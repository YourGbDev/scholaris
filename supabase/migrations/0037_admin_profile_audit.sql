-- Record administrator profile edits in the same transaction as the change.
-- Do not store profile contents or credentials in the audit trail.
create or replace function public.audit_admin_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_email text;
begin
  if v_actor is null or public.is_admin() is not true or new is not distinct from old then
    return new;
  end if;
  select email into v_email from public.profiles where id = v_actor;
  insert into public.audit_logs (actor_id, actor_email, actor_role, action, target_type, target_id, details)
  values (v_actor, v_email, 'admin', 'user_updated', 'user', old.id::text, '{}'::jsonb);
  if new.role is distinct from old.role then
    insert into public.audit_logs (actor_id, actor_email, actor_role, action, target_type, target_id, details)
    values (v_actor, v_email, 'admin', 'user_role_changed', 'user', old.id::text,
      jsonb_build_object('old_role', old.role, 'new_role', new.role));
  end if;
  if new.status is distinct from old.status then
    insert into public.audit_logs (actor_id, actor_email, actor_role, action, target_type, target_id, details)
    values (v_actor, v_email, 'admin', 'user_status_changed', 'user', old.id::text,
      jsonb_build_object('old_status', old.status, 'new_status', new.status));
  end if;
  return new;
end;
$$;

revoke all on function public.audit_admin_profile_update() from public, anon, authenticated;
drop trigger if exists audit_admin_profile_update on public.profiles;
create trigger audit_admin_profile_update before update on public.profiles
for each row execute function public.audit_admin_profile_update();
