-- Migration 0019: tighten application_documents access
-- * Providers may read only documents for scholarships they created,
--   and only after the application has left draft (draft and withdrawn applications are excluded).
-- * Organization-name matching removed (profiles.organization is
--   user-editable and role='provider' is granted on submission).
-- * Storage policies guard the uuid cast so other buckets cannot error.

-- Providers read documents for scholarships they created (draft and withdrawn applications excluded); admins read all.
DROP POLICY IF EXISTS "providers_and_admins_read_application_documents" ON public.application_documents;
CREATE POLICY "providers_and_admins_read_application_documents"
  ON public.application_documents
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.applications a
      JOIN public.scholarships s ON s.id = a.scholarship_id
      WHERE a.id = application_documents.application_id
        AND s.created_by = auth.uid()
        AND a.status NOT IN ('draft', 'withdrawn')
    )
  );

DROP POLICY IF EXISTS "storage_student_upload_own_application_documents" ON storage.objects;
DROP POLICY IF EXISTS "storage_student_read_own_application_documents" ON storage.objects;
DROP POLICY IF EXISTS "storage_student_delete_own_application_documents" ON storage.objects;
DROP POLICY IF EXISTS "storage_provider_admin_read_application_documents" ON storage.objects;

CREATE POLICY "storage_student_upload_own_application_documents"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'application_documents'
    AND CASE
      WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      THEN EXISTS (
        SELECT 1 FROM public.applications a
        WHERE a.id = CASE
          WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          THEN ((storage.foldername(name))[1])::uuid ELSE NULL END
          AND a.user_id = auth.uid()
      )
      ELSE false
    END
  );

CREATE POLICY "storage_student_read_own_application_documents"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'application_documents'
    AND CASE
      WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      THEN EXISTS (
        SELECT 1 FROM public.applications a
        WHERE a.id = CASE
          WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          THEN ((storage.foldername(name))[1])::uuid ELSE NULL END
          AND a.user_id = auth.uid()
      )
      ELSE false
    END
  );

CREATE POLICY "storage_student_delete_own_application_documents"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'application_documents'
    AND CASE
      WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      THEN EXISTS (
        SELECT 1 FROM public.applications a
        WHERE a.id = CASE
          WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          THEN ((storage.foldername(name))[1])::uuid ELSE NULL END
          AND a.user_id = auth.uid()
          AND a.status IN ('draft', 'submitted')
      )
      ELSE false
    END
  );

-- Providers read storage documents for scholarships they created (draft and withdrawn applications excluded); admins read all.
CREATE POLICY "storage_provider_admin_read_application_documents"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'application_documents'
    AND (
      public.is_admin()
      OR CASE
        WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        THEN EXISTS (
          SELECT 1 FROM public.applications a
          JOIN public.scholarships s ON s.id = a.scholarship_id
          WHERE a.id = CASE
            WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            THEN ((storage.foldername(name))[1])::uuid ELSE NULL END
            AND s.created_by = auth.uid()
            AND a.status NOT IN ('draft', 'withdrawn')
        )
        ELSE false
      END
    )
  );