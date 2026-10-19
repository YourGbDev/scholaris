-- =============================================================================
-- Migration 0026: Organization-Admin Controls, Capacity Accounting & School Eligibility
--
-- Sprint: Organization-Admin Controls, Capacity Accounting & School Eligibility (Phase 1)
-- Reference Plan: docs/plans/2026-10-19_organization_admin_controls_plan.md
--
-- Objectives:
-- 1. Table public.schools catalog seeded with 10 neutral, unranked universities.
-- 2. Deduplicated RPC public.add_custom_school(p_name text).
-- 3. Student profile school_id reference and migration backfill.
-- 4. Backend aggregate slot access: public.scholarship_capacities security barrier view.
-- 5. Atomic scholarship slot capacity enforcement & reduction guard trigger.
-- 6. Backend school eligibility submission guard in guard_application_workflow().
-- 7. Organization activity logs, reviewer assignments & roster RPCs.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1. Table: public.schools
-- -----------------------------------------------------------------------------
create table if not exists public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  normalized_name text not null unique,
  aliases text[] not null default '{}',
  is_curated boolean not null default true, -- Seeded vs user-added; NOT a claim of student enrollment verification
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_schools_normalized_name on public.schools (normalized_name);

alter table public.schools enable row level security;
drop policy if exists "Schools are readable by all authenticated users" on public.schools;
create policy "Schools are readable by all authenticated users"
  on public.schools for select to authenticated using (true);

grant select on public.schools to authenticated;
revoke insert, update, delete on public.schools from public, anon, authenticated;

-- Seed 10 neutral, pre-populated Philippine universities in alphabetical order (zero arbitrary rankings)
insert into public.schools (name, normalized_name, aliases, is_curated) values
  ('Adamson University', 'adamson university', array['adamson', 'adu'], true),
  ('Ateneo de Manila University', 'ateneo de manila university', array['ateneo de manila', 'admu', 'ateneo'], true),
  ('De La Salle University', 'de la salle university', array['de la salle university', 'de la salle', 'dlsu', 'la salle'], true),
  ('Far Eastern University', 'far eastern university', array['far eastern university', 'feu'], true),
  ('Mapúa University', 'mapua university', array['mapua', 'mapua university', 'mapua institute of technology'], true),
  ('Pamantasan ng Lungsod ng Maynila', 'pamantasan ng lungsod ng maynila', array['pamantasan ng lungsod ng maynila', 'plm'], true),
  ('Polytechnic University of the Philippines', 'polytechnic university of the philippines', array['polytechnic university of the philippines', 'pup', 'polytechnic university'], true),
  ('Technological University of the Philippines', 'technological university of the philippines', array['technological university of the philippines', 'tup', 'technological university'], true),
  ('University of Santo Tomas', 'university of santo tomas', array['university of santo tomas', 'ust'], true),
  ('University of the Philippines Diliman', 'university of the philippines diliman', array['university of the philippines diliman', 'up diliman', 'upd', 'up'], true)
on conflict (normalized_name) do nothing;

-- -----------------------------------------------------------------------------
-- 2. RPC: public.add_custom_school
-- -----------------------------------------------------------------------------
create or replace function public.add_custom_school(p_name text)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_norm text;
  v_existing_id uuid;
  v_new_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_name is null or trim(p_name) = '' then
    raise exception 'School name cannot be empty' using errcode = 'P0002';
  end if;

  v_norm := lower(trim(regexp_replace(p_name, '\s+', ' ', 'g')));

  -- Deduplication: match against normalized_name or any alias
  select id into v_existing_id
  from public.schools
  where normalized_name = v_norm or v_norm = any(aliases)
  limit 1;

  if v_existing_id is not null then
    return v_existing_id;
  end if;

  insert into public.schools (name, normalized_name, aliases, is_curated, created_by)
  values (trim(p_name), v_norm, '{}', false, auth.uid())
  returning id into v_new_id;

  return v_new_id;
