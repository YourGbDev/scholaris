-- =============================================================================
-- Migration 0027: Individual Provider Lifecycle & Direct Benefactor Decisioning
--
-- Sprint: Individual Provider Lifecycle & Benefactor Decisioning (Phase 3)
-- Reference Plan: docs/plans/2026-10-21_individual_provider_lifecycle_plan.md
--
-- Objectives:
-- 1. Update public.can_review_scholarship(uuid) to grant active individual
--    providers read and evaluation access to applications for their own grants.
-- 2. Update public.review_application(uuid, text, text, jsonb, text) to support
--    single-step direct benefactor decisions ('approve', 'reject') without
--    requiring institutional reviewer endorsement, while strictly preserving
--    the decision boundary (approving does NOT award or release funds).
-- 3. Enforce atomic slot capacity check (rejection with 'P0001' on overbooking)
--    without double-counting approved and awarded applications.
-- 4. Maintain immutable audit history and student notifications.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1. Helper Function: public.can_review_scholarship
-- -----------------------------------------------------------------------------
create or replace function public.can_review_scholarship(p_scholarship_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.scholarships s
    join public.profiles p on p.id = s.created_by
    where s.id = p_scholarship_id
      and (
        public.organization_role(s.created_by) in ('org_admin', 'reviewer')
        or (
          s.created_by = auth.uid()
          and p.role = 'provider'
          and p.provider_type = 'individual'
          and p.status = 'active'
          and exists (
            select 1 from public.provider_verifications pv
            where pv.user_id = auth.uid()
              and pv.provider_type = 'individual'
              and pv.status = 'approved'
          )
        )
      )
  );
$$;

