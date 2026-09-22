-- =============================================================================
-- Scholaris — 0012: Add provider_type to profiles
--
-- Adds provider_type column to profiles table:
-- - Allowed values: 'individual', 'organization'
-- - Defaults to NULL
-- - Only populated when role = 'provider'. NULL for students and admins.
-- - No RLS changes, no backfill needed.
-- =============================================================================

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS provider_type TEXT
CHECK (provider_type IN ('individual', 'organization'))
DEFAULT NULL;

COMMENT ON COLUMN profiles.provider_type IS
'Only populated when role = provider. NULL for students and admins.';
