-- Profile owners may edit their details but must not reactivate themselves.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and status = 'active'
  );
$$;

create or replace function public.guard_profiles_role_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status
     and public.is_admin() is not true
     and not (auth.uid() is null and current_setting('role') in ('none', 'postgres', 'service_role')) then
    raise exception 'Unauthorized: only administrators can modify account status.';
  end if;

  if (new.role is distinct from old.role or new.provider_type is distinct from old.provider_type)
     and (public.is_admin() or pg_trigger_depth() > 1) is not true then
    raise exception 'Unauthorized: only administrators can modify role or provider_type directly.';
  end if;
  return new;
end;
$$;
