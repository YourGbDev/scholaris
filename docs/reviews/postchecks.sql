-- =============================================================================
-- Scholaris — Post-Migration Fail-Stop Checks (postchecks.sql)
--
-- Authoritative post-migration security, privilege, and integrity verification.
-- Must be executed post-deployment to assert zero regressions, strict RLS,
-- correct security definer functions, storage trigger binding, and privilege boundaries.
--
-- Migration stages covered:
--   Stage 0027: can_review_scholarship, review_application, provider_verifications RLS
--   Stage 0029: individual_support_budgets, individual_support_payments RLS & grants
--   Stage 0030: support_concerns RLS & revoked write grants
--   Stage 0031: support_payment_review_requests / support_concerns RLS & RPC
--   Stage 0032: safety_reports bucket configuration, storage.objects trigger, evidence grants
--   Stage 0033: is_admin_active(), provider_verifications grants, dropped admin update policy,
--               and anti-self-approval trigger
-- =============================================================================

-- =============================================================================
-- STAGE 0027: Individual Provider Lifecycle & Benefactor Decisioning
-- =============================================================================

-- 0027-A: can_review_scholarship exists with SECURITY DEFINER and returns boolean
DO $$
DECLARE
  v_proc record;
BEGIN
  SELECT p.proname, pn.nspname, p.prosecdef, pg_get_function_result(p.oid) as ret_type
  INTO v_proc
  FROM pg_proc p
  JOIN pg_namespace pn ON pn.oid = p.pronamespace
  WHERE pn.nspname = 'public' AND p.proname = 'can_review_scholarship';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAIL-STOP 0027: Function public.can_review_scholarship does not exist';
  END IF;

  IF v_proc.prosecdef IS NOT TRUE THEN
    RAISE EXCEPTION 'FAIL-STOP 0027: Function public.can_review_scholarship must be SECURITY DEFINER';
  END IF;

  IF v_proc.ret_type <> 'boolean' THEN
    RAISE EXCEPTION 'FAIL-STOP 0027: Function public.can_review_scholarship must return boolean (returns %)', v_proc.ret_type;
  END IF;
END $$;

-- 0027-B: review_application exists with SECURITY DEFINER
DO $$
DECLARE
  v_proc record;
BEGIN
  SELECT p.proname, pn.nspname, p.prosecdef
  INTO v_proc
  FROM pg_proc p
  JOIN pg_namespace pn ON pn.oid = p.pronamespace
  WHERE pn.nspname = 'public' AND p.proname = 'review_application';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAIL-STOP 0027: Function public.review_application does not exist';
  END IF;

  IF v_proc.prosecdef IS NOT TRUE THEN
    RAISE EXCEPTION 'FAIL-STOP 0027: Function public.review_application must be SECURITY DEFINER';
  END IF;
END $$;

-- 0027-C: provider_verifications has Row Level Security enabled
DO $$
DECLARE
  v_rls boolean;
BEGIN
  SELECT c.relrowsecurity INTO v_rls
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relname = 'provider_verifications';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAIL-STOP 0027: Table public.provider_verifications does not exist';
  END IF;

  IF v_rls IS NOT TRUE THEN
    RAISE EXCEPTION 'FAIL-STOP 0027: Row-Level Security (RLS) must be enabled on public.provider_verifications';
  END IF;
END $$;

-- =============================================================================
-- STAGE 0029: Individual Support Ledger
-- =============================================================================

-- 0029-A: individual_support_budgets and individual_support_payments RLS enabled
DO $$
DECLARE
  v_budgets_rls boolean;
  v_payments_rls boolean;
BEGIN
  SELECT c.relrowsecurity INTO v_budgets_rls
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relname = 'individual_support_budgets';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAIL-STOP 0029: Table public.individual_support_budgets does not exist';
  END IF;

  IF v_budgets_rls IS NOT TRUE THEN
    RAISE EXCEPTION 'FAIL-STOP 0029: RLS must be enabled on public.individual_support_budgets';
  END IF;

  SELECT c.relrowsecurity INTO v_payments_rls
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relname = 'individual_support_payments';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAIL-STOP 0029: Table public.individual_support_payments does not exist';
  END IF;

  IF v_payments_rls IS NOT TRUE THEN
    RAISE EXCEPTION 'FAIL-STOP 0029: RLS must be enabled on public.individual_support_payments';
  END IF;
