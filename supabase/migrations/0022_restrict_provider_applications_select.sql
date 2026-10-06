-- DRAFT, NOT APPLIED. Run only after review. Do not touch the update policy.
-- Prod's live policy is named providers_select_own_applications (pg_policies, Oct 2026).
drop policy if exists "providers_select_own_applications" on public.applications;
drop policy if exists "Providers can select applications to their own scholarships" on public.applications;

create policy "providers_select_own_applications"
  on public.applications for select
  to authenticated
  using (
    status not in ('draft', 'withdrawn')
    and exists (
      select 1 from public.scholarships s
      where s.id = applications.scholarship_id
        and s.created_by = auth.uid()
    )
  );
