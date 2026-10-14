# Orca Agent Handoff: Builder (cowrie / ai/builder)

**Sprint:** 3rd Increment Checking (End-to-End Transaction Cycle)  
**Assigned Task Card:** docs/tasks/task_builder.md (and TASK.md)  
**Master Plan:** docs/plans/2026-10-15_3rd_increment_transaction_cycle_plan.md  

### Instructions:
1. Review TASK.md for full implementation details.
2. Implement migration supabase/migrations/0023_transaction_cycle_persistence.sql (pplication_evaluations, pplication_status_history, 
otifications).
3. Update ApplicationRepository with saveEvaluation, providerUpdateNotes, ecordStatusTransition, and createNotification.
4. Connect ApplicantReviewDrawer decision handler to persist rubric scores & create notification.
5. Verify lutter analyze and lutter test.
6. Write completion report to docs/reports/3rd_increment_builder_report.md.
