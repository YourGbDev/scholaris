-- 0032_student_safety_reports.sql
-- Scholarship-level student safety reporting independent of applications.
-- Privacy isolation: strictly isolated from provider access (RA 10173).
begin;

create table if not exists public.student_safety_reports (
  id uuid primary key default gen_random_uuid(),
  scholarship_id uuid not null references public.scholarships(id) on delete restrict,
  provider_id uuid not null references public.profiles(id) on delete restrict,
  reporter_id uuid not null references public.profiles(id) on delete restrict,
  category text not null check (
    category in (
      'fraud',
      'unsafe_meetup',
      'unsafe_request',
      'harassment',
      'threat',
      'release_fee',
      'payment_problem',
      'payment_not_received',
      'other'
    )
  ),
  relationship text not null check (
    relationship in ('experienced', 'witnessed', 'told', 'first_hand')
  ),
  description text not null check (length(trim(description)) between 10 and 2000),
  incident_on date check (incident_on is null or incident_on <= current_date),
  status text not null default 'open' check (
    status in ('open', 'under_review', 'resolved', 'dismissed')
  ),
  resolution_note text check (
    resolution_note is null or length(trim(resolution_note)) between 10 and 1000
  ),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Unique constraint: one open report per (scholarship, reporter, category)
create unique index if not exists one_open_safety_report
  on public.student_safety_reports (scholarship_id, reporter_id, category)
  where status in ('open', 'under_review');

create index if not exists idx_safety_reports_scholarship_status
  on public.student_safety_reports (scholarship_id, status, created_at);

create index if not exists idx_safety_reports_reporter
  on public.student_safety_reports (reporter_id, created_at);

create index if not exists idx_safety_reports_provider
  on public.student_safety_reports (provider_id, created_at);

alter table public.student_safety_reports enable row level security;
revoke all on public.student_safety_reports from public, anon, authenticated;
grant select on public.student_safety_reports to authenticated;

-- RLS: Only the reporter themselves or an active platform admin can view reports.
-- Providers strictly have ZERO read access.
drop policy if exists safety_report_read on public.student_safety_reports;
create policy safety_report_read on public.student_safety_reports
  for select to authenticated
  using (
    reporter_id = auth.uid() or public.is_support_admin()
  );

-- Evidence table
create table if not exists public.student_safety_report_evidence (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.student_safety_reports(id) on delete cascade,
  file_path text not null,
  file_name text not null,
  file_size_bytes integer check (file_size_bytes between 1 and 5242880),
  mime_type text check (mime_type in ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')),
  uploaded_at timestamptz not null default now()
);

create index if not exists idx_safety_evidence_report
  on public.student_safety_report_evidence (report_id);

create unique index if not exists idx_safety_evidence_file_path
  on public.student_safety_report_evidence (file_path);

alter table public.student_safety_report_evidence enable row level security;
revoke all on public.student_safety_report_evidence from public, anon, authenticated;
grant select on public.student_safety_report_evidence to authenticated;

drop policy if exists safety_evidence_read on public.student_safety_report_evidence;
create policy safety_evidence_read on public.student_safety_report_evidence
  for select to authenticated
  using (
    exists (
      select 1 from public.student_safety_reports r
      where r.id = report_id
        and (r.reporter_id = auth.uid() or public.is_support_admin())
    )
  );

-- Ensure metadata column exists on storage.objects for environments lacking full storage schema
do $$
begin
  alter table storage.objects add column if not exists metadata jsonb;
exception when others then
  null;
end $$;

-- Private Storage Bucket for Student Safety Evidence
do $$
begin
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values (
    'safety_reports',
    'safety_reports',
    false,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
  ) on conflict (id) do update set
    public = false,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
exception when others then
  begin
    insert into storage.buckets (id, name, public)
    values ('safety_reports', 'safety_reports', false)
    on conflict (id) do nothing;
  exception when others then
    null;
  end;
end $$;

drop policy if exists "Reporters can upload safety report evidence" on storage.objects;
create policy "Reporters can upload safety report evidence"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'safety_reports'
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role = 'student'
        and coalesce(p.status, 'active') = 'active'
    )
    and exists (
      select 1 from public.student_safety_reports r
      where (storage.foldername(name))[2] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        and r.id = ((storage.foldername(name))[2])::uuid
        and r.reporter_id = auth.uid()
        and r.status in ('open', 'under_review')
    )
  );

