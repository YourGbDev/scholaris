-- =============================================================================
-- Scholaris — 0013: Provider Verifications & Secure Documents Storage
--
-- 1. Ensure provider columns on public.profiles (provider_type, organization, phone)
-- 2. Dedicated public.provider_verifications table for Individual & Organization onboarding
-- 3. Strict Row-Level Security (RLS) on provider_verifications (anti-self-approval)
-- 4. Private storage bucket (provider_documents) with safe error-tolerant blocks
-- =============================================================================

-- Ensure updated_at trigger function exists
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  new.updated_at = now();
  RETURN new;
END;
$$;

-- Ensure is_admin helper exists
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;

-- 1. Profiles additions
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS provider_type TEXT
CHECK (provider_type IN ('individual', 'organization'))
DEFAULT NULL;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS organization TEXT;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS phone TEXT;

-- 2. provider_verifications table
CREATE TABLE IF NOT EXISTS public.provider_verifications (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider_type           TEXT NOT NULL CHECK (provider_type IN ('individual', 'organization')),
  status                  TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  submitted_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_by             UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at             TIMESTAMPTZ,
  review_note             TEXT,

  -- Individual Provider Fields
  full_name               TEXT,
  email                   TEXT,
  phone                   TEXT,
  gov_id_type             TEXT,
  gov_id_number           TEXT,
  gov_id_front_path       TEXT,
  selfie_id_path          TEXT,
  source_of_funds         TEXT,
  monthly_giving_budget   TEXT,
  tin                     TEXT,
  data_consent            BOOLEAN NOT NULL DEFAULT false,

  -- Organization Provider Fields
  org_name                TEXT,
  org_type                TEXT,
  reg_number              TEXT,
  rep_name                TEXT,
  rep_position            TEXT,
  rep_email               TEXT,
  rep_phone               TEXT,
  sec_cert_path           TEXT,
  bir_2303_path           TEXT,
  board_resolution_path   TEXT,

  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Unique constraint so a user only has one active verification record
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'provider_verifications_user_id_key'
  ) THEN
    ALTER TABLE public.provider_verifications ADD CONSTRAINT provider_verifications_user_id_key UNIQUE (user_id);
  END IF;
END $$;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_provider_verifications_user_id
  ON public.provider_verifications(user_id);

CREATE INDEX IF NOT EXISTS idx_provider_verifications_status
  ON public.provider_verifications(status);

CREATE INDEX IF NOT EXISTS idx_provider_verifications_submitted_at
  ON public.provider_verifications(submitted_at DESC);

-- Update trigger
DROP TRIGGER IF EXISTS provider_verifications_set_updated_at ON public.provider_verifications;
CREATE TRIGGER provider_verifications_set_updated_at
  BEFORE UPDATE ON public.provider_verifications
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 3. Row Level Security on provider_verifications
ALTER TABLE public.provider_verifications ENABLE ROW LEVEL SECURITY;

-- Owner can read their own verification
DROP POLICY IF EXISTS "Users can read own provider verification" ON public.provider_verifications;
CREATE POLICY "Users can read own provider verification"
  ON public.provider_verifications FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Owner can insert their own verification
DROP POLICY IF EXISTS "Users can insert own provider verification" ON public.provider_verifications;
CREATE POLICY "Users can insert own provider verification"
  ON public.provider_verifications FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Owner can update their own verification if still pending.
-- CRITICAL SECURITY: WITH CHECK requires status = 'pending' to prevent providers from self-approving!
DROP POLICY IF EXISTS "Users can update own pending verification" ON public.provider_verifications;
CREATE POLICY "Users can update own pending verification"
  ON public.provider_verifications FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id AND status = 'pending')
  WITH CHECK (auth.uid() = user_id AND status = 'pending');

-- Admins can view all provider verifications
DROP POLICY IF EXISTS "Admins can view all provider verifications" ON public.provider_verifications;
CREATE POLICY "Admins can view all provider verifications"
  ON public.provider_verifications FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- Admins can update verification status, notes, reviewed_by
DROP POLICY IF EXISTS "Admins can update provider verifications" ON public.provider_verifications;
CREATE POLICY "Admins can update provider verifications"
  ON public.provider_verifications FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- 4. Private Storage Bucket: provider_documents (Safe wrapper)
DO $$
BEGIN
  INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  VALUES (
    'provider_documents',
    'provider_documents',
    false,
    5242880, -- 5 MB
    ARRAY['image/jpeg', 'image/png', 'application/pdf']
  )
  ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'application/pdf'];
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Bucket insert notice: %', SQLERRM;
END $$;

-- Storage RLS policies (Safe wrappers so table DDL is never rolled back)
DO $$
BEGIN
  DROP POLICY IF EXISTS "Providers can upload own verification documents" ON storage.objects;
  CREATE POLICY "Providers can upload own verification documents"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
      bucket_id = 'provider_documents' AND
      auth.uid()::text = (storage.foldername(name))[1]
    );
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Storage insert policy notice: %', SQLERRM;
END $$;

DO $$
BEGIN
  DROP POLICY IF EXISTS "Providers can read own verification documents" ON storage.objects;
  CREATE POLICY "Providers can read own verification documents"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
      bucket_id = 'provider_documents' AND
      auth.uid()::text = (storage.foldername(name))[1]
    );
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Storage select policy notice: %', SQLERRM;
END $$;

DO $$
BEGIN
  DROP POLICY IF EXISTS "Admins can read all provider verification documents" ON storage.objects;
  CREATE POLICY "Admins can read all provider verification documents"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
      bucket_id = 'provider_documents' AND
      public.is_admin()
    );
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Storage admin policy notice: %', SQLERRM;
END $$;

-- Force PostgREST schema cache reload
NOTIFY pgrst, 'reload schema';
