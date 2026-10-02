-- =============================================================================
-- Migration 0020: Restrict Provider Applicant Profile Access & Scoping
--
--
-- SAFE TO APPLY: This migration only creates the view and function. It is safe
-- to apply BEFORE the Dart update ships. The legacy policy is dropped in 0021.
--
-- Context:
-- In migration 0007_providers_select_applicant_profiles.sql, the policy:
--   "Providers can select profiles of applicants to their own scholarships"
-- was added directly to public.profiles.
--
-- Critical Privacy & Security Issues in 0007:
-- 1. Full Row Exposure: Because RLS operates at the row level, a provider client
--    can execute SELECT * on public.profiles, exposing sensitive personal data:
--    - birth_date (revealing exact age and minor status)
--    - has_disability (health / PWD status)
--    - is_indigenous (ethnic / cultural minority status)
--    - phone (personal contact number)
--    - gender, nationality, and email
-- 2. Draft Leakage: The join in 0007 did NOT check `a.status <> 'draft'`.
--    Consequently, if a student merely created a draft application, a provider
--    could immediately view their profile.
--
-- Remediation Architecture (Part 1):
-- 1. Create a dedicated, column-minimized Security Barrier View:
--    `public.provider_applicant_profiles`
--    and an RPC helper `public.get_applicant_profile(uuid)`.
--    - Exposes ONLY non-sensitive academic & demographic attributes used by provider UI.
--    - Enforces that the application has left 'draft' status (a.status <> 'draft').
--    - Excludes has_disability, is_indigenous, birth_date, phone, email, and gender.
--    - FLAGGED: monthly_family_income is included strictly because provider
--      intake reviews display household income tiers for means-tested grants.
-- (The over-permissive RLS policy from public.profiles is dropped in 0021.)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Column-Minimized Security Barrier View for Providers
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.provider_applicant_profiles
WITH (security_barrier = true) AS
SELECT
  p.id,
  p.full_name,
  p.school,
  p.course,
  p.year_level,
  p.gpa,
  p.region,
  p.province,
  p.city_municipality,
  p.setup_complete,

  -- ---------------------------------------------------------------------------
  -- SENSITIVE FIELD AUDIT & JUSTIFICATION:
  -- The following field is classified as sensitive financial information under
  -- RA 10173. It is included in this view because provider evaluation screens:
  --   1. lib/features/provider/presentation/provider_application_detail_screen.dart:656
  --   2. lib/features/provider/presentation/widgets/applicant_review_drawer.dart:380,808
  --   3. lib/features/provider/presentation/org/org_incoming_applications_tab.dart:1267
  --   4. lib/features/provider/presentation/org/org_analytics_tab.dart:161
  -- genuinely require household income to evaluate eligibility for need-based grants
  -- (e.g. CHED Tulong Dunong, 4Ps thresholds).
  --
  -- The following sensitive fields are STRICTLY EXCLUDED:
  -- - p.birth_date       (EXCLUDED: not used in provider screens; protects minors)
  -- - p.has_disability   (EXCLUDED: not used in provider review screens)
  -- - p.is_indigenous    (EXCLUDED: not used in provider review screens)
  -- - p.phone            (EXCLUDED: student contact phone hidden from grantors)
  -- - p.email            (EXCLUDED: direct student email hidden; uses in-app status)
  -- - p.gender           (EXCLUDED: not needed for academic review)
  -- ---------------------------------------------------------------------------
  p.monthly_family_income

FROM public.profiles p
WHERE
  -- Platform administrators have global audit access
  public.is_admin()
  -- Providers can only read profiles of students who submitted to their grants
  OR EXISTS (
    SELECT 1
    FROM public.applications a
    JOIN public.scholarships s ON s.id = a.scholarship_id
    WHERE a.user_id = p.id
      AND s.created_by = auth.uid()
      AND a.status <> 'draft'
  );

COMMENT ON VIEW public.provider_applicant_profiles IS
'Sanitized, column-minimized view of applicant profiles for scholarship providers. Strictly excludes disability, indigenous affiliation, birth date, phone, and unsubmitted draft applications.';

GRANT SELECT ON public.provider_applicant_profiles TO authenticated;
REVOKE ALL ON public.provider_applicant_profiles FROM PUBLIC, anon;

-- -----------------------------------------------------------------------------
-- 3. Security Definer RPC Helper: get_applicant_profile
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_applicant_profile(p_user_id uuid)
RETURNS TABLE (
  id uuid,
  full_name text,
  school text,
  course text,
  year_level int,
  gpa numeric,
  region text,
  province text,
  city_municipality text,
  setup_complete boolean,
  monthly_family_income numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  -- Strict guard: caller must be administrator OR the provider who owns a scholarship
  -- to which the user has a submitted (non-draft) application.
  IF NOT (
    public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.applications a
      JOIN public.scholarships s ON s.id = a.scholarship_id
      WHERE a.user_id = p_user_id
        AND s.created_by = auth.uid()
        AND a.status <> 'draft'
    )
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.full_name,
    p.school,
    p.course,
    p.year_level,
    p.gpa,
    p.region,
    p.province,
    p.city_municipality,
    p.setup_complete,
    p.monthly_family_income
  FROM public.profiles p
  WHERE p.id = p_user_id;
END;
$$;

COMMENT ON FUNCTION public.get_applicant_profile(uuid) IS
'RPC endpoint returning a sanitized applicant profile for a specific student ID if caller is authorized.';

GRANT EXECUTE ON FUNCTION public.get_applicant_profile(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_applicant_profile(uuid) FROM PUBLIC, anon;