drop policy if exists "Reporters and admins can read safety report evidence" on storage.objects;
create policy "Reporters and admins can read safety report evidence"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'safety_reports'
    and (
      public.is_support_admin()
      or (
        (storage.foldername(name))[1] = auth.uid()::text
        and exists (
          select 1 from public.profiles p
          where p.id = auth.uid()
            and p.role = 'student'
            and coalesce(p.status, 'active') = 'active'
        )
        and exists (
          select 1 from public.student_safety_reports r
          where (storage.foldername(name))[2] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            and r.id = ((storage.foldername(name))[2])::uuid
            and r.reporter_id = auth.uid()
        )
      )
    )
  );

drop policy if exists "Reporters can delete own unattached evidence" on storage.objects;
create policy "Reporters can delete own unattached evidence"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'safety_reports'
    and (storage.foldername(name))[1] = auth.uid()::text
    and not exists (
      select 1 from public.student_safety_report_evidence e
      where e.file_path = name
    )
  );

-- Shared server serialization guard against concurrent delete / registration race
create or replace function public.guard_safety_report_evidence_delete()
returns trigger
language plpgsql security definer as $$
begin
  if OLD.bucket_id = 'safety_reports' then
    -- Coordinate with attach_safety_report_evidence using transaction-scoped advisory lock
    perform pg_advisory_xact_lock(hashtext('safety_reports:' || OLD.name));

    if exists (
      select 1 from public.student_safety_report_evidence
      where file_path = OLD.name
    ) then
      -- Attached evidence must never be deleted; return NULL to skip deletion of this row
      return null;
    end if;
  end if;
  return OLD;
end;
$$;

drop trigger if exists trg_guard_safety_report_evidence_delete on storage.objects;
create trigger trg_guard_safety_report_evidence_delete
  before delete on storage.objects
  for each row
  execute function public.guard_safety_report_evidence_delete();