END $$;

-- 0029-B: Direct write privileges revoked from public, anon, authenticated; SELECT granted to authenticated
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_privileges
    WHERE table_schema = 'public'
      AND table_name IN ('individual_support_budgets', 'individual_support_payments')
      AND grantee IN ('public', 'anon', 'authenticated')
      AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE')
  ) THEN
    RAISE EXCEPTION 'FAIL-STOP 0029: Direct write privileges (INSERT, UPDATE, DELETE) on individual support tables must be revoked from public, anon, and authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_privileges
    WHERE table_schema = 'public'
      AND table_name = 'individual_support_budgets'
      AND grantee = 'authenticated'
      AND privilege_type = 'SELECT'
  ) OR NOT EXISTS (
    SELECT 1 FROM information_schema.table_privileges
    WHERE table_schema = 'public'
      AND table_name = 'individual_support_payments'
      AND grantee = 'authenticated'
      AND privilege_type = 'SELECT'
  ) THEN
    RAISE EXCEPTION 'FAIL-STOP 0029: Authenticated users must retain SELECT grant on individual support tables';
  END IF;
END $$;

-- =============================================================================
-- STAGE 0030: Individual Support Recovery & Student Support Concerns
-- =============================================================================

-- 0030-A: support_concerns RLS enabled
DO $$
DECLARE
  v_concerns_rls boolean;
BEGIN
  SELECT c.relrowsecurity INTO v_concerns_rls
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relname = 'support_concerns';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAIL-STOP 0030: Table public.support_concerns does not exist';
  END IF;

  IF v_concerns_rls IS NOT TRUE THEN
    RAISE EXCEPTION 'FAIL-STOP 0030: RLS must be enabled on public.support_concerns';
  END IF;
END $$;

-- 0030-B: Direct write privileges revoked on public.support_concerns
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_privileges
    WHERE table_schema = 'public'
      AND table_name = 'support_concerns'
      AND grantee IN ('public', 'anon', 'authenticated')
      AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE')
  ) THEN
    RAISE EXCEPTION 'FAIL-STOP 0030: Direct write privileges (INSERT, UPDATE, DELETE) on public.support_concerns must be revoked from public, anon, and authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_privileges
    WHERE table_schema = 'public'
      AND table_name = 'support_concerns'
      AND grantee = 'authenticated'
      AND privilege_type = 'SELECT'
  ) THEN
    RAISE EXCEPTION 'FAIL-STOP 0030: Authenticated users must retain SELECT grant on public.support_concerns';
  END IF;
END $$;

-- =============================================================================
-- STAGE 0031: Provider Payment Review Requests
-- =============================================================================

-- 0031-A: support_payment_review_requests / support_concerns RLS enabled & RPC verified
DO $$
DECLARE
  v_rls boolean;
  v_proc record;
BEGIN
  -- Verify RLS on dedicated table if present, or on public.support_concerns which backs payment review requests
  IF to_regclass('public.support_payment_review_requests') IS NOT NULL THEN
    SELECT c.relrowsecurity INTO v_rls
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'support_payment_review_requests';

    IF v_rls IS NOT TRUE THEN
      RAISE EXCEPTION 'FAIL-STOP 0031: RLS must be enabled on public.support_payment_review_requests';
    END IF;
  ELSE
    SELECT c.relrowsecurity INTO v_rls
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'support_concerns';

    IF v_rls IS NOT TRUE THEN
      RAISE EXCEPTION 'FAIL-STOP 0031: RLS must be enabled on public.support_concerns (backing provider payment review requests)';
    END IF;
  END IF;

  -- Verify RPC public.request_support_payment_review exists and is SECURITY DEFINER
  SELECT p.proname, pn.nspname, p.prosecdef, pg_get_function_result(p.oid) as ret_type
  INTO v_proc
  FROM pg_proc p
  JOIN pg_namespace pn ON pn.oid = p.pronamespace
  WHERE pn.nspname = 'public' AND p.proname = 'request_support_payment_review';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAIL-STOP 0031: Function public.request_support_payment_review does not exist';
  END IF;

  IF v_proc.prosecdef IS NOT TRUE THEN
    RAISE EXCEPTION 'FAIL-STOP 0031: Function public.request_support_payment_review must be SECURITY DEFINER';
  END IF;
