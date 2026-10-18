-- Compatibility only: retain 0009's existing platform-admin approved -> awarded
-- transition. It does NOT authorize platform-admin approval or rejection.
begin;
drop policy application_student_update_boundary on public.applications;
create policy application_student_update_boundary on public.applications
  as restrictive for update to authenticated
  using ((user_id = auth.uid() and status in ('draft','submitted','under_review'))
    or (public.is_admin() and status = 'approved'))
  with check ((user_id = auth.uid() and status in ('draft','submitted','under_review','withdrawn'))
    or (public.is_admin() and status = 'awarded'));
create policy "Admins can update approved applications to awarded"
  on public.applications for update to authenticated
  using (status = 'approved' and public.is_admin())
  with check (status = 'awarded' and public.is_admin());

create or replace function public.guard_application_workflow() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user = pg_catalog.pg_get_userbyid((select proowner from pg_catalog.pg_proc
    where oid = 'public.review_application(uuid,text,text,jsonb,text)'::regprocedure)) then return new; end if;
  if TG_OP = 'INSERT' then
    if new.endorsed_by is not null or new.endorsed_at is not null or new.decided_by is not null or new.decided_at is not null then
      raise exception 'Workflow fields are server-managed' using errcode = '42501';
    end if;
  else
    if (new.id, new.user_id, new.scholarship_id, new.endorsed_by, new.endorsed_at, new.decided_by, new.decided_at)
      is distinct from (old.id, old.user_id, old.scholarship_id, old.endorsed_by, old.endorsed_at, old.decided_by, old.decided_at) then
      raise exception 'Ownership and workflow fields are immutable' using errcode = '42501';
    end if;
    if new.status is distinct from old.status and not (
      (old.user_id = auth.uid() and ((old.status = 'draft' and new.status = 'submitted')
        or (old.status in ('draft','submitted','under_review') and new.status = 'withdrawn')))
      or (public.is_admin() and old.status = 'approved' and new.status = 'awarded')
    ) then raise exception 'Use the authorized workflow action' using errcode = '42501'; end if;
  end if;
  return new;
end;
$$;
notify pgrst, 'reload schema';
commit;
