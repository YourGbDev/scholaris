-- =============================================================================
-- Migration 0018: secure_storage_application_documents
-- Hardens the application_documents Supabase Storage bucket:
-- 1. Sets storage bucket to private (public: false)
-- 2. Scopes storage.objects policies strictly to application ownership:
--    Files stored at '$application_id/$filename' can only be uploaded, read,
--    or deleted if the application belongs to auth.uid() (or authorized provider/admin).
-- =============================================================================

-- 1. Ensure storage bucket is private (disallow unauthenticated CDN access)
UPDATE storage.buckets
SET public = false
WHERE id = 'application_documents';

-- In case bucket does not exist yet:
INSERT INTO storage.buckets (id, name, public)
VALUES ('application_documents', 'application_documents', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- 2. Drop legacy permissive bucket-level policies
DROP POLICY IF EXISTS "authenticated_upload_application_documents" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_read_application_documents" ON storage.objects;
DROP POLICY IF EXISTS "storage_student_upload_own_application_documents" ON storage.objects;
DROP POLICY IF EXISTS "storage_student_read_own_application_documents" ON storage.objects;
DROP POLICY IF EXISTS "storage_student_delete_own_application_documents" ON storage.objects;

-- 3. Storage INSERT Policy:
-- Student can only upload files into the folder corresponding to their own application
CREATE POLICY "storage_student_upload_own_application_documents"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'application_documents'
    AND EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = ((storage.foldername(name))[1])::uuid
        AND a.user_id = auth.uid()
    )
  );

-- 4. Storage SELECT Policy:
-- Student can read files from their own application.
-- Reviewing providers & admins can read files for submitted applications.
CREATE POLICY "storage_student_read_own_application_documents"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'application_documents'
    AND (
      -- Student reading their own uploaded application documents
      EXISTS (
        SELECT 1 FROM public.applications a
        WHERE a.id = ((storage.foldername(name))[1])::uuid
          AND a.user_id = auth.uid()
      )
      OR
      -- Platform Administrator audit access
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
      )
      OR
      -- Provider reviewing applications to their grant
      EXISTS (
        SELECT 1 FROM public.applications a
        JOIN public.scholarships s ON s.id = a.scholarship_id
        WHERE a.id = ((storage.foldername(name))[1])::uuid
          AND (
            s.created_by = auth.uid()
            OR s.provider = (SELECT organization_name FROM public.profiles WHERE id = auth.uid())
          )
      )
    )
  );

-- 5. Storage DELETE Policy:
-- Student can only delete documents from their own draft/submitted application
CREATE POLICY "storage_student_delete_own_application_documents"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'application_documents'
    AND EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = ((storage.foldername(name))[1])::uuid
        AND a.user_id = auth.uid()
        AND a.status IN ('draft', 'submitted')
    )
  );