END $$;

-- =============================================================================
-- STAGE 0032: Student Safety Reports & Secure Evidence Storage
-- =============================================================================

-- 0032-A: Strict Bucket Configuration Check for 'safety_reports'
DO $$
DECLARE
  v_bucket record;
  c_expected_mime text[] := ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']::text[];
BEGIN
  SELECT * INTO v_bucket FROM storage.buckets WHERE id = 'safety_reports';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Bucket safety_reports does not exist in storage.buckets';
  END IF;

  -- Strict private bucket assertion: public must be false (rejects public = true and public IS NULL)
  IF v_bucket.public IS NOT FALSE THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Bucket safety_reports must be private (public = false)';
  END IF;

  -- NULL-safe file size limit assertion: exactly 5,242,880 bytes (5MB)
  IF v_bucket.file_size_limit IS DISTINCT FROM 5242880 THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Bucket safety_reports file_size_limit must be exactly 5242880 bytes (found %)', v_bucket.file_size_limit;
  END IF;

  -- Exact MIME whitelist assertion: mutual subset array comparison + cardinality equality + no NULL elements
  IF v_bucket.allowed_mime_types IS NULL
     OR NOT (v_bucket.allowed_mime_types @> c_expected_mime AND v_bucket.allowed_mime_types <@ c_expected_mime)
     OR cardinality(v_bucket.allowed_mime_types) <> cardinality(c_expected_mime)
     OR array_position(v_bucket.allowed_mime_types, NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Bucket safety_reports allowed_mime_types mismatch. Expected exactly: %, Found: %',
      c_expected_mime, v_bucket.allowed_mime_types;
  END IF;
END $$;

-- 0032-B: Exact Trigger Check on storage.objects
DO $$
DECLARE
  v_tg record;
BEGIN
  SELECT t.tgname, t.tgenabled, t.tgtype, t.tgfoid, p.proname, pn.nspname, p.prosecdef
  INTO v_tg
  FROM pg_trigger t
  JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace cn ON cn.oid = c.relnamespace
  JOIN pg_proc p ON p.oid = t.tgfoid
  JOIN pg_namespace pn ON pn.oid = p.pronamespace
  WHERE cn.nspname = 'storage' AND c.relname = 'objects'
    AND t.tgname = 'trg_guard_safety_report_evidence_delete';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Trigger trg_guard_safety_report_evidence_delete is not installed on storage.objects';
  END IF;

  -- Verify binding to public schema procedure
  IF v_tg.tgfoid <> 'public.guard_safety_report_evidence_delete()'::regprocedure THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Trigger trg_guard_safety_report_evidence_delete must be bound to public.guard_safety_report_evidence_delete()';
  END IF;

  -- Verify trigger is enabled ('O' = origin and local)
  IF v_tg.tgenabled <> 'O' THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Trigger trg_guard_safety_report_evidence_delete is not enabled (status: %)', v_tg.tgenabled;
  END IF;

  -- Verify event type bitmask: BEFORE (bit 1, value 2), FOR EACH ROW (bit 0, value 1), DELETE (bit 3, value 8; or bit 4 value 16)
  IF (v_tg.tgtype & 2) = 0 THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Trigger trg_guard_safety_report_evidence_delete must be a BEFORE trigger (tgtype: %)', v_tg.tgtype;
  END IF;

  IF (v_tg.tgtype & 1) = 0 THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Trigger trg_guard_safety_report_evidence_delete must be a FOR EACH ROW trigger (tgtype: %)', v_tg.tgtype;
  END IF;

  IF ((v_tg.tgtype & 8) = 0 AND (v_tg.tgtype & 16) = 0) THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Trigger trg_guard_safety_report_evidence_delete must be a DELETE trigger (tgtype: %)', v_tg.tgtype;
  END IF;

  -- Verify function is SECURITY DEFINER
  IF v_tg.prosecdef IS NOT TRUE THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Trigger function public.guard_safety_report_evidence_delete must be SECURITY DEFINER';
  END IF;
END $$;

-- 0032-C: Direct Write Grants Revoked on student_safety_report_evidence
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_privileges
    WHERE table_schema = 'public' AND table_name = 'student_safety_report_evidence'
      AND grantee IN ('public', 'anon', 'authenticated')
      AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE')
  ) THEN
    RAISE EXCEPTION 'FAIL-STOP 0032: Direct write privileges (INSERT, UPDATE, DELETE) on student_safety_report_evidence are not revoked from public/anon/authenticated';
  END IF;
