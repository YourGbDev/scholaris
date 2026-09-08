-- =============================================================================
-- Scholaris — 0007: providers_select_applicant_profiles (policy, documentation only)
--
-- DOCUMENTATION-ONLY CAPTURE. This policy is ALREADY LIVE in the production
-- Supabase schema. Do NOT re-run this file — it is a record of the RLS the
-- client already depends on.
--
-- Allows a provider to SELECT only the `profiles` rows of applicants who applied
-- to a scholarship the provider owns. This backs the client-side applicant-name
-- resolution in the incoming-applications list (ProfileRepository.fetchProfileById
-- for each applicant id). The existence check ties the readable profile to a real
-- application on a provider-owned scholarship, so a provider can never browse an
-- arbitrary user's profile.
-- =============================================================================

create policy "Providers can select profiles of applicants to their own scholarships"
  on public.profiles for select
  to authenticated
  using (
    exists (
      select 1
      from public.applications a
      join public.scholarships s on s.id = a.scholarship_id
      where a.user_id = profiles.id
        and s.created_by = auth.uid()
    )
  );
