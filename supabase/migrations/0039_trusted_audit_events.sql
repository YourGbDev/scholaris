-- Client reports are not authoritative evidence that an operation succeeded.
revoke insert on public.audit_logs from public, anon, authenticated;
do $$
declare v_columns text;
begin
  select string_agg(format('%I', attname), ', ' order by attnum) into v_columns
  from pg_attribute where attrelid = 'public.audit_logs'::regclass and attnum > 0 and not attisdropped;
  execute format('revoke insert (%s) on public.audit_logs from public, anon, authenticated', v_columns);
end;
$$;
drop policy if exists "Authenticated users can record audit actions" on public.audit_logs;

create or replace function public.log_audit_event(
  p_action text, p_target_type text, p_target_id text default null, p_details jsonb default '{}'::jsonb
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_email text;
  v_target uuid;
  v_title text;
  v_provider text;
  v_details jsonb := coalesce(p_details, '{}'::jsonb);
  v_reason text;
  v_note text;
  v_id uuid;
begin
  if v_actor is null or public.is_admin() is not true then
    raise exception 'An active administrator is required.' using errcode = '42501';
  end if;
  -- Older clients still report these after the actual row mutation. The row
  -- triggers own the evidence; tolerate the call without creating a duplicate.
  if p_action in ('user_created','user_updated','user_deleted','user_deactivated',
      'role_and_status_updated','scholarship_activated','scholarship_paused') then
    return null;
  end if;
  if p_action is distinct from 'scholarship_flagged' or p_target_type is distinct from 'scholarship' then
    raise exception 'This client audit action is not supported.' using errcode = '22023';
  end if;
  if jsonb_typeof(v_details) is distinct from 'object'
     or exists (select 1 from jsonb_object_keys(v_details) k where k not in ('reason','resolution_note','title','provider')) then
    raise exception 'Unsupported audit details.' using errcode = '22023';
  end if;
  if jsonb_typeof(v_details -> 'reason') is distinct from 'string' then
    raise exception 'A text reason is required.' using errcode = '22023';
  end if;
  v_reason := btrim(v_details ->> 'reason');
  if length(v_reason) not between 1 and 500 then
    raise exception 'The reason must contain 1 to 500 characters.' using errcode = '22023';
  end if;
  if v_details ? 'resolution_note' and jsonb_typeof(v_details -> 'resolution_note') not in ('string','null') then
    raise exception 'The resolution note must be text.' using errcode = '22023';
  end if;
  v_note := nullif(btrim(v_details ->> 'resolution_note'), '');
  if length(v_note) > 1000 then
    raise exception 'The resolution note is too long.' using errcode = '22023';
  end if;
  begin v_target := p_target_id::uuid;
  exception when invalid_text_representation then
    raise exception 'A valid scholarship identifier is required.' using errcode = '22023';
  end;
  select title, provider into v_title, v_provider from public.scholarships where id = v_target;
  if not found then raise exception 'The scholarship was not found.' using errcode = 'P0002'; end if;
  select email into v_email from auth.users where id = v_actor;
  insert into public.audit_logs(actor_id,actor_email,actor_role,action,target_type,target_id,details)
  values(v_actor,v_email,'admin','scholarship_flagged','scholarship',v_target::text,
    jsonb_strip_nulls(jsonb_build_object('source','database_rpc','outcome','success',
      'title',v_title,'provider',v_provider,'reason',v_reason,'resolution_note',v_note))) returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.log_audit_event(text,text,text,jsonb) from public, anon;
grant execute on function public.log_audit_event(text,text,text,jsonb) to authenticated;

-- Keep the existing transactional profile-update events, but source the actor's
-- email from Auth rather than the profile email field that owners can edit.
create or replace function public.audit_admin_profile_update()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_actor uuid := auth.uid(); v_email text;
begin
  if v_actor is null or public.is_admin() is not true or new is not distinct from old then return new; end if;
  select email into v_email from auth.users where id = v_actor;
  insert into public.audit_logs(actor_id,actor_email,actor_role,action,target_type,target_id,details)
  values(v_actor,v_email,'admin','user_updated','user',old.id::text,jsonb_build_object('source','database','outcome','success'));
  if new.role is distinct from old.role then
    insert into public.audit_logs(actor_id,actor_email,actor_role,action,target_type,target_id,details)
    values(v_actor,v_email,'admin','user_role_changed','user',old.id::text,
      jsonb_build_object('source','database','outcome','success','old_role',old.role,'new_role',new.role));
  end if;
  if new.status is distinct from old.status then
    insert into public.audit_logs(actor_id,actor_email,actor_role,action,target_type,target_id,details)
    values(v_actor,v_email,'admin','user_status_changed','user',old.id::text,
      jsonb_build_object('source','database','outcome','success','old_status',old.status,'new_status',new.status));
  end if;
  return new;
end;
$$;
revoke all on function public.audit_admin_profile_update() from public, anon, authenticated;

create or replace function public.audit_profile_lifecycle()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_actor uuid := auth.uid(); v_email text; v_role text; v_target uuid; v_action text;
begin
  -- An Auth-side cascade may already have removed the actor's Auth row.
  if v_actor is not null and not exists(select 1 from auth.users where id=v_actor) then v_actor := null; end if;
  select email into v_email from auth.users where id=v_actor;
  select role into v_role from public.profiles where id=v_actor;
  if tg_op='DELETE' then v_target:=old.id; v_action:='user_deleted';
  else v_target:=new.id; v_action:='user_created'; end if;
  insert into public.audit_logs(actor_id,actor_email,actor_role,action,target_type,target_id,details)
  values(v_actor,v_email,coalesce(v_role,case when v_actor is null then 'system' else 'unknown' end),
    v_action,'user',v_target::text,jsonb_build_object('source','database_profile','outcome','success'));
  if tg_op='DELETE' then return old; else return new; end if;
end;
$$;
revoke all on function public.audit_profile_lifecycle() from public, anon, authenticated;
drop trigger if exists audit_profile_created on public.profiles;
create trigger audit_profile_created after insert on public.profiles for each row execute function public.audit_profile_lifecycle();
drop trigger if exists audit_profile_deleted on public.profiles;
create trigger audit_profile_deleted before delete on public.profiles for each row execute function public.audit_profile_lifecycle();

create or replace function public.audit_scholarship_change()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_actor uuid := auth.uid(); v_email text; v_role text; v_action text; v_target uuid;
begin
  if tg_op='UPDATE' and new is not distinct from old then return new; end if;
  if v_actor is not null and not exists(select 1 from auth.users where id=v_actor) then v_actor:=null; end if;
  select email into v_email from auth.users where id=v_actor;
  select role into v_role from public.profiles where id=v_actor;
  if tg_op='DELETE' then v_action:='scholarship_deleted'; v_target:=old.id;
  elsif tg_op='INSERT' then v_action:='scholarship_created'; v_target:=new.id;
  elsif new.is_active is distinct from old.is_active then
    v_action:=case when new.is_active is true then 'scholarship_activated' else 'scholarship_paused' end; v_target:=new.id;
  else v_action:='scholarship_updated'; v_target:=new.id; end if;
  insert into public.audit_logs(actor_id,actor_email,actor_role,action,target_type,target_id,details)
  values(v_actor,v_email,coalesce(v_role,case when v_actor is null then 'system' else 'unknown' end),v_action,
    'scholarship',v_target::text,jsonb_build_object('source','database','outcome','success'));
  if tg_op='DELETE' then return old; else return new; end if;
end;
$$;
revoke all on function public.audit_scholarship_change() from public, anon, authenticated;
drop trigger if exists audit_scholarship_change on public.scholarships;
create trigger audit_scholarship_change after insert or update or delete on public.scholarships
for each row execute function public.audit_scholarship_change();

create or replace function public.set_admin_scholarship_active(p_id uuid, p_active boolean)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if auth.uid() is null or public.is_admin() is not true then
    raise exception 'An active administrator is required.' using errcode = '42501';
  end if;
  if p_id is null or p_active is null then
    raise exception 'A scholarship and active status are required.' using errcode = '22023';
  end if;
  update public.scholarships set is_active = p_active where id = p_id returning id into v_id;
  if not found then raise exception 'The scholarship was not found.' using errcode = 'P0002'; end if;
  return v_id;
end;
$$;
revoke all on function public.set_admin_scholarship_active(uuid,boolean) from public, anon;
grant execute on function public.set_admin_scholarship_active(uuid,boolean) to authenticated;

create or replace function public.audit_auth_event()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_action text := new.payload ->> 'action';
  v_actor_text text := coalesce(new.payload ->> 'actor_id',new.payload ->> 'user_id');
  v_actor uuid; v_target text; v_email text; v_role text; v_ip text;
begin
  -- Only documented Auth event names are mirrored. Never copy arbitrary traits,
  -- actor usernames, request bodies, passwords, JWTs or OTPs from the payload.
  if v_action is null or v_action not in (
    'login','logout','invite_accepted','user_signedup','user_invited','user_deleted','user_modified',
    'user_recovery_requested','user_reauthenticate_requested','user_confirmation_requested','user_repeated_signup',
    'user_updated_password','token_revoked','token_refreshed','generate_recovery_codes','factor_in_progress',
    'factor_unenrolled','challenge_created','verification_attempted','factor_deleted','recovery_codes_deleted',
    'factor_updated','mfa_code_login','identity_unlinked'
  ) then return new; end if;
  begin v_actor:=v_actor_text::uuid;
  exception when invalid_text_representation then v_actor:=null; end;
  v_target:=v_actor::text;
  if not exists(select 1 from auth.users where id=v_actor) then v_actor:=null; end if;
  select email into v_email from auth.users where id=v_actor;
  select role into v_role from public.profiles where id=v_actor;
  begin v_ip:=host(nullif(new.ip_address,'')::inet);
  exception when invalid_text_representation then v_ip:=null; end;
  insert into public.audit_logs(actor_id,actor_email,actor_role,action,target_type,target_id,details,ip_address,created_at)
  values(v_actor,v_email,coalesce(v_role,'unknown'),'auth_'||v_action,'auth',v_target,
    jsonb_build_object('source','supabase_auth','outcome','recorded','auth_action',v_action,'auth_event_id',new.id::text),
    v_ip,coalesce(new.created_at,now()));
  -- Failure intentionally aborts the Auth audit insert too; no silent gap.
  return new;
end;
$$;
revoke all on function public.audit_auth_event() from public, anon, authenticated;
drop trigger if exists scholaris_auth_audit on auth.audit_log_entries;
create trigger scholaris_auth_audit after insert on auth.audit_log_entries
for each row execute function public.audit_auth_event();