END $$;

-- =============================================================================
-- STAGE 0033: Atomic Provider Verification Review & Decisioning
-- =============================================================================

-- 0033-A: Verify is_admin_active() exists and returns boolean
DO $$
DECLARE
  v_proc record;
BEGIN
  SELECT p.proname, pn.nspname, p.prosecdef, pg_get_function_result(p.oid) as ret_type
  INTO v_proc
  FROM pg_proc p
  JOIN pg_namespace pn ON pn.oid = p.pronamespace
  WHERE pn.nspname = 'public' AND p.proname = 'is_admin_active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAIL-STOP 0033: Function public.is_admin_active does not exist';
  END IF;

  IF v_proc.ret_type <> 'boolean' THEN
    RAISE EXCEPTION 'FAIL-STOP 0033: Function public.is_admin_active must return boolean (returns %)', v_proc.ret_type;
  END IF;

  IF v_proc.prosecdef IS NOT TRUE THEN
    RAISE EXCEPTION 'FAIL-STOP 0033: Function public.is_admin_active must be SECURITY DEFINER';
  END IF;
END $$;

-- 0033-B: Effective Permissions Check on public.provider_verifications
-- Authenticated users must retain table INSERT and UPDATE grants for registration and resubmission
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_privileges
    WHERE table_schema = 'public' AND table_name = 'provider_verifications'
      AND grantee = 'authenticated'
      AND privilege_type = 'INSERT'
  ) THEN
    RAISE EXCEPTION 'FAIL-STOP 0033: Authenticated users must retain INSERT grant on provider_verifications for registration';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_privileges
    WHERE table_schema = 'public' AND table_name = 'provider_verifications'
      AND grantee = 'authenticated'
      AND privilege_type = 'UPDATE'
  ) THEN
    RAISE EXCEPTION 'FAIL-STOP 0033: Authenticated users must retain UPDATE grant on provider_verifications for resubmission';
  END IF;
END $$;

-- 0033-C: Direct Admin Table UPDATE Policy Dropped
-- Ensures administrative reviews must execute via atomic RPC review_provider_verification
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'provider_verifications'
      AND policyname = 'Admins can update provider verifications'
  ) THEN
    RAISE EXCEPTION 'FAIL-STOP 0033: Direct policy "Admins can update provider verifications" must be dropped to force atomic RPC review';
  END IF;
END $$;

-- 0033-D: Anti-Self-Approval Trigger Verification on public.provider_verifications
DO $$
DECLARE
  v_tg record;
BEGIN
  SELECT t.tgname, t.tgenabled, p.proname, pn.nspname, p.prosecdef
  INTO v_tg
  FROM pg_trigger t
  JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace cn ON cn.oid = c.relnamespace
  JOIN pg_proc p ON p.oid = t.tgfoid
  JOIN pg_namespace pn ON pn.oid = p.pronamespace
  WHERE cn.nspname = 'public' AND c.relname = 'provider_verifications'
    AND t.tgname IN ('trg_prevent_provider_self_approval', 'trg_provider_verification_review')
    AND NOT t.tgisinternal;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAIL-STOP 0033: Anti-self-approval trigger (trg_prevent_provider_self_approval or trg_provider_verification_review) does not exist on public.provider_verifications';
  END IF;

  IF v_tg.tgenabled <> 'O' THEN
    RAISE EXCEPTION 'FAIL-STOP 0033: Anti-self-approval trigger % is not enabled (status: %)', v_tg.tgname, v_tg.tgenabled;
  END IF;
END $$;
