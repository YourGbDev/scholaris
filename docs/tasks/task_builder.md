# Task Card: Builder (`cowrie` / `ai/builder`)

**Sprint:** 3rd Increment Pre-Presentation Audit  
**Role:** 🔨 Backend, Supabase Persistence & Logic Specialist  
**Reference Plan:** `docs/plans/2026-10-19_increment3_pre_presentation_audit_plan.md`  
**Status:** `READY FOR AUDIT`

---

## 1. Objective
Conduct an exhaustive audit of the backend repository layer, data transport, status transition logic, and database schemas supporting the 3-role transaction cycle (`draft` -> `submitted` -> `under_review` -> `endorsed` -> `approved` / `awarded`). Verify that all transaction data is strictly persisted in PostgreSQL without synthetic mock fallbacks or uncaught repository exceptions.

---

## 2. Permitted Files
- `lib/features/applications/data/repositories/application_repository.dart`
- `lib/features/applications/providers/applications_provider.dart`
- `lib/features/applications/models/application.dart`
- `lib/features/provider/providers/provider_sub_role_provider.dart`
- `supabase/migrations/0023_transaction_cycle_persistence.sql`
- `supabase/migrations/0024_organization_review_cycle.sql`
- `supabase/migrations/0025_preserve_existing_award_transition.sql`
- `test/application_workflow_transport_test.dart`
- `test/features/provider/provider_sub_role_test.dart`
- `docs/reports/2026-10-19_increment3_builder_report.md` (report deliverable)

---

## 3. Specific Audit Checklist

### A. Repository & State Machine Integrity
1. **Status Transition Validity**:
   - Inspect `application_repository.dart` and `applications_provider.dart`.
   - Confirm atomic status transitions:
     - `submitApplication`: transitions from `draft` to `submitted`.
     - `startReview`: transitions from `submitted` to `under_review`.
     - `endorseApplication`: inserts into `application_reviews` and transitions status to `endorsed`.
     - `approveApplication`: provider admin grants final award, transitioning status to `approved`.
2. **Zero Synthetic / Mock Fallback**:
   - Verify that all production repository methods connect directly to `_client` (Supabase Client).
   - Ensure no hardcoded mock objects or static fallback application records exist in production code paths.
3. **Database Schema & Table Alignment**:
   - Review migrations `0023`, `0024`, and `0025`.
   - Confirm table definitions for:
     - `public.application_reviews` (stores `academic_score`, `financial_score`, `leadership_score`, `recommendation`, `evaluator_notes`).
     - `public.organization_memberships` (stores `organization_id`, `user_id`, `role`, `active`).
     - `public.notifications` (stores `user_id`, `title`, `message`, `type`, `target_id`).
     - `public.audit_logs` (stores `actor_id`, `action`, `resource_type`, `resource_id`, `metadata`).

### B. Automated Verification
1. Run targeted builder test suites:
   ```bash
   flutter test test/application_workflow_transport_test.dart
   flutter test test/features/provider/provider_sub_role_test.dart
   ```
2. Run analyzer on application repository and provider code:
   ```bash
   flutter analyze lib/features/applications/data/repositories/application_repository.dart lib/features/provider/providers/provider_sub_role_provider.dart
   ```

---

## 4. Deliverable Report
Commit completion report to:
`docs/reports/2026-10-19_increment3_builder_report.md`

Must use standard sections:
- `### Implemented / Audited`
- `### Verified` (with command and output)
- `### Not verified`
- `### Remaining risks`
