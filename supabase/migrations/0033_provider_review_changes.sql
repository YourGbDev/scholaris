-- 0033_provider_review_changes.sql
-- Atomic provider verification review decisions, expected-state validation,
-- 'changes_requested' workflow, and provider resubmission.
begin;

-- 0. Define active admin check and harden is_admin helper
create or replace function public.is_admin_active()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
      and coalesce(status, 'active') = 'active'
  );
$$;

grant execute on function public.is_admin_active() to authenticated, anon;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
      and coalesce(status, 'active') = 'active'
  );
$$;

grant execute on function public.is_admin() to authenticated, anon;

-- 1. Status enum constraint extension to support 'changes_requested'
alter table public.provider_verifications
  drop constraint if exists provider_verifications_status_check;

alter table public.provider_verifications
  add constraint provider_verifications_status_check
  check (status in ('pending', 'approved', 'rejected', 'changes_requested'));

-- 2. Drop direct admin table UPDATE policy so all review decisions must pass through the atomic RPC
drop policy if exists "Admins can update provider verifications" on public.provider_verifications;

-- 3. Update review trigger to enforce active admin, anti-self-approval, required note, and audit logging
create or replace function public.handle_provider_verification_review()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin_email text;
  v_admin_role text;
begin
  -- Trigger on status change to 'approved', 'rejected', or 'changes_requested'
  if (new.status in ('approved', 'rejected', 'changes_requested') and (old.status is distinct from new.status)) then
    -- Prevent non-admins and suspended admins from reviewing
    if not public.is_admin_active() then
      raise exception 'Unauthorized: active administrator privileges required.' using errcode = '42501';
    end if;

    -- Prevent self-review
    if new.user_id = auth.uid() then
      raise exception 'Self-review is strictly prohibited' using errcode = '42501';
    end if;

    -- Enforce review note length between 10 and 1000 characters for all review actions
    if new.review_note is null or length(trim(new.review_note)) not between 10 and 1000 then
      raise exception 'A review explanation of 10 to 1000 characters is required for all review decisions' using errcode = '22023';
    end if;

    -- Enforce valid transition: only pending or changes_requested verifications can be reviewed
    if old.status not in ('pending', 'changes_requested') then
      raise exception 'Cannot transition provider verification from status % to %', old.status, new.status using errcode = '22023';
    end if;

    -- Enforce server-side reviewer assignment
    new.reviewed_by := auth.uid();
    new.reviewed_at := now();

    -- Fetch admin profile metadata
    select email, role into v_admin_email, v_admin_role
    from public.profiles
    where id = auth.uid();

    -- Write immutable audit log row
    insert into public.audit_logs (
      actor_id,
      actor_email,
      actor_role,
      action,
      target_type,
      target_id,
      details,
      created_at
    ) values (
      auth.uid(),
      coalesce(v_admin_email, (auth.jwt() ->> 'email')),
      coalesce(v_admin_role, 'admin'),
      case new.status
        when 'approved' then 'provider_verification_approved'
        when 'changes_requested' then 'provider_verification_changes_requested'
        else 'provider_verification_rejected'
      end,
      'provider_verification',
      new.user_id::text,
      jsonb_build_object(
        'provider_type', new.provider_type,
        'previous_status', old.status,
        'new_status', new.status,
        'review_note', new.review_note
      ),
      now()
    );
  end if;

  return new;
end;
$$;

-- 4. Update RLS policy so providers with changes_requested or rejected status can update back to pending
drop policy if exists "Users can update own pending verification" on public.provider_verifications;
create policy "Users can update own pending verification"
  on public.provider_verifications for update
  to authenticated
  using (auth.uid() = user_id and status in ('pending', 'rejected', 'changes_requested'))
  with check (auth.uid() = user_id and status = 'pending');

