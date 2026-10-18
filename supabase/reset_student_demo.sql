-- =============================================================================
-- SCHOLARIS: QUICK RESET FOR STUDENT DEMO ACCOUNT
-- =============================================================================
-- Run this anytime in Supabase Dashboard -> SQL Editor to reset the demo student!

SET session_replication_role = 'replica';

-- 1. Delete notifications for demo student
DELETE FROM public.notifications
WHERE user_id = 'd0570001-0000-0000-0000-000000000001';

-- 2. Delete disbursements for demo student's applications
DELETE FROM public.disbursements
WHERE application_id IN (
  SELECT id FROM public.applications
  WHERE user_id = 'd0570001-0000-0000-0000-000000000001'
);

-- 3. Delete evaluations for demo student's applications
DELETE FROM public.application_evaluations
WHERE application_id IN (
  SELECT id FROM public.applications
  WHERE user_id = 'd0570001-0000-0000-0000-000000000001'
);

-- 4. Delete status history for demo student's applications
DELETE FROM public.application_status_history
WHERE application_id IN (
  SELECT id FROM public.applications
  WHERE user_id = 'd0570001-0000-0000-0000-000000000001'
);

-- 5. Delete application records for demo student
DELETE FROM public.applications
WHERE user_id = 'd0570001-0000-0000-0000-000000000001';

SET session_replication_role = 'origin';

SELECT '✅ Demo student (Juan Dela Cruz) application has been completely cleared! Ready for fresh demo application.' AS status;
