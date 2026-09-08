-- =============================================================================
-- Scholaris — 0004: scholarships.created_by (schema, documentation only)
--
-- DOCUMENTATION-ONLY CAPTURE. This column is ALREADY LIVE in the production
-- Supabase schema. Do NOT re-run this file — it is a record of the schema the
-- client already depends on.
--
-- Adds ownership to the `scholarships` table so a provider can be matched to the
-- scholarships they created. The signed-in provider's id is stored on each
-- scholarship they own; the provider console reads applications for scholarships
-- whose `created_by` equals the current user id.
--
-- The `incoming_applications` feature reads this column through the
-- `providers_select_own_applications` RLS policy (see 0005). A missing
-- `created_by` is treated as "no owner" (the application will not surface in any
-- provider's incoming queue), which is the safe default for scholarships seeded
-- before ownership existed.
-- =============================================================================

alter table public.scholarships
  add column if not exists created_by uuid
    references auth.users (id) on delete set null;