revoke all on function public.can_review_scholarship(uuid) from public, anon;
grant execute on function public.can_review_scholarship(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Atomic Review & Decision RPC: public.review_application
-- -----------------------------------------------------------------------------
create or replace function public.review_application(
  p_application_id uuid, p_expected_status text, p_action text,
  p_scores jsonb default null, p_notes text default null
) returns public.applications
language plpgsql security definer set search_path = '' as $$
declare
  a public.applications;
  s public.scholarships;
  actor_role text;
  is_individual_owner boolean := false;
  target_status text;
  x numeric;
  academic numeric;
  financial numeric;
  leadership numeric;
  vision numeric;
  composite numeric;
  v_occupied int;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  -- Reject null or unsupported review action immediately before any side effect
  if p_action is null or p_action not in ('endorse', 'approve', 'reject') then
    raise exception 'Invalid review action' using errcode = '22023';
  end if;

  select * into a from public.applications where id = p_application_id for update;
  if not found then
    raise exception 'Application unavailable' using errcode = '42501';
  end if;

  select * into s from public.scholarships where id = a.scholarship_id for update;

  -- Applicants are strictly forbidden from reviewing their own applications
  if a.user_id = auth.uid() then
    raise exception 'Application unavailable' using errcode = '42501';
  end if;

  actor_role := public.organization_role(s.created_by);

  -- Determine caller authority: Institutional vs Individual Sponsor
  if actor_role is null then
    -- Fail closed: ONLY positive individual provider classification with active status & approved verification
    if s.created_by = auth.uid() and exists (
      select 1 from public.profiles p
      join public.provider_verifications pv on pv.user_id = p.id
      where p.id = auth.uid()
        and p.role = 'provider'
        and p.provider_type = 'individual'
        and p.status = 'active'
        and pv.provider_type = 'individual'
        and pv.status = 'approved'
    ) then
      is_individual_owner := true;
    else
      -- Organization accounts without membership or unverified/disabled providers fail closed
      raise exception 'Application unavailable' using errcode = '42501';
    end if;
  end if;

  if a.status is distinct from p_expected_status then
    raise exception 'Application changed. Refresh before continuing.' using errcode = '40001';
  end if;

  -- ---------------------------------------------------------------------------
  -- Flow A: Individual Provider / Benefactor Direct Decision
  -- ---------------------------------------------------------------------------
  if is_individual_owner then
    if p_action is null or p_action not in ('approve', 'reject') then
      raise exception 'Individual providers make direct decisions without endorsement' using errcode = '42501';
    end if;

    if a.status not in ('submitted', 'under_review') then
      raise exception 'Application cannot be decided in its current state' using errcode = '42501';
    end if;

    if p_action = 'approve' then
      -- Atomic slot capacity check (capped scholarships only)
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

    -- Decision boundary: 'approve' transitions ONLY to 'approved', never to 'awarded'
    target_status := case p_action
      when 'approve' then 'approved'
      when 'reject' then 'rejected'
      else null
    end;
    if target_status is null then
      raise exception 'Invalid target status' using errcode = '22023';
    end if;

    update public.applications
    set status = target_status, decided_by = auth.uid(), decided_at = now()
    where id = a.id;

    insert into public.notifications(user_id, title, message, target_id, type)
    values (
      a.user_id,
      case p_action when 'approve' then 'Application Approved' else 'Application Rejected' end,
      format('Your application for "%s" has been %s.', s.title, target_status),
      a.id::text,
      'application_update'
    );

    insert into public.application_status_history(application_id, changed_by, from_status, to_status, remarks)
    values (
      a.id,
      auth.uid(),
      a.status,
      target_status,
      'Decision by scholarship sponsor. ' || coalesce(p_notes, '')
    );

    select * into strict a from public.applications where id = a.id;
    return a;
  end if;

  -- ---------------------------------------------------------------------------
  -- Flow B: Institutional Multi-Role Review Cycle (Reviewer -> Org Admin)
  -- ---------------------------------------------------------------------------
  if p_action = 'endorse' then
    if actor_role <> 'reviewer' then
      raise exception 'Only reviewers can endorse' using errcode = '42501';
    end if;
    if a.status not in ('submitted', 'under_review') or a.endorsed_by is not null then
      raise exception 'Application cannot be endorsed in its current state';
    end if;
    if p_scores is null or not (p_scores ?& array['academic','financial','leadership','vision']) then
      raise exception 'All four rubric scores are required';
    end if;
    foreach x in array array[(p_scores->>'academic')::numeric, (p_scores->>'financial')::numeric,
      (p_scores->>'leadership')::numeric, (p_scores->>'vision')::numeric] loop
      if x is null or not (x >= 0 and x <= 10) then
        raise exception 'Scores must be between 0 and 10';
      end if;
    end loop;
    academic := (p_scores->>'academic')::numeric;
    financial := (p_scores->>'financial')::numeric;
    leadership := (p_scores->>'leadership')::numeric;
    vision := (p_scores->>'vision')::numeric;
    composite := round(academic * .4 + financial * .3 + leadership * .2 + vision * .1, 2);

    insert into public.application_evaluations(
      application_id, reviewer_id, score_academic, score_financial,
      score_leadership, score_vision, composite_score, deliberation_notes, decision
    ) values (
      a.id, auth.uid(), academic, financial, leadership, vision, composite, p_notes, 'endorsed'
    );

    target_status := 'under_review';
    update public.applications
    set status = target_status, endorsed_by = auth.uid(), endorsed_at = now()
    where id = a.id;

  elsif p_action in ('approve', 'reject') then
    if actor_role <> 'org_admin' then
      raise exception 'Only organization admins can decide' using errcode = '42501';
    end if;
    if a.status <> 'under_review' or a.endorsed_by is null or a.endorsed_by = auth.uid()
      or not exists (
        select 1 from public.application_evaluations e
        where e.application_id = a.id
          and e.reviewer_id = a.endorsed_by
          and e.decision = 'endorsed'
      ) then
      raise exception 'A separate reviewer endorsement is required';
    end if;

    if p_action = 'approve' then
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
    update public.applications
    set status = target_status, decided_by = auth.uid(), decided_at = now()
    where id = a.id;

    insert into public.notifications(user_id, title, message, target_id, type)
    values (
      a.user_id,
      case p_action when 'approve' then 'Application Approved' else 'Application Rejected' end,
      format('Your application for "%s" has been %s.', s.title, target_status),
      a.id::text,
      'application_update'
    );
  else
    raise exception 'Unsupported review action';
  end if;

  insert into public.application_status_history(application_id, changed_by, from_status, to_status, remarks)
  values (
    a.id,
    auth.uid(),
    a.status,
    target_status,
    case when p_action = 'endorse' then 'Endorsed to organization admin. ' else 'Final decision. ' end || coalesce(p_notes, '')
  );

  select * into strict a from public.applications where id = a.id;
  return a;
end;
$$;

revoke all on function public.review_application(uuid,text,text,jsonb,text) from public, anon;
grant execute on function public.review_application(uuid,text,text,jsonb,text) to authenticated;

commit;
