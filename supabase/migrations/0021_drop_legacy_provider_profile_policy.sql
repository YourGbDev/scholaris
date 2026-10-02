-- =============================================================================
-- Migration 0021: Drop Legacy Provider Profile Policy
--
-- APPLY ONLY AFTER the Dart release that uses provider_applicant_profiles
-- is live for all provider users.
-- =============================================================================

DROP POLICY IF EXISTS "Providers can select profiles of applicants to their own scholarships" ON public.profiles;
