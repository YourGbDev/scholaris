-- 0040_admin_unlock_account.sql
-- Authoritative Admin Account Unlock RPC and Audit Trail
--
-- IAS1 Indicator C3: Account Lockout & Administrative Unlock
-- Provides an authoritative, active-admin-only RPC to reset consecutive failed
-- login attempts and clear lockout status across all client devices.
--
-- When an administrator unlocks an account:
-- 1. Verifies that caller is an active administrator (public.is_admin() is true).
-- 2. Inserts an authoritative success entry into public.login_attempts with now(),
--    which causes public.get_login_lockout_status(email) to calculate zero failed
--    attempts since the last success, clearing lockout on any client.
-- 3. Inserts an immutable audit log record in public.audit_logs capturing the action,
--    administrator identity, and target email.

create or replace function public.admin_unlock_account(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_email text;
  v_target_email text := lower(btrim(p_email));
  v_id uuid;
begin
  if v_actor is null or public.is_admin() is not true then
    raise exception 'An active administrator is required.' using errcode = '42501';
  end if;

  if v_target_email is null or v_target_email = '' then
    raise exception 'Target email cannot be empty.' using errcode = '22023';
  end if;

  -- 1. Insert an authoritative success record in login_attempts to reset the lockout window
  insert into public.login_attempts (
    email,
    attempt_time,
    success,
    user_agent
  ) values (
    v_target_email,
    now(),
    true,
    'admin_unlock'
  );

  -- 2. Source administrator email from auth.users
  select email into v_email from auth.users where id = v_actor;

  -- 3. Record authoritative immutable audit log event
  insert into public.audit_logs (
    actor_id,
    actor_email,
    actor_role,
    action,
    target_type,
    target_id,
    details
  ) values (
    v_actor,
    v_email,
    'admin',
    'ADMIN_USER_UNLOCKED',
    'user_account',
    v_target_email,
    jsonb_build_object(
      'source', 'admin_console',
      'outcome', 'success',
      'unlocked_email', v_target_email
    )
  ) returning id into v_id;

  return jsonb_build_object(
    'success', true,
    'unlocked_email', v_target_email,
    'audit_id', v_id
  );
end;
$$;

revoke all on function public.admin_unlock_account(text) from public, anon;
grant execute on function public.admin_unlock_account(text) to authenticated;