-- Immutable audit history for safety report lifecycle
create table if not exists public.student_safety_report_history (
  id bigint generated always as identity primary key,
  report_id uuid not null references public.student_safety_reports(id) on delete cascade,
  from_status text not null,
  to_status text not null,
  action_note text,
  actor_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_safety_history_report
  on public.student_safety_report_history (report_id, created_at);

alter table public.student_safety_report_history enable row level security;
revoke all on public.student_safety_report_history from public, anon, authenticated;
grant select on public.student_safety_report_history to authenticated;

drop policy if exists safety_history_admin_read on public.student_safety_report_history;
create policy safety_history_admin_read on public.student_safety_report_history
  for select to authenticated
  using (
    exists (
      select 1 from public.student_safety_reports r
      where r.id = report_id
        and (r.reporter_id = auth.uid() or public.is_support_admin())
    )
  );

-- RPC: submit_student_safety_report
create or replace function public.submit_student_safety_report(
  p_scholarship uuid,
  p_category text,
  p_relationship text,
  p_description text,
  p_incident_on date default null
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid;
  v_role text;
  v_scholarship record;
  v_provider uuid;
  v_recent_count int;
  v_id uuid;
  v_rel text;
  v_cat text;
  v_user_urgent_count int;
  v_distinct_24h int;
  v_surge_alerted boolean;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  -- Serialize per-reporter submission to eliminate daily quota race conditions
  perform 1 from public.profiles where id = v_uid for update;

  -- Ensure actor is an active student or profile (providers cannot submit student reports)
  select role into v_role from public.profiles where id = v_uid and status = 'active';
  if v_role is distinct from 'student' and not public.is_support_admin() then
    raise exception 'Only active students may submit safety reports' using errcode = '42501';
  end if;

  -- Enforce rate-limit: maximum 5 reports per reporter per 24 hours
  select count(*) into v_recent_count
  from public.student_safety_reports
  where reporter_id = v_uid and created_at > now() - interval '24 hours';

  if v_recent_count >= 5 then
    raise exception 'Daily report submission limit reached (5 per 24 hours)' using errcode = '42501';
  end if;

  -- Validate and lock scholarship to resolve provider and prevent threshold race conditions
  select * into v_scholarship from public.scholarships where id = p_scholarship for update;
  if not found then
    raise exception 'Scholarship unavailable' using errcode = '42501';
  end if;

  v_provider := v_scholarship.created_by;
  if v_provider is null then
    raise exception 'Target scholarship provider unavailable' using errcode = '42501';
  end if;

  -- Normalize canonical keys
  v_rel := case p_relationship
    when 'first_hand' then 'experienced'
    else p_relationship
  end;

  v_cat := case p_category
    when 'unsafe_request' then 'unsafe_meetup'
    when 'payment_not_received' then 'payment_problem'
    else p_category
  end;

  -- Check incident date not future
  if p_incident_on is not null and p_incident_on > current_date then
    raise exception 'Incident date cannot be in the future';
  end if;

  -- Insert report row
  insert into public.student_safety_reports(
    scholarship_id,
    provider_id,
    reporter_id,
    category,
    relationship,
    description,
    incident_on
  ) values (
    p_scholarship,
    v_provider,
    v_uid,
    v_cat,
    v_rel,
    trim(p_description),
    p_incident_on
  ) returning id into v_id;

  -- Append audit history
  insert into public.student_safety_report_history(
    report_id,
    from_status,
    to_status,
    actor_id
  ) values (
    v_id,
    'none',
    'open',
    v_uid
  );

  -- Alert 1: Urgent category notification on first report by this user in 24h
  if v_cat in ('harassment', 'unsafe_meetup', 'threat') then
    select count(*) into v_user_urgent_count
    from public.student_safety_reports
    where scholarship_id = p_scholarship
      and reporter_id = v_uid
      and category in ('harassment', 'unsafe_meetup', 'threat')
      and created_at > now() - interval '24 hours';

    if v_user_urgent_count <= 1 then
      insert into public.notifications(user_id, title, message, target_id, type)
      select
        id,
        'Urgent safety report',
        'An urgent student concern (' || v_cat || ') was submitted for scholarship ' || v_scholarship.title || '.',
        v_id::text,
        'admin_safety_alert'
      from public.profiles
      where role = 'admin' and status = 'active';
    end if;
  end if;

  -- Alert 2: Distinct-reporter surge alert (fires once upon reaching threshold >= 3 in 24h)
  select count(distinct reporter_id) into v_distinct_24h
  from public.student_safety_reports
  where scholarship_id = p_scholarship
    and created_at > now() - interval '24 hours';

  select exists (
    select 1 from public.notifications
    where target_id = p_scholarship::text
      and type = 'admin_safety_surge'
      and created_at > now() - interval '24 hours'
  ) into v_surge_alerted;

  if v_distinct_24h >= 3 and not v_surge_alerted then
    insert into public.notifications(user_id, title, message, target_id, type)
    select
      id,
      'Safety surge priority',
      '3 distinct students have reported concerns in the last 24 hours regarding scholarship ' || v_scholarship.title || '. Review priority queue.',
      p_scholarship::text,
      'admin_safety_surge'
    from public.profiles
    where role = 'admin' and status = 'active';
  end if;

  -- Confirmation receipt to student reporter
  insert into public.notifications(user_id, title, message, target_id, type)
  values (
    v_uid,
    'Safety report received',
    'Your report regarding ' || v_scholarship.title || ' has been received. Platform administrators will review the details confidentially.',
    v_id::text,
    'student_report_receipt'
  );

  return v_id;
end;
$$;

-- RPC: review_student_safety_report
create or replace function public.review_student_safety_report(
  p_report uuid,
  p_status text,
  p_note text
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  r public.student_safety_reports;
  v_res jsonb;
begin
  if not public.is_support_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;

  select * into r from public.student_safety_reports where id = p_report for update;
  if not found then
    raise exception 'Report unavailable';
  end if;

  if p_status is null or p_status not in ('under_review', 'resolved', 'dismissed') then
    raise exception 'Invalid review status';
  end if;

  if p_note is null or length(trim(p_note)) not between 10 and 1000 then
    raise exception 'A review explanation of 10 to 1000 characters is required';
  end if;

  update public.student_safety_reports
  set
    status = p_status,
    resolution_note = trim(p_note),
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    updated_at = now()
  where id = p_report;

  insert into public.student_safety_report_history(
    report_id,
    from_status,
    to_status,
    action_note,
    actor_id
  ) values (
    p_report,
    r.status,
    p_status,
    trim(p_note),
    auth.uid()
  );

  -- Notify reporter when report moves to resolved or dismissed
  if p_status in ('resolved', 'dismissed') then
    insert into public.notifications(user_id, title, message, target_id, type)
    values (
      r.reporter_id,
      'Safety report update',
      'Your submitted report has been marked ' || p_status || '. Note: ' || trim(p_note),
      p_report::text,
      'student_report_' || p_status
    );
  end if;

  select to_jsonb(sr.*) into v_res
  from public.student_safety_reports sr
  where sr.id = p_report;

  return v_res;
end;
$$;

-- RPC: attach_safety_report_evidence
create or replace function public.attach_safety_report_evidence(
  p_report uuid,
  p_path text,
  p_name text,
  p_size integer,
  p_mime text
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  r public.student_safety_reports;
  v_count int;
  v_id uuid;
  v_storage_meta jsonb;
  v_valid_mime text;
  v_valid_size integer;
begin
  select * into r from public.student_safety_reports where id = p_report for update;
  if not found then
    raise exception 'Report not found' using errcode = '42501';
  end if;

  if r.reporter_id is distinct from auth.uid() and not public.is_support_admin() then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  if r.status in ('resolved', 'dismissed') then
    raise exception 'Cannot attach evidence to a closed report';
  end if;

  -- Validate path structure belongs strictly to reporter and report
  if p_path not like (r.reporter_id::text || '/' || p_report::text || '/%') then
    raise exception 'Invalid evidence file path structure' using errcode = '42501';
  end if;

  -- Prevent duplicate registration of the same storage object across reports
  if exists (
    select 1 from public.student_safety_report_evidence
    where file_path = p_path
  ) then
    raise exception 'Evidence object already registered: %', p_path using errcode = '23505';
  end if;

  -- Coordinate object deletion and registration with shared server transaction advisory lock
  perform pg_advisory_xact_lock(hashtext('safety_reports:' || p_path));

  -- Verify object actually exists in private storage bucket and acquire row lock against concurrent delete
  select metadata into v_storage_meta
  from storage.objects
  where bucket_id = 'safety_reports'
    and name = p_path
  for update;
  if not found then
    raise exception 'Storage object does not exist in safety_reports bucket: %', p_path using errcode = '42501';
  end if;

  -- Validate declared client parameters
  if p_mime not in ('image/jpeg', 'image/png', 'image/webp', 'application/pdf') then
    raise exception 'Unsupported evidence MIME type: %', p_mime using errcode = '22023';
  end if;

  if p_size is null or p_size <= 0 or p_size > 5242880 then
    raise exception 'Evidence file size must be between 1 and 5242880 bytes' using errcode = '22023';
  end if;

  -- Validate MIME type against stored metadata if available, else client parameter
  v_valid_mime := coalesce(v_storage_meta->>'mimetype', v_storage_meta->>'contentType', p_mime);
  if v_valid_mime not in ('image/jpeg', 'image/png', 'image/webp', 'application/pdf') then
    raise exception 'Unsupported evidence MIME type: %', v_valid_mime using errcode = '22023';
  end if;

  -- Validate file size <= 5MB against stored metadata if available, else client parameter
  v_valid_size := coalesce((v_storage_meta->>'size')::integer, (v_storage_meta->>'contentLength')::integer, p_size);
  if v_valid_size is null or v_valid_size <= 0 or v_valid_size > 5242880 then
    raise exception 'Evidence file size must be between 1 and 5242880 bytes' using errcode = '22023';
  end if;

  select count(*) into v_count
  from public.student_safety_report_evidence
  where report_id = p_report;

  if v_count >= 3 then
    raise exception 'Maximum of 3 evidence files allowed per report';
  end if;

  insert into public.student_safety_report_evidence(
    report_id,
    file_path,
    file_name,
    file_size_bytes,
    mime_type
  ) values (
    p_report,
    p_path,
    p_name,
    v_valid_size,
    v_valid_mime
  ) returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.submit_student_safety_report(uuid, text, text, text, date) from public, anon;
grant execute on function public.submit_student_safety_report(uuid, text, text, text, date) to authenticated;

revoke all on function public.review_student_safety_report(uuid, text, text) from public, anon;
grant execute on function public.review_student_safety_report(uuid, text, text) to authenticated;

revoke all on function public.attach_safety_report_evidence(uuid, text, text, integer, text) from public, anon;
grant execute on function public.attach_safety_report_evidence(uuid, text, text, integer, text) to authenticated;

commit;
