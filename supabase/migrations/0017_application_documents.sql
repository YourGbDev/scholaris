-- =============================================================================
-- Migration 0017: application_documents
-- Stores student-uploaded documents tied to scholarship applications (transcripts,
-- certificates of indigency, grade sheets, recommendation letters, etc.)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.application_documents (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  uuid        NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  document_type   text        NOT NULL CHECK (document_type IN (
                                'transcript',
                                'certificate_of_indigency',
                                'certificate_of_grades',
                                'recommendation_letter',
                                'enrollment_certificate',
                                'id_document',
                                'other'
                              )),
  file_name       text        NOT NULL,
  file_path       text        NOT NULL,
  storage_url     text,
  file_size_bytes bigint,
  mime_type       text,
  uploaded_at     timestamptz NOT NULL DEFAULT now()
);

-- Indexes for performant filtering by application and chronological lookup
CREATE INDEX IF NOT EXISTS idx_application_documents_app_id
  ON public.application_documents(application_id);

CREATE INDEX IF NOT EXISTS idx_application_documents_uploaded_at
  ON public.application_documents(uploaded_at DESC);

-- Enable Row Level Security
ALTER TABLE public.application_documents ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- RLS Policies
-- -----------------------------------------------------------------------------

-- 1. Students can SELECT documents belonging to their own applications
CREATE POLICY "students_read_own_application_documents"
  ON public.application_documents
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = application_documents.application_id
        AND a.user_id = auth.uid()
    )
  );

-- 2. Students can INSERT documents only into their own applications
CREATE POLICY "students_insert_own_application_documents"
  ON public.application_documents
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = application_documents.application_id
        AND a.user_id = auth.uid()
    )
  );

-- 3. Students can DELETE documents from their own draft/in-progress applications
CREATE POLICY "students_delete_own_application_documents"
  ON public.application_documents
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = application_documents.application_id
        AND a.user_id = auth.uid()
        AND a.status IN ('draft', 'submitted')
    )
  );

-- 4. Providers & Admins can SELECT documents for applications they review
CREATE POLICY "providers_and_admins_read_application_documents"
  ON public.application_documents
  FOR SELECT
  TO authenticated
  USING (
    -- Admin access: platform administrators can audit all documents
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
    OR
    -- Provider access: scholarship owners and organization reviewers
    EXISTS (
      SELECT 1 FROM public.applications a
      JOIN public.scholarships s ON s.id = a.scholarship_id
      WHERE a.id = application_documents.application_id
        AND (
          s.created_by = auth.uid()
          OR s.provider = (SELECT organization_name FROM public.profiles WHERE id = auth.uid())
        )
    )
  );

-- -----------------------------------------------------------------------------
-- Storage Bucket & Storage Access Policies
-- -----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('application_documents', 'application_documents', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- 1. Student can only upload files into the folder corresponding to their own application
CREATE POLICY "storage_student_upload_own_application_documents"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'application_documents'
    AND (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    AND EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = ((storage.foldername(name))[1])::uuid
        AND a.user_id = auth.uid()
    )
  );

-- 2. Student can read files from their own application
CREATE POLICY "storage_student_read_own_application_documents"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'application_documents'
    AND (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    AND EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = ((storage.foldername(name))[1])::uuid
        AND a.user_id = auth.uid()
    )
  );

-- 3. Student can delete documents from their own draft/submitted application
CREATE POLICY "storage_student_delete_own_application_documents"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'application_documents'
    AND (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    AND EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = ((storage.foldername(name))[1])::uuid
        AND a.user_id = auth.uid()
        AND a.status IN ('draft', 'submitted')
    )
  );

-- 4. Providers & Platform Admins can read documents for applications they review
CREATE POLICY "storage_provider_admin_read_application_documents"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'application_documents'
    AND (
      -- Platform Administrator audit access
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
      )
      OR
      -- Provider reviewing applications to their grant
      (
        (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        AND EXISTS (
          SELECT 1 FROM public.applications a
          JOIN public.scholarships s ON s.id = a.scholarship_id
          WHERE a.id = ((storage.foldername(name))[1])::uuid
            AND (
              s.created_by = auth.uid()
              OR s.provider = (SELECT organization_name FROM public.profiles WHERE id = auth.uid())
            )
        )
      )
    )
  );