end;
$$;
revoke all on function public.add_custom_school(text) from public, anon;
grant execute on function public.add_custom_school(text) to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Student Profile Backfill & Scholarships eligible_school_ids Column
-- -----------------------------------------------------------------------------
alter table public.profiles add column if not exists school_id uuid references public.schools(id);
alter table public.scholarships add column if not exists eligible_school_ids uuid[] default null;

do $$
declare
  r record;
  v_norm text;
  v_school_id uuid;
begin
  -- Strictly filter to students: do not convert provider organization names (e.g. DOST-SEI) into schools.
  -- Only match against curated seed institutions (is_curated = true).
  -- Ambiguous or unmatched text is preserved in profiles.school without inventing a campus association.
  for r in select id, school from public.profiles
    where role = 'student' and school is not null and trim(school) <> '' and school_id is null loop
    v_norm := lower(trim(regexp_replace(r.school, '\s+', ' ', 'g')));

    select id into v_school_id
    from public.schools
    where is_curated = true
      and (normalized_name = v_norm or v_norm = any(aliases))
    limit 1;

    -- If matched to a curated seed institution, link it.
    -- If unmatched or ambiguous, leave school_id as NULL, preserving original school text.
    if v_school_id is not null then
      update public.profiles set school_id = v_school_id where id = r.id;
    end if;
  end loop;
end $$;

-- -----------------------------------------------------------------------------
-- 4. Backend Aggregate Slot Access: public.scholarship_capacities
-- -----------------------------------------------------------------------------
create or replace view public.scholarship_capacities with (security_barrier = true) as
select
  s.id as scholarship_id,
  s.slots as total_slots,
  coalesce(count(a.id) filter (where a.status in ('approved', 'awarded')), 0)::int as occupied_slots,
  case
    when s.slots is null then null
    else greatest(0, s.slots - coalesce(count(a.id) filter (where a.status in ('approved', 'awarded')), 0)::int)
  end as remaining_slots,
  (s.slots is null) as is_uncapped
from public.scholarships s
left join public.applications a on a.scholarship_id = s.id
where (
  -- Visibility rule: students only see active grants; org members see their own
  s.is_active = true
  or public.is_admin()
  or exists (
    select 1 from public.organization_memberships m
    where m.user_id = auth.uid()
      and m.organization_id = s.created_by
      and m.active = true
  )
)
group by s.id, s.slots, s.is_active, s.created_by;

grant select on public.scholarship_capacities to authenticated;

create or replace function public.get_scholarship_capacity(p_scholarship_id uuid)
returns table (
  scholarship_id uuid,
  total_slots int,
  occupied_slots int,
  remaining_slots int,
  is_uncapped boolean
)
language sql stable security definer set search_path = '' as $$
  select
    c.scholarship_id,
    c.total_slots,
    c.occupied_slots,
    c.remaining_slots,
    c.is_uncapped
  from public.scholarship_capacities c
  where c.scholarship_id = p_scholarship_id;
