-- =============================================================================
-- SCHOLARIS: 3RD INCREMENT CHECKING ALL-IN-ONE SETUP & RESET SCRIPT
-- =============================================================================
--
-- File: supabase/demo_3rd_increment_setup_and_reset.sql
-- Purpose:
--   1. Idempotently creates 0023 database tables (application_evaluations,
--      application_status_history, notifications) and Row-Level Security (RLS) policies.
--   2. Ensures verified demo accounts exist (student, provider) with credentials:
--        • Student:  student.demo@scholaris.edu.ph  /  Scholaris2026!
--        • Provider: provider.dost@scholaris.gov.ph /  Scholaris2026!
--   3. Seeds the DOST-SEI Undergraduate Scholarship owned by the provider.
--   4. Cleans/resets any previous application test runs for the demo student so
--      you can rehearse tonight and reset in 1 click right before your demo!
--
-- HOW TO RUN:
--   Paste this entire script into the Supabase Dashboard -> SQL Editor and click "Run".
-- =============================================================================

-- =============================================================================
-- PART 1: MIGRATION 0023 TABLES & RLS POLICIES
-- =============================================================================

-- 1.1 Helper function for admin check (if not already defined)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;

-- 1.2 Table: application_evaluations (Rubric criteria & deliberation remarks)
CREATE TABLE IF NOT EXISTS public.application_evaluations (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id      uuid NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  reviewer_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  score_academic      numeric(4, 2) NOT NULL,
  score_financial     numeric(4, 2) NOT NULL,
  score_leadership    numeric(4, 2) NOT NULL,
  score_vision        numeric(4, 2) NOT NULL,
  composite_score     numeric(4, 2) NOT NULL,
  deliberation_notes  text,
  decision            text NOT NULL CHECK (decision IN ('approved', 'rejected', 'under_review')),
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_application_evaluations_app_id
  ON public.application_evaluations(application_id);
CREATE INDEX IF NOT EXISTS idx_application_evaluations_reviewer_id
  ON public.application_evaluations(reviewer_id);

ALTER TABLE public.application_evaluations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "evaluations_insert_by_provider" ON public.application_evaluations;
CREATE POLICY "evaluations_insert_by_provider"
  ON public.application_evaluations FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = reviewer_id
    AND (
      public.is_admin()
      OR EXISTS (
        SELECT 1 FROM public.applications a
        JOIN public.scholarships s ON s.id = a.scholarship_id
        WHERE a.id = application_evaluations.application_id
          AND s.created_by = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "evaluations_select_by_provider_or_admin" ON public.application_evaluations;
CREATE POLICY "evaluations_select_by_provider_or_admin"
  ON public.application_evaluations FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.applications a
      JOIN public.scholarships s ON s.id = a.scholarship_id
      WHERE a.id = application_evaluations.application_id
        AND s.created_by = auth.uid()
    )
  );

DROP POLICY IF EXISTS "evaluations_select_by_student_owner" ON public.application_evaluations;
CREATE POLICY "evaluations_select_by_student_owner"
  ON public.application_evaluations FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = application_evaluations.application_id
        AND a.user_id = auth.uid()
    )
  );

GRANT SELECT, INSERT ON public.application_evaluations TO authenticated;

