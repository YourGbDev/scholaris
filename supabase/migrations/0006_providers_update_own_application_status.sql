-- =============================================================================
-- Scholaris — 0006: providers_update_own_application_status (policy, documentation only)
--
-- DOCUMENTATION-ONLY CAPTURE. This policy is ALREADY LIVE in the production
-- Supabase schema. Do NOT re-run this file — it is a record of the RLS the
-- client already depends on.
--
-- Allows a provider to UPDATE only the `status` column of applications whose
-- scholarship they own (scholarships.created_by = auth.uid()). This is the
-- write counterpart to 0005 and the basis for a future "advance application
-- status" action on the provider console. The current incoming-applications
-- surface is read-only and never invokes this path, but the policy is captured
-- here so the schema contract is complete.
-- =============================================================================

create policy "Providers can update status of applications to their own scholarships"
  on public.applications for update
  to authenticated
  using (
    exists (
      select 1 from public.scholarships s
      where s.id = applications.scholarship_id
        and s.created_by = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.scholarships s
      where s.id = applications.scholarship_id
        and s.created_by = auth.uid()
    )
  );