$$;
revoke all on function public.get_scholarship_capacity(uuid) from public, anon;
grant execute on function public.get_scholarship_capacity(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 5. Trigger: Guard Scholarship Capacity Reduction Below Occupied Count
-- -----------------------------------------------------------------------------
create or replace function public.guard_scholarship_capacity() returns trigger
language plpgsql as $$
declare
  v_occupied int;
begin
  if new.slots is not null then
    select count(*) into v_occupied
    from public.applications
    where scholarship_id = new.id
      and status in ('approved', 'awarded');

    if new.slots < v_occupied then
      raise exception 'Cannot reduce total slots to %: % slots are currently occupied by approved scholars.'
        , new.slots, v_occupied using errcode = 'P0002';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_guard_scholarship_capacity on public.scholarships;
create trigger trg_guard_scholarship_capacity
  before update of slots on public.scholarships
  for each row execute function public.guard_scholarship_capacity();

-- -----------------------------------------------------------------------------
-- 6. Atomic Slot Capacity Enforcement in public.review_application
-- -----------------------------------------------------------------------------
create or replace function public.review_application(
  p_application_id uuid, p_expected_status text, p_action text,
  p_scores jsonb default null, p_notes text default null
) returns public.applications
language plpgsql security definer set search_path = '' as $$
declare
  a public.applications; s public.scholarships; actor_role text;
  target_status text; x numeric; academic numeric; financial numeric;
  leadership numeric; vision numeric; composite numeric;
  v_occupied int;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select * into a from public.applications where id = p_application_id for update;
  if not found then raise exception 'Application unavailable' using errcode = '42501'; end if;
  select * into s from public.scholarships where id = a.scholarship_id for update;
  actor_role := public.organization_role(s.created_by);
  if actor_role is null or actor_role not in ('org_admin', 'reviewer') or a.user_id = auth.uid() then
    raise exception 'Application unavailable' using errcode = '42501';
  end if;
  if a.status is distinct from p_expected_status then
    raise exception 'Application changed. Refresh before continuing.' using errcode = '40001';
  end if;
  if p_action = 'endorse' then
    if actor_role <> 'reviewer' then raise exception 'Only reviewers can endorse' using errcode = '42501'; end if;
    if a.status not in ('submitted', 'under_review') or a.endorsed_by is not null then
      raise exception 'Application cannot be endorsed in its current state';
    end if;
    if p_scores is null or not (p_scores ?& array['academic','financial','leadership','vision']) then
      raise exception 'All four rubric scores are required';
    end if;
    foreach x in array array[(p_scores->>'academic')::numeric, (p_scores->>'financial')::numeric,
      (p_scores->>'leadership')::numeric, (p_scores->>'vision')::numeric] loop
      if x is null or not (x >= 0 and x <= 10) then raise exception 'Scores must be between 0 and 10'; end if;
    end loop;
    academic := (p_scores->>'academic')::numeric;
    financial := (p_scores->>'financial')::numeric;
    leadership := (p_scores->>'leadership')::numeric;
    vision := (p_scores->>'vision')::numeric;
    composite := round(academic * .4 + financial * .3 + leadership * .2 + vision * .1, 2);
    insert into public.application_evaluations(application_id, reviewer_id, score_academic,
      score_financial, score_leadership, score_vision, composite_score, deliberation_notes, decision)
      values (a.id, auth.uid(), academic, financial, leadership, vision, composite, p_notes, 'endorsed');
    target_status := 'under_review';
    update public.applications set status = target_status, endorsed_by = auth.uid(), endorsed_at = now()
      where id = a.id;
  elsif p_action in ('approve', 'reject') then
    if actor_role <> 'org_admin' then raise exception 'Only organization admins can decide' using errcode = '42501'; end if;
    if a.status <> 'under_review' or a.endorsed_by is null or a.endorsed_by = auth.uid()
      or not exists (select 1 from public.application_evaluations e where e.application_id = a.id
        and e.reviewer_id = a.endorsed_by and e.decision = 'endorsed') then
      raise exception 'A separate reviewer endorsement is required';
    end if;

    if p_action = 'approve' then
      -- Capacity check (only for capped scholarships)
      if s.slots is not null then
        select count(*) into v_occupied
        from public.applications
        where scholarship_id = s.id
          and status in ('approved', 'awarded')
          and id <> a.id;

        if v_occupied >= s.slots then
          raise exception 'Scholarship capacity reached. No slots remaining (%/% occupied).',
            v_occupied, s.slots using errcode = 'P0001';
        end if;
      end if;
    end if;

    target_status := case p_action when 'approve' then 'approved' else 'rejected' end;
    update public.applications set status = target_status, decided_by = auth.uid(), decided_at = now()
      where id = a.id;
    insert into public.notifications(user_id, title, message, target_id, type)
      values (a.user_id, case p_action when 'approve' then 'Application Approved' else 'Application Rejected' end,
        format('Your application for "%s" has been %s.', s.title, target_status), a.id::text, 'application_update');
  else
    raise exception 'Unsupported review action';
  end if;
  insert into public.application_status_history(application_id, changed_by, from_status, to_status, remarks)
    values (a.id, auth.uid(), a.status, target_status,
      case when p_action = 'endorse' then 'Endorsed to organization admin. ' else 'Final decision. ' end || coalesce(p_notes, ''));
  select * into strict a from public.applications where id = a.id;
  return a;
end;
$$;
revoke all on function public.review_application(uuid,text,text,jsonb,text) from public, anon;
grant execute on function public.review_application(uuid,text,text,jsonb,text) to authenticated;

-- -----------------------------------------------------------------------------
-- 7. Backend School Eligibility Enforcement in guard_application_workflow
-- -----------------------------------------------------------------------------
create or replace function public.guard_application_workflow() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_eligible_schools uuid[];
  v_student_school_id uuid;
begin
  if current_user = pg_catalog.pg_get_userbyid((select proowner from pg_catalog.pg_proc
    where oid = 'public.review_application(uuid,text,text,jsonb,text)'::regprocedure)) then return new; end if;
  if TG_OP = 'INSERT' then
    if new.endorsed_by is not null or new.endorsed_at is not null or new.decided_by is not null or new.decided_at is not null then
      raise exception 'Workflow fields are server-managed' using errcode = '42501';
    end if;

    -- School eligibility check on direct student insert (if inserted as 'submitted')
    if new.status = 'submitted' then
      select s.eligible_school_ids into v_eligible_schools
      from public.scholarships s where s.id = new.scholarship_id;

      if v_eligible_schools is not null and array_length(v_eligible_schools, 1) > 0 then
        select p.school_id into v_student_school_id
        from public.profiles p where p.id = new.user_id;

        if v_student_school_id is null or not (v_student_school_id = any(v_eligible_schools)) then
          raise exception 'School eligibility requirement not met. This scholarship is restricted to designated partner institutions.'
            using errcode = 'P0003';
        end if;
      end if;
    end if;
  else
    if (new.id, new.user_id, new.scholarship_id, new.endorsed_by, new.endorsed_at, new.decided_by, new.decided_at)
      is distinct from (old.id, old.user_id, old.scholarship_id, old.endorsed_by, old.endorsed_at, old.decided_by, old.decided_at) then
      raise exception 'Ownership and workflow fields are immutable' using errcode = '42501';
    end if;
    if new.status is distinct from old.status and not (
      (old.user_id = auth.uid() and ((old.status = 'draft' and new.status = 'submitted')
        or (old.status in ('draft','submitted','under_review') and new.status = 'withdrawn')))
      or (public.is_admin() and old.status = 'approved' and new.status = 'awarded')
    ) then raise exception 'Use the authorized workflow action' using errcode = '42501'; end if;

    -- School eligibility check on student submitting draft ('draft' -> 'submitted')
    if old.status = 'draft' and new.status = 'submitted' then
      select s.eligible_school_ids into v_eligible_schools
      from public.scholarships s where s.id = new.scholarship_id;

      if v_eligible_schools is not null and array_length(v_eligible_schools, 1) > 0 then
        select p.school_id into v_student_school_id
        from public.profiles p where p.id = new.user_id;

        if v_student_school_id is null or not (v_student_school_id = any(v_eligible_schools)) then
          raise exception 'School eligibility requirement not met. This scholarship is restricted to designated partner institutions.'
            using errcode = 'P0003';
        end if;
      end if;
    end if;
  end if;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 8. Table: public.scholarship_reviewer_assignments & Assignment RPCs
-- -----------------------------------------------------------------------------
create table if not exists public.scholarship_reviewer_assignments (
  id uuid primary key default gen_random_uuid(),
  scholarship_id uuid not null references public.scholarships(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id) on delete cascade,
  assigned_by uuid not null references public.profiles(id),
  assigned_at timestamptz not null default now(),
  constraint uq_scholarship_reviewer unique (scholarship_id, reviewer_id)
);

create index if not exists idx_scholarship_reviewer_assignments_scholarship
  on public.scholarship_reviewer_assignments (scholarship_id);
create index if not exists idx_scholarship_reviewer_assignments_reviewer
  on public.scholarship_reviewer_assignments (reviewer_id);

alter table public.scholarship_reviewer_assignments enable row level security;

create policy "Org members can view reviewer assignments for org scholarships"
  on public.scholarship_reviewer_assignments
  for select to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.scholarships s
      where s.id = scholarship_reviewer_assignments.scholarship_id
        and public.can_review_scholarship(s.id)
    )
  );

