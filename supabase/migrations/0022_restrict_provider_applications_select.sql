-- DRAFT, NOT APPLIED, apply only after review together with 0020/0021 and after confirming the provider UI never needs draft rows. Do not touch the 0006 update policy.

drop policy if exists "Providers can select applications to their own scholarships" on public.applications;

create policy "Providers can select applications to their own scholarships"
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
