-- Auth owns email verification; synchronize only the email it has committed.
create or replace function public.sync_profile_auth_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles set email = new.email where id = new.id;
  return new;
end;
$$;

drop trigger if exists sync_profile_auth_email on auth.users;
create trigger sync_profile_auth_email
  after update of email on auth.users
  for each row
  when (old.email is distinct from new.email)
  execute function public.sync_profile_auth_email();