create policy "Org admins can manage reviewer assignments"
  on public.scholarship_reviewer_assignments
  for all to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.scholarships s
      where s.id = scholarship_reviewer_assignments.scholarship_id
        and public.organization_role(s.created_by) = 'org_admin'
    )
  )
  with check (
    public.is_admin()
    or exists (
      select 1 from public.scholarships s
      where s.id = scholarship_reviewer_assignments.scholarship_id
        and public.organization_role(s.created_by) = 'org_admin'
    )
  );

grant select on public.scholarship_reviewer_assignments to authenticated;

-- RPC: public.assign_scholarship_reviewer
create or replace function public.assign_scholarship_reviewer(
  p_scholarship_id uuid,
  p_reviewer_id uuid
) returns public.scholarship_reviewer_assignments
language plpgsql security definer set search_path = '' as $$
declare
  v_scholarship public.scholarships;
  v_role text;
  v_reviewer_role text;
  v_assignment public.scholarship_reviewer_assignments;
  v_actor_email text;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select * into v_scholarship from public.scholarships where id = p_scholarship_id;
  if not found then raise exception 'Scholarship not found' using errcode = 'P0002'; end if;

  v_role := public.organization_role(v_scholarship.created_by);
  if not (public.is_admin() or v_role = 'org_admin') then
    raise exception 'Only organization admins can assign reviewers' using errcode = '42501';
  end if;

  -- Ensure reviewer is active reviewer or org_admin in the organization
  select m.role into v_reviewer_role
  from public.organization_memberships m
  where m.user_id = p_reviewer_id
    and m.organization_id = v_scholarship.created_by
    and m.active = true;

  if v_reviewer_role is null or v_reviewer_role not in ('reviewer', 'org_admin') then
    raise exception 'User is not an active reviewer for this organization' using errcode = 'P0002';
  end if;

  insert into public.scholarship_reviewer_assignments (scholarship_id, reviewer_id, assigned_by)
  values (p_scholarship_id, p_reviewer_id, auth.uid())
  on conflict (scholarship_id, reviewer_id) do update set assigned_at = now()
  returning * into v_assignment;

  -- Audit log entry
  select email into v_actor_email from auth.users where id = auth.uid();
  insert into public.audit_logs (actor_id, actor_email, actor_role, action, target_type, target_id, details)
  values (
    auth.uid(),
    v_actor_email,
    'org_admin',
    'assign_reviewer',
    'scholarship',
    p_scholarship_id::text,
    jsonb_build_object('reviewer_id', p_reviewer_id::text, 'scholarship_id', p_scholarship_id::text)
  );

  return v_assignment;
