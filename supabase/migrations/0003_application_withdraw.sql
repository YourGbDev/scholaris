-- =============================================================================
-- Scholaris — 0003: Application withdrawal lifecycle
--
-- Adds the terminal `withdrawn` status to the applications.status CHECK
-- constraint so a student can withdraw an in-flight application (draft /
-- submitted / under review). Withdrawn is terminal and is never "pending".
--
-- The constraint was declared inline on the `status` column in 0001_init.sql,
-- so PostgreSQL auto-named it `applications_status_check`. It is dropped and
-- recreated with the full six-status set; nothing else about the table changes.
-- =============================================================================

alter table public.applications
  drop constraint if exists applications_status_check,
  add constraint applications_status_check
    check (status in ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'withdrawn'));