-- 1.3 Table: application_status_history (Audit timeline)
CREATE TABLE IF NOT EXISTS public.application_status_history (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  uuid NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  changed_by      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  from_status     text NOT NULL,
  to_status       text NOT NULL,
  remarks         text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_application_status_history_app_id
  ON public.application_status_history(application_id);

ALTER TABLE public.application_status_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "status_history_insert_authorized_actors" ON public.application_status_history;
CREATE POLICY "status_history_insert_authorized_actors"
  ON public.application_status_history FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = changed_by
    AND (
      public.is_admin()
      OR EXISTS (
        SELECT 1 FROM public.applications a
        WHERE a.id = application_status_history.application_id
          AND a.user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.applications a
        JOIN public.scholarships s ON s.id = a.scholarship_id
        WHERE a.id = application_status_history.application_id
          AND s.created_by = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "status_history_select_authorized_actors" ON public.application_status_history;
CREATE POLICY "status_history_select_authorized_actors"
  ON public.application_status_history FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = application_status_history.application_id
        AND a.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.applications a
      JOIN public.scholarships s ON s.id = a.scholarship_id
      WHERE a.id = application_status_history.application_id
        AND s.created_by = auth.uid()
    )
  );

GRANT SELECT, INSERT ON public.application_status_history TO authenticated;

-- 1.4 Table: notifications (Persistent student alerts)
CREATE TABLE IF NOT EXISTS public.notifications (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title       text NOT NULL,
  message     text NOT NULL,
  type        text NOT NULL DEFAULT 'application_update',
  target_id   text,
  is_read     boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id
  ON public.notifications(user_id);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_insert_authenticated" ON public.notifications;
CREATE POLICY "notifications_insert_authenticated"
  ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "notifications_select_by_owner" ON public.notifications;
CREATE POLICY "notifications_select_by_owner"
  ON public.notifications FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "notifications_update_by_owner" ON public.notifications;
CREATE POLICY "notifications_update_by_owner"
  ON public.notifications FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE ON public.notifications TO authenticated;


-- =============================================================================
-- PART 2: DEMO ACCOUNTS SEED (Auth + Profiles)
-- =============================================================================

-- Fixed UUIDs for predictable demo binding
-- Admin UUID:    d0570000-0000-0000-0000-000000000000
-- Student UUID:  d0570001-0000-0000-0000-000000000001
-- Provider UUID: d0570002-0000-0000-0000-000000000002
-- Scholarship:   d0570003-0000-0000-0000-000000000003

DO $$
BEGIN
  -- 2.0 Seed Admin in auth.users
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'admin@scholaris.edu.ph') THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, recovery_sent_at, last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      'd0570000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated', 'admin@scholaris.edu.ph',
      crypt('Scholaris2026!', gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Scholaris System Administrator"}',
      now(), now(), '', '', '', ''
    );
  ELSE
    UPDATE auth.users
    SET encrypted_password = crypt('Scholaris2026!', gen_salt('bf')),
        email_confirmed_at = now()
    WHERE email = 'admin@scholaris.edu.ph';
  END IF;

  -- 2.1 Seed Student in auth.users
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'student.demo@scholaris.edu.ph') THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, recovery_sent_at, last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      'd0570001-0000-0000-0000-000000000001',
      'authenticated', 'authenticated', 'student.demo@scholaris.edu.ph',
      crypt('Scholaris2026!', gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Juan Dela Cruz"}',
      now(), now(), '', '', '', ''
    );
  ELSE
    UPDATE auth.users
    SET encrypted_password = crypt('Scholaris2026!', gen_salt('bf')),
        email_confirmed_at = now()
    WHERE email = 'student.demo@scholaris.edu.ph';
  END IF;

  -- 2.2 Seed Provider in auth.users
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'provider.dost@scholaris.gov.ph') THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, recovery_sent_at, last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      'd0570002-0000-0000-0000-000000000002',
      'authenticated', 'authenticated', 'provider.dost@scholaris.gov.ph',
      crypt('Scholaris2026!', gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Dr. Renato U. Solidum Jr."}',
      now(), now(), '', '', '', ''
    );
  ELSE
    UPDATE auth.users
    SET encrypted_password = crypt('Scholaris2026!', gen_salt('bf')),
        email_confirmed_at = now()
    WHERE email = 'provider.dost@scholaris.gov.ph';
  END IF;
END $$;

-- 2.0 Seed or Update Admin Profile in public.profiles
INSERT INTO public.profiles (
  id, full_name, role, setup_complete
) VALUES (
  'd0570000-0000-0000-0000-000000000000',
  'Scholaris Administrator',
  'admin',
  true
)
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  role = 'admin',
  setup_complete = true;

