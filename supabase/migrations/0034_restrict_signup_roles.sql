-- Public signup metadata is user-controlled and cannot confer admin access.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role, status)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    case when new.raw_user_meta_data->>'role' = 'provider'
      then 'provider' else 'student' end,
    'active'
  );
  return new;
end;
$$;

-- An owner recreating a missing profile cannot grant themselves admin access.
drop policy if exists "Profiles are insertable by owner" on public.profiles;
create policy "Profiles are insertable by owner"
  on public.profiles for insert to authenticated
  with check (
    auth.uid() = id
    and role in ('student', 'provider')
    and status = 'active'
  );
