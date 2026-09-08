-- =============================================================================
-- Scholaris — 0005: providers_select_own_applications (policy, documentation only)
--
-- DOCUMENTATION-ONLY CAPTURE. This policy is ALREADY LIVE in the production
-- Supabase schema. Do NOT re-run this file — it is a record of the RLS the
-- client already depends on.
--
-- Allows a provider to SELECT only applications whose `scholarship_id` points at
-- a scholarship they created (scholarships.created_by = auth.uid()). This is the
-- server-side scope that backs ApplicationRepository.fetchIncomingApplications()
-- and protects provider-scoped reads as defense in depth — the repository also
-- restricts the scholarship id list to the current provider client-side.
-- =============================================================================

create policy "Providers can select applications to their own scholarships"
  on public.applications for select
  to authenticated
  using (
    exists (
      select 1 from public.scholarships s
      where s.id = applications.scholarship_id
        and s.created_by = auth.uid()
    )
  );