end;
$$;
revoke all on function public.assign_scholarship_reviewer(uuid, uuid) from public, anon;
grant execute on function public.assign_scholarship_reviewer(uuid, uuid) to authenticated;

-- RPC: public.unassign_scholarship_reviewer
create or replace function public.unassign_scholarship_reviewer(
  p_scholarship_id uuid,
  p_reviewer_id uuid
) returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  v_scholarship public.scholarships;
  v_role text;
  v_actor_email text;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select * into v_scholarship from public.scholarships where id = p_scholarship_id;
  if not found then raise exception 'Scholarship not found' using errcode = 'P0002'; end if;

  v_role := public.organization_role(v_scholarship.created_by);
  if not (public.is_admin() or v_role = 'org_admin') then
    raise exception 'Only organization admins can unassign reviewers' using errcode = '42501';
  end if;

  delete from public.scholarship_reviewer_assignments
  where scholarship_id = p_scholarship_id and reviewer_id = p_reviewer_id;

  -- Audit log entry
  select email into v_actor_email from auth.users where id = auth.uid();
  insert into public.audit_logs (actor_id, actor_email, actor_role, action, target_type, target_id, details)
  values (
    auth.uid(),
    v_actor_email,
    'org_admin',
    'unassign_reviewer',
    'scholarship',
    p_scholarship_id::text,
    jsonb_build_object('reviewer_id', p_reviewer_id::text, 'scholarship_id', p_scholarship_id::text)
  );

  return true;
