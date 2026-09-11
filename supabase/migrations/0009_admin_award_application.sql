-- =============================================================================
-- Scholaris — 0009: Admin-confirmed scholarship award lifecycle
--
-- Adds the terminal `awarded` status to the applications.status CHECK
-- constraint so administrators can officially confer scholarships following
-- provider approval (approved -> awarded).
--
-- Access Control (Row-Level Security):
-- 1. applications_status_check: adds 'awarded' to the allowed status values.
-- 2. Permissive UPDATE policy: allows an admin to update an application from
--    current status 'approved' to new status 'awarded'.
-- 3. Restrictive UPDATE policy: strictly blocks any non-admin (students and
--    providers) from setting status to 'awarded', guaranteeing that existing
--    student (0001) and provider (0006) update policies cannot be used to
--    bypass the admin award guard.
-- 4. Permissive SELECT policy: allows administrators to view all applications
--    in the system for tracking, audit, and award confirmation.
-- =============================================================================

-- 0. Ensure profiles table has role column
alter table public.profiles add column if not exists role text default 'student';

-- 1. Helper security definer function to avoid RLS recursion with profiles (0007)
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

grant execute on function public.is_admin() to authenticated;

-- 2. Status CHECK constraint
alter table public.applications
  drop constraint if exists applications_status_check,
  add constraint applications_status_check
    check (status in ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'withdrawn', 'awarded'));

-- 3. Permissive UPDATE policy for admins
create policy "Admins can update approved applications to awarded"
  on public.applications for update
  to authenticated
  using (
    status = 'approved'
    and public.is_admin()
  )
  with check (
    status = 'awarded'
    and public.is_admin()
  );

-- 4. Restrictive UPDATE policy: no non-admin may set status to awarded or modify an awarded application
create policy "Only admins can set or modify awarded status"
  on public.applications
  as restrictive
  for update
  to authenticated
  using (
    status <> 'awarded'
    or public.is_admin()
  )
  with check (
    status <> 'awarded'
    or public.is_admin()
  );

-- 5. Permissive SELECT policy for admins
create policy "Admins can select all applications"
  on public.applications for select
  to authenticated
  using (
    public.is_admin()
  );
