-- =============================================================================
-- Scholaris — 0011: IAS Module: Security Validations, Account Lockout & Audit Trail
--
-- 1. login_attempts table: tracks authentication attempts for lockout escalation
-- 2. audit_logs table: immutable system ledger of administrative and user actions
-- 3. Row-Level Security (RLS) restricting audit logs access to administrators
-- 4. Helper functions for lockout calculation and audit event ingestion
-- =============================================================================

-- 0. Defensive check for is_admin helper
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

grant execute on function public.is_admin() to authenticated, anon;

-- 1. Login Attempts table
create table if not exists public.login_attempts (
  id           uuid primary key default gen_random_uuid(),
  email        text not null,
  attempt_time timestamptz not null default now(),
  success      boolean not null default false,
  ip_address   text,
  user_agent   text
);

create index if not exists idx_login_attempts_email_time 
  on public.login_attempts (email, attempt_time desc);

alter table public.login_attempts enable row level security;

-- Only admins can inspect login attempts directly
drop policy if exists "Admins can select login attempts" on public.login_attempts;
create policy "Admins can select login attempts"
  on public.login_attempts for select
  to authenticated
  using (public.is_admin());

-- Service role or functions can insert attempts
drop policy if exists "Anyone can insert login attempts via service" on public.login_attempts;
create policy "Anyone can insert login attempts via service"
  on public.login_attempts for insert
  to anon, authenticated
  with check (true);

-- 2. Audit Logs table
create table if not exists public.audit_logs (
  id          uuid primary key default gen_random_uuid(),
  actor_id    uuid references auth.users(id) on delete set null,
  actor_email text,
  actor_role  text not null default 'unknown',
  action      text not null,
  target_type text not null,
  target_id   text,
  details     jsonb default '{}'::jsonb,
  ip_address  text,
  created_at  timestamptz not null default now()
);

create index if not exists idx_audit_logs_created_at 
  on public.audit_logs (created_at desc);

create index if not exists idx_audit_logs_actor_id 
  on public.audit_logs (actor_id);

create index if not exists idx_audit_logs_action 
  on public.audit_logs (action);

alter table public.audit_logs enable row level security;

-- Only admins can read audit logs
drop policy if exists "Admins can view audit logs" on public.audit_logs;
create policy "Admins can view audit logs"
  on public.audit_logs for select
  to authenticated
  using (public.is_admin());

-- Authenticated users can record audit actions
drop policy if exists "Authenticated users can record audit actions" on public.audit_logs;
create policy "Authenticated users can record audit actions"
  on public.audit_logs for insert
  to authenticated
  with check (auth.uid() = actor_id or actor_id is null or public.is_admin());

-- 3. Security Definer helper: log_audit_event
create or replace function public.log_audit_event(
  p_action text,
  p_target_type text,
  p_target_id text default null,
  p_details jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_user_email text;
  v_user_role text;
  v_log_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is not null then
    select email into v_user_email from auth.users where id = v_user_id;
    select coalesce(role, 'student') into v_user_role from public.profiles where id = v_user_id;
  end if;
  
  insert into public.audit_logs (
    actor_id,
    actor_email,
    actor_role,
    action,
    target_type,
    target_id,
    details
  ) values (
    v_user_id,
    v_user_email,
    coalesce(v_user_role, 'unknown'),
    p_action,
    p_target_type,
    p_target_id,
    p_details
  ) returning id into v_log_id;

  return v_log_id;
end;
$$;

grant execute on function public.log_audit_event(text, text, text, jsonb) to authenticated, anon;

-- 4. Server-side lockout calculator helper
create or replace function public.get_login_lockout_status(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recent_attempts int;
  v_last_attempt timestamptz;
  v_lockout_mins int := 0;
  v_locked_until timestamptz := null;
  v_is_locked boolean := false;
begin
  -- Count consecutive failed attempts since the last successful login
  select count(*), max(attempt_time)
  into v_recent_attempts, v_last_attempt
  from public.login_attempts
  where email = lower(trim(p_email))
    and success = false
    and attempt_time > coalesce(
      (select max(attempt_time) from public.login_attempts where email = lower(trim(p_email)) and success = true),
      '-infinity'::timestamptz
    );

  if v_recent_attempts >= 5 then
    v_lockout_mins := 60;
  elsif v_recent_attempts = 4 then
    v_lockout_mins := 15;
  elsif v_recent_attempts = 3 then
    v_lockout_mins := 5;
  end if;

  if v_lockout_mins > 0 and v_last_attempt is not null then
    v_locked_until := v_last_attempt + (v_lockout_mins || ' minutes')::interval;
    if now() < v_locked_until then
      v_is_locked := true;
    end if;
  end if;

  return jsonb_build_object(
    'is_locked', v_is_locked,
    'failed_attempts', coalesce(v_recent_attempts, 0),
    'locked_until', v_locked_until
  );
end;
$$;

grant execute on function public.get_login_lockout_status(text) to anon, authenticated;

-- 5. Admin User Management Permissions on public.profiles
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists status text default 'active'
  check (status in ('active', 'deactivated', 'suspended'));

-- Backfill profile emails from auth.users where possible
update public.profiles p
set email = u.email
from auth.users u
where p.id = u.id and (p.email is null or p.email = '');

-- Update auth trigger to populate email and role automatically on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role, status)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    coalesce(new.raw_user_meta_data->>'role', 'student'),
    'active'
  );
  return new;
end;
$$;

-- Allow administrators to SELECT all profiles for User Management
drop policy if exists "Admins can select all profiles" on public.profiles;
create policy "Admins can select all profiles"
  on public.profiles for select
  to authenticated
  using (public.is_admin());

-- Allow administrators to UPDATE any profile (role changes, deactivations, status updates)
drop policy if exists "Admins can update all profiles" on public.profiles;
create policy "Admins can update all profiles"
  on public.profiles for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Allow administrators to DELETE profiles
drop policy if exists "Admins can delete profiles" on public.profiles;
create policy "Admins can delete profiles"
  on public.profiles for delete
  to authenticated
  using (public.is_admin());