-- 2.3 Seed or Update Student Profile in public.profiles
INSERT INTO public.profiles (
  id, full_name, birth_date, gender, nationality,
  region, province, city_municipality,
  gpa, year_level, course, school,
  monthly_family_income, has_disability, is_indigenous,
  setup_complete, role
) VALUES (
  'd0570001-0000-0000-0000-000000000001',
  'Juan Dela Cruz',
  '2004-06-15',
  'Male',
  'Filipino',
  'NCR',
  'Metro Manila',
  'Quezon City',
  1.24,
  3,
  'BS Computer Science',
  'University of the Philippines Diliman',
  15000,
  false,
  false,
  true,
  'student'
)
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  school = EXCLUDED.school,
  course = EXCLUDED.course,
  year_level = EXCLUDED.year_level,
  gpa = EXCLUDED.gpa,
  monthly_family_income = EXCLUDED.monthly_family_income,
  setup_complete = true,
  role = 'student';

-- 2.4 Seed or Update Provider Profile in public.profiles
INSERT INTO public.profiles (
  id, full_name, role, school, setup_complete
) VALUES (
  'd0570002-0000-0000-0000-000000000002',
  'Dr. Renato U. Solidum Jr.',
  'provider',
  'DOST-SEI',
  true
)
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  role = 'provider',
  school = 'DOST-SEI',
  setup_complete = true;

-- 2.5 Ensure Provider Verification Record exists
INSERT INTO public.provider_verifications (
  user_id,
  organization_name,
  provider_type,
  status,
  submitted_at,
  reviewed_at
) VALUES (
  'd0570002-0000-0000-0000-000000000002',
  'Department of Science and Technology - SEI',
  'institutional',
  'approved',
  now(),
  now()
)
ON CONFLICT (user_id) DO UPDATE SET
  status = 'approved',
  provider_type = 'institutional';


-- =============================================================================
-- PART 3: SEED DOST-SEI SCHOLARSHIP (OWNED BY DEMO PROVIDER)
-- =============================================================================

INSERT INTO public.scholarships (
  id,
  title,
  provider,
  description,
  min_gpa,
  max_monthly_income,
  required_year_levels,
  required_courses,
  slots,
  deadline,
  is_active,
  created_by
) VALUES (
  'd0570003-0000-0000-0000-000000000003',
  'DOST-SEI Undergraduate Scholarship (RA 7687)',
  'DOST-SEI',
  'Provides financial assistance to talented and deserving Filipino youth pursuing priority fields of study in science, mathematics, and engineering.',
  1.75,
  50000,
  ARRAY[1, 2, 3, 4],
  ARRAY['BS Computer Science', 'BS Information Technology', 'BS Applied Physics'],
  50,
  (CURRENT_DATE + INTERVAL '45 days')::date,
  true,
  'd0570002-0000-0000-0000-000000000002'
)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  created_by = 'd0570002-0000-0000-0000-000000000002',
  deadline = (CURRENT_DATE + INTERVAL '45 days')::date,
  is_active = true;


-- =============================================================================
-- PART 4: CLEAN & RESET PREVIOUS APPLICATION RUNS
-- =============================================================================
-- This guarantees the demo student starts with a clean slate for the live demo!

-- 4.1 Delete previous notifications for the demo student
DELETE FROM public.notifications
WHERE user_id = 'd0570001-0000-0000-0000-000000000001';

-- 4.2 Delete prior disbursements for applications belonging to the demo student
DELETE FROM public.disbursements
WHERE application_id IN (
  SELECT id FROM public.applications
  WHERE user_id = 'd0570001-0000-0000-0000-000000000001'
);

-- 4.3 Delete evaluations for applications belonging to the demo student
DELETE FROM public.application_evaluations
WHERE application_id IN (
  SELECT id FROM public.applications
  WHERE user_id = 'd0570001-0000-0000-0000-000000000001'
);

-- 4.4 Delete status history for applications belonging to the demo student
DELETE FROM public.application_status_history
WHERE application_id IN (
  SELECT id FROM public.applications
  WHERE user_id = 'd0570001-0000-0000-0000-000000000001'
);

-- 4.5 Delete prior application records for the demo student
DELETE FROM public.applications
WHERE user_id = 'd0570001-0000-0000-0000-000000000001';

-- Output verification message
SELECT '✅ Scholaris 3rd Increment checking environment initialized and reset successfully!' AS status;
