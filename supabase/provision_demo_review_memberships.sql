-- Trusted operator provisioning for the explicitly requested demo accounts.
-- Execute only AFTER 0024, against the project inspected for this demo.
-- Emails here locate existing users once; application authorization uses UUID
-- memberships exclusively. This neither creates accounts nor shares sessions.
begin;
do $$
declare admin_id uuid; reviewer_id uuid;
begin
  select u.id into strict admin_id from auth.users u join public.profiles p on p.id=u.id
    where u.email='demo_provider@scholaris.ph' and p.role='provider' and p.status='active';
  select u.id into strict reviewer_id from auth.users u join public.profiles p on p.id=u.id
    where u.email='demo_evaluator@scholaris.ph' and p.role='provider' and p.status='active';
  if admin_id = reviewer_id or not exists (select 1 from public.scholarships
    where id='bcb518b3-f789-45f9-997e-df6db19aab5c' and created_by=admin_id) then
    raise exception 'Demo account or scholarship ownership mismatch';
  end if;
  insert into public.organization_memberships(user_id,organization_id,role) values
    (admin_id,admin_id,'org_admin'), (reviewer_id,admin_id,'reviewer');
end;
$$;
commit;