-- 5. Atomic decision RPC: review_provider_verification
create or replace function public.review_provider_verification(
  p_user_id uuid,
  p_status text,
  p_note text default null,
  p_expected_status text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_rec public.provider_verifications;
  v_rows integer;
  v_res jsonb;
begin
  -- Enforce active platform admin role
  if not public.is_admin_active() then
    raise exception 'Admin privileges required' using errcode = '42501';
  end if;

  -- Validate expected status is provided
  if p_expected_status is null or trim(p_expected_status) = '' then
    raise exception 'Expected status is required for concurrency validation' using errcode = '22023';
  end if;

  -- Validate target status
  if p_status is null or p_status not in ('approved', 'rejected', 'changes_requested') then
    raise exception 'Invalid provider verification status: %', p_status using errcode = '22023';
  end if;

  -- Row lock for concurrency & state validation
  select * into v_rec
  from public.provider_verifications
  where user_id = p_user_id
  for update;

  if not found then
    raise exception 'Provider verification record not found for user %', p_user_id using errcode = 'P0002';
  end if;

  -- Prevent self-approval/review
  if v_rec.user_id = auth.uid() then
    raise exception 'Self-review is strictly prohibited' using errcode = '42501';
  end if;

  -- Expected state check (optimistic concurrency protection)
  if p_expected_status is not null and v_rec.status is distinct from p_expected_status then
    raise exception 'Provider verification status conflict: expected %, found %', p_expected_status, v_rec.status using errcode = '40001';
  end if;

  -- Enforce allowed source status
  if v_rec.status not in ('pending', 'changes_requested') then
    raise exception 'Cannot review provider verification with status %; only pending or changes_requested can be reviewed', v_rec.status using errcode = '22023';
  end if;

  -- Prevent transition to identical status
  if v_rec.status = p_status then
    raise exception 'Target status % matches current status', p_status using errcode = '22023';
  end if;

  -- Validate note requirements: explanation is required for ALL review actions (approved, rejected, changes_requested)
  if p_note is null or length(trim(p_note)) not between 10 and 1000 then
    raise exception 'An explanation of 10 to 1000 characters is required for all review decisions' using errcode = '22023';
  end if;

  -- Update record
  update public.provider_verifications
  set
    status = p_status,
    review_note = trim(p_note),
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    updated_at = now()
  where user_id = p_user_id;

  get diagnostics v_rows = row_count;
  if v_rows = 0 then
    raise exception 'Failed to update provider verification record' using errcode = 'P0001';
  end if;

  -- Notification to provider
  insert into public.notifications(user_id, title, message, target_id, type)
  values (
    p_user_id,
    case p_status
      when 'approved' then 'Provider accreditation approved'
      when 'changes_requested' then 'Information requested for provider accreditation'
      else 'Provider accreditation declined'
    end,
    case p_status
      when 'approved' then 'Your provider verification has been approved. Note: ' || trim(p_note)
      when 'changes_requested' then 'Action required: an administrator requested updates to your accreditation. Reason: ' || trim(p_note)
      else 'Your provider verification application was declined. Reason: ' || trim(p_note)
    end,
    p_user_id::text,
    'provider_verification_' || p_status
  );

  -- Fetch fresh updated record
  select to_jsonb(pv.*) into v_res
  from public.provider_verifications pv
  where pv.user_id = p_user_id;

  return v_res;
end;
$$;

-- 6. Provider resubmission RPC: resubmit_provider_verification
create or replace function public.resubmit_provider_verification(
  p_payload jsonb
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid;
  v_rec public.provider_verifications;
  v_res jsonb;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_rec
  from public.provider_verifications
  where user_id = v_uid
  for update;

  if not found then
    raise exception 'No provider verification found for user' using errcode = 'P0002';
  end if;

  -- Resubmission is permitted only when changes_requested or rejected
  if v_rec.status not in ('changes_requested', 'rejected', 'pending') then
    raise exception 'Approved provider verifications cannot be resubmitted' using errcode = '42501';
  end if;

  -- Update allowed fields from payload (whitelisted only)
  update public.provider_verifications
  set
    full_name = coalesce((p_payload->>'full_name'), full_name),
    email = coalesce((p_payload->>'email'), email),
    phone = coalesce((p_payload->>'phone'), phone),
    gov_id_type = coalesce((p_payload->>'gov_id_type'), gov_id_type),
    gov_id_number = coalesce((p_payload->>'gov_id_number'), gov_id_number),
    gov_id_front_path = coalesce((p_payload->>'gov_id_front_path'), gov_id_front_path),
    selfie_id_path = coalesce((p_payload->>'selfie_id_path'), selfie_id_path),
    source_of_funds = coalesce((p_payload->>'source_of_funds'), source_of_funds),
    monthly_giving_budget = coalesce((p_payload->>'monthly_giving_budget'), monthly_giving_budget),
    tin = coalesce((p_payload->>'tin'), tin),
    org_name = coalesce((p_payload->>'org_name'), org_name),
    org_type = coalesce((p_payload->>'org_type'), org_type),
    reg_number = coalesce((p_payload->>'reg_number'), reg_number),
    rep_name = coalesce((p_payload->>'rep_name'), rep_name),
    rep_position = coalesce((p_payload->>'rep_position'), rep_position),
    rep_email = coalesce((p_payload->>'rep_email'), rep_email),
    rep_phone = coalesce((p_payload->>'rep_phone'), rep_phone),
    sec_cert_path = coalesce((p_payload->>'sec_cert_path'), sec_cert_path),
    bir_2303_path = coalesce((p_payload->>'bir_2303_path'), bir_2303_path),
    board_resolution_path = coalesce((p_payload->>'board_resolution_path'), board_resolution_path),
    status = 'pending',
    review_note = null,
    submitted_at = now(),
    updated_at = now()
  where user_id = v_uid;

  -- Fetch fresh updated record
  select to_jsonb(pv.*) into v_res
  from public.provider_verifications pv
  where pv.user_id = v_uid;

  return v_res;
end;
$$;

revoke all on function public.review_provider_verification(uuid, text, text, text) from public, anon;
grant execute on function public.review_provider_verification(uuid, text, text, text) to authenticated;

revoke all on function public.resubmit_provider_verification(jsonb) from public, anon;
grant execute on function public.resubmit_provider_verification(jsonb) to authenticated;

commit;