end;
$$;
revoke all on function public.unassign_scholarship_reviewer(uuid, uuid) from public, anon;
grant execute on function public.unassign_scholarship_reviewer(uuid, uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 9. RPC: public.get_organization_roster
-- -----------------------------------------------------------------------------
create or replace function public.get_organization_roster(p_organization_id uuid)
returns table (
  user_id uuid,
  full_name text,
  role text,
  active boolean,
  created_at timestamptz,
  assigned_scholarship_count bigint
)
language sql stable security definer set search_path = '' as $$
  select
    m.user_id,
    coalesce(p.full_name, 'Team Member') as full_name,
    m.role,
    m.active,
    m.created_at,
    count(sra.id) as assigned_scholarship_count
  from public.organization_memberships m
  join public.profiles p on p.id = m.user_id
  left join public.scholarship_reviewer_assignments sra on sra.reviewer_id = m.user_id
  where m.organization_id = p_organization_id
    and p.role = 'provider'
    and (
      public.is_admin()
      or exists (
        select 1 from public.organization_memberships caller_m
        where caller_m.user_id = auth.uid()
          and caller_m.organization_id = p_organization_id
          and caller_m.active = true
      )
    )
  group by m.user_id, p.full_name, m.role, m.active, m.created_at
  order by m.role asc, full_name asc;
$$;
revoke all on function public.get_organization_roster(uuid) from public, anon;
grant execute on function public.get_organization_roster(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 10. RPC: public.get_organization_activity_logs
-- -----------------------------------------------------------------------------
create or replace function public.get_organization_activity_logs(
  p_organization_id uuid,
  p_limit int default 50,
  p_offset int default 0,
  p_action_filter text default null
)
returns table (
  id uuid,
  actor_id uuid,
  actor_name text,
  action text,
  target_type text,
  target_id text,
  details jsonb,
  created_at timestamptz
)
language sql stable security definer set search_path = '' as $$
  select
    al.id,
    al.actor_id,
    coalesce(p.full_name, al.actor_email, 'System') as actor_name,
    al.action,
    al.target_type,
    al.target_id,
    coalesce(al.details, '{}'::jsonb) as details,
    al.created_at
  from public.audit_logs al
  left join public.profiles p on p.id = al.actor_id
  where (
    public.is_admin()
    or exists (
      select 1 from public.organization_memberships caller_m
      where caller_m.user_id = auth.uid()
        and caller_m.organization_id = p_organization_id
        and caller_m.active = true
    )
  )
  and (
    -- Actions performed by members of this organization
    exists (
      select 1 from public.organization_memberships m
      where m.user_id = al.actor_id and m.organization_id = p_organization_id
    )
    -- Or actions targeting scholarships of this organization
    or exists (
      select 1 from public.scholarships s
      where s.id::text = al.target_id and s.created_by = p_organization_id
    )
  )
  and (p_action_filter is null or al.action = p_action_filter)
  order by al.created_at desc, al.id desc
  limit coalesce(p_limit, 50)
  offset coalesce(p_offset, 0);
$$;
revoke all on function public.get_organization_activity_logs(uuid, int, int, text) from public, anon;
grant execute on function public.get_organization_activity_logs(uuid, int, int, text) to authenticated;

notify pgrst, 'reload schema';
commit;
