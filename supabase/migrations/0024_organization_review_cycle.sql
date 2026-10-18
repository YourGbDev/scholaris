-- Apply after 0023. No demo identities or email/name-based authorization.
-- organization_id reuses the existing scholarship owner as the organization
-- principal; membership is provisioned by a trusted database operator only.
begin;

create table public.organization_memberships (
  user_id uuid primary key references public.profiles(id),
  organization_id uuid not null references public.profiles(id),
  role text not null check (role in ('org_admin', 'reviewer', 'finance')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  check (role <> 'org_admin' or user_id = organization_id)
);
alter table public.organization_memberships enable row level security;
revoke all on public.organization_memberships from public, anon, authenticated;
grant select on public.organization_memberships to authenticated;
create policy membership_read_self on public.organization_memberships
  for select to authenticated using (user_id = auth.uid());

create function public.organization_role(p_organization_id uuid)
returns text language sql stable security definer set search_path = '' as $$
  select m.role from public.organization_memberships m
  join public.profiles p on p.id = m.user_id
  where m.user_id = auth.uid() and m.organization_id = p_organization_id
    and m.active and p.role = 'provider' and p.status = 'active'
$$;
revoke all on function public.organization_role(uuid) from public, anon;
grant execute on function public.organization_role(uuid) to authenticated;

create function public.can_review_scholarship(p_scholarship_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.scholarships s
    where s.id = p_scholarship_id
    and public.organization_role(s.created_by) in ('org_admin', 'reviewer'))
$$;
revoke all on function public.can_review_scholarship(uuid) from public, anon;
grant execute on function public.can_review_scholarship(uuid) to authenticated;

create function public.organization_scholarship_ids()
returns table(id uuid) language sql stable security definer set search_path = '' as $$
  select s.id from public.scholarships s
  where public.can_review_scholarship(s.id)
$$;
revoke all on function public.organization_scholarship_ids() from public, anon;
grant execute on function public.organization_scholarship_ids() to authenticated;

-- Restrictive policies also constrain legacy permissive policies on live DBs.
drop policy if exists "Providers can update status of applications to their own scholarships" on public.applications;
drop policy if exists providers_update_own_application_status on public.applications;
drop policy if exists providers_select_own_applications on public.applications;
drop policy if exists "Providers can select applications to their own scholarships" on public.applications;
drop policy if exists "Admins can update approved applications to awarded" on public.applications;
create policy application_org_read_boundary on public.applications
  as restrictive for select to authenticated using (
    user_id = auth.uid() or public.is_admin() or
    (status not in ('draft', 'withdrawn') and public.can_review_scholarship(scholarship_id))
  );
create policy application_org_read on public.applications
  for select to authenticated using (
    status not in ('draft', 'withdrawn') and public.can_review_scholarship(scholarship_id)
  );
create policy application_student_write_boundary on public.applications
  as restrictive for insert to authenticated with check (
    user_id = auth.uid() and status in ('draft', 'submitted')
    and exists (select 1 from public.profiles p where p.id = auth.uid()
      and p.role = 'student' and p.status = 'active')
    and exists (select 1 from public.scholarships s where s.id = scholarship_id
      and s.is_active and s.deadline >= current_date)
  );
create policy application_student_update_boundary on public.applications
  as restrictive for update to authenticated
  using (user_id = auth.uid() and status in ('draft', 'submitted', 'under_review'))
  with check (user_id = auth.uid() and status in ('draft', 'submitted', 'under_review', 'withdrawn'));

alter table public.applications
  add column endorsed_by uuid references auth.users(id),
  add column endorsed_at timestamptz,
  add column decided_by uuid references auth.users(id),
  add column decided_at timestamptz;
alter table public.application_evaluations drop constraint application_evaluations_decision_check;
alter table public.application_evaluations add constraint application_evaluations_decision_check
  check (decision in ('approved', 'rejected', 'under_review', 'endorsed'));

-- Client writes cannot forge evaluations, history, or recipient notifications.
revoke insert, update, delete on public.application_evaluations,
  public.application_status_history, public.notifications from public, anon, authenticated;
drop policy if exists evaluations_insert_by_provider on public.application_evaluations;
drop policy if exists status_history_insert_authorized_actors on public.application_status_history;
drop policy if exists notifications_insert_authenticated on public.notifications;
drop policy if exists status_history_select_authorized_actors on public.application_status_history;
create policy history_owner_admin_read on public.application_status_history for select to authenticated
  using (public.is_admin() or exists (select 1 from public.applications a
    where a.id = application_id and a.user_id = auth.uid()));
grant update (is_read) on public.notifications to authenticated;
create policy evaluation_org_read on public.application_evaluations for select to authenticated
  using (exists (select 1 from public.applications a where a.id = application_id
    and a.status not in ('draft', 'withdrawn') and public.can_review_scholarship(a.scholarship_id)));
create policy evaluation_read_boundary on public.application_evaluations as restrictive
  for select to authenticated using (exists (select 1 from public.applications a where a.id = application_id));
create policy history_org_read on public.application_status_history for select to authenticated
  using (exists (select 1 from public.applications a where a.id = application_id
    and a.status not in ('draft', 'withdrawn') and public.can_review_scholarship(a.scholarship_id)));
create policy history_read_boundary on public.application_status_history as restrictive
  for select to authenticated using (exists (select 1 from public.applications a where a.id = application_id));

-- Publishing remains an org admin operation, including legacy owner policies.
create policy scholarship_admin_insert_boundary on public.scholarships as restrictive
  for insert to authenticated with check (
    created_by = auth.uid() and public.organization_role(created_by) = 'org_admin');
create policy scholarship_admin_update_boundary on public.scholarships as restrictive
  for update to authenticated using (public.organization_role(created_by) = 'org_admin')
  with check (created_by = auth.uid() and public.organization_role(created_by) = 'org_admin');
create policy scholarship_admin_delete_boundary on public.scholarships as restrictive
  for delete to authenticated using (public.organization_role(created_by) = 'org_admin');

create function public.review_application(
  p_application_id uuid, p_expected_status text, p_action text,
  p_scores jsonb default null, p_notes text default null
) returns public.applications
language plpgsql security definer set search_path = '' as $$
declare
  a public.applications; s public.scholarships; actor_role text;
  target_status text; x numeric; academic numeric; financial numeric;
  leadership numeric; vision numeric; composite numeric;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select * into a from public.applications where id = p_application_id for update;
  if not found then raise exception 'Application unavailable' using errcode = '42501'; end if;
  select * into s from public.scholarships where id = a.scholarship_id;
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

-- Defense in depth against direct PATCHes (including privileged fields) and
-- ownership reassignment. Only the transaction function's DB owner may write
-- workflow fields; an authenticated JWT cannot acquire that database role.
create function public.guard_application_workflow() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user = pg_catalog.pg_get_userbyid((select proowner from pg_catalog.pg_proc
    where oid = 'public.review_application(uuid,text,text,jsonb,text)'::regprocedure)) then return new; end if;
  if TG_OP = 'INSERT' then
    if new.endorsed_by is not null or new.endorsed_at is not null or new.decided_by is not null or new.decided_at is not null then
      raise exception 'Workflow fields are server-managed' using errcode = '42501';
    end if;
  else
    if (new.id, new.user_id, new.scholarship_id, new.endorsed_by, new.endorsed_at, new.decided_by, new.decided_at)
      is distinct from (old.id, old.user_id, old.scholarship_id, old.endorsed_by, old.endorsed_at, old.decided_by, old.decided_at) then
      raise exception 'Ownership and workflow fields are immutable' using errcode = '42501';
    end if;
    if new.status is distinct from old.status and not (
      old.user_id = auth.uid() and ((old.status = 'draft' and new.status = 'submitted')
        or (old.status in ('draft','submitted','under_review') and new.status = 'withdrawn'))
    ) then raise exception 'Use the authorized workflow action' using errcode = '42501'; end if;
  end if;
  return new;
end;
$$;
create trigger guard_application_workflow before insert or update on public.applications
  for each row execute function public.guard_application_workflow();

-- Academic profile projection stays column-minimized. No contact, health,
-- ethnicity, birth-date, or unrestricted profiles-table access is granted.
create or replace view public.provider_applicant_profiles with (security_barrier = true) as
select p.id, p.full_name, p.school, p.course, p.year_level, p.gpa, p.region,
  p.province, p.city_municipality, p.setup_complete, p.monthly_family_income
from public.profiles p where public.is_admin() or exists (
  select 1 from public.applications a where a.user_id = p.id
    and a.status not in ('draft', 'withdrawn') and public.can_review_scholarship(a.scholarship_id));
create or replace function public.get_applicant_profile(p_user_id uuid)
returns table (id uuid, full_name text, school text, course text, year_level int,
  gpa numeric, region text, province text, city_municipality text, setup_complete boolean, monthly_family_income numeric)
language sql stable security definer set search_path = '' as $$
  select * from public.provider_applicant_profiles p where p.id = p_user_id
$$;

drop policy if exists providers_and_admins_read_application_documents on public.application_documents;
create policy providers_and_admins_read_application_documents on public.application_documents
  for select to authenticated using (public.is_admin() or exists (
    select 1 from public.applications a where a.id = application_id
      and a.status not in ('draft','withdrawn') and public.can_review_scholarship(a.scholarship_id)));
create policy document_read_boundary on public.application_documents as restrictive
  for select to authenticated using (exists (select 1 from public.applications a where a.id = application_id));
drop policy if exists storage_provider_admin_read_application_documents on storage.objects;
create policy storage_provider_admin_read_application_documents on storage.objects
  for select to authenticated using (bucket_id = 'application_documents' and (
    public.is_admin() or exists (select 1 from public.applications a
      where a.id = case when (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        then ((storage.foldername(name))[1])::uuid else null end
      and a.status not in ('draft','withdrawn') and public.can_review_scholarship(a.scholarship_id))));
-- Constrain any older bucket-wide read policy too.
create policy storage_document_read_boundary on storage.objects as restrictive
  for select to authenticated using (bucket_id <> 'application_documents' or public.is_admin()
    or exists (select 1 from public.applications a
      where a.id = case when (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        then ((storage.foldername(name))[1])::uuid else null end));

notify pgrst, 'reload schema';
commit;
