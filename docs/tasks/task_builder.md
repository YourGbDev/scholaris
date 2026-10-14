# Task Card: Builder (`cowrie` / `ai/builder`)

**Sprint:** 3rd Increment Checking (End-to-End Transaction Cycle)  
**Role:** 🔨 Backend, Supabase Persistence & Logic Specialist  
**Reference Plan:** `docs/plans/2026-10-15_3rd_increment_transaction_cycle_plan.md`  
**Status:** `READY FOR IMPLEMENTATION`

---

## 1. Objective
Implement database persistence for all steps of the Student -> Provider -> Student transaction cycle so the instructor can verify database tables and data retrieval in Supabase.

---

## 2. Deliverables & Specifications

### A. Database Migration: `supabase/migrations/0023_transaction_cycle_persistence.sql`
Create the following tables with proper constraints and indexes:
1. **`public.application_evaluations`**:
   - `id uuid primary key default gen_random_uuid()`
   - `application_id uuid not null references public.applications(id) on delete cascade`
   - `reviewer_id uuid not null references auth.users(id) on delete cascade`
   - `score_academic numeric(4,2) not null`
   - `score_financial numeric(4,2) not null`
   - `score_leadership numeric(4,2) not null`
   - `score_vision numeric(4,2) not null`
   - `composite_score numeric(4,2) not null`
   - `deliberation_notes text`
   - `decision text not null` (e.g. `'approved'`, `'rejected'`, `'under_review'`)
   - `created_at timestamptz not null default now()`
2. **`public.application_status_history`**:
   - `id uuid primary key default gen_random_uuid()`
   - `application_id uuid not null references public.applications(id) on delete cascade`
   - `changed_by uuid not null references auth.users(id) on delete cascade`
   - `from_status text not null`
   - `to_status text not null`
   - `remarks text`
   - `created_at timestamptz not null default now()`
3. **`public.notifications`**:
   - `id uuid primary key default gen_random_uuid()`
   - `user_id uuid not null references auth.users(id) on delete cascade`
   - `title text not null`
   - `message text not null`
   - `type text not null default 'application_update'`
   - `target_id text` (application id)
   - `is_read boolean not null default false`
   - `created_at timestamptz not null default now()`

### B. Application Repository & Data Source
In `lib/features/applications/repositories/application_repository.dart`:
1. **Fix `updateNotes` bug for Provider**:
   - Provider calling `updateNotes` previously scoped by `user_id = providerId`, which matched 0 rows.
   - Implement `providerUpdateNotes(String applicationId, String notes)` that updates `applications.notes` where `id = applicationId` (protected by RLS policy 0006).
2. **Implement Rubric Evaluation Persistence**:
   - `Future<void> saveEvaluation({required String applicationId, required double scoreAcademic, required double scoreFinancial, required double scoreLeadership, required double scoreVision, required double compositeScore, String? notes, required String decision})`.
   - Inserts into `application_evaluations`.
   - Also gracefully encodes rubric summary into `applications.notes` as JSON fallback (`{"academic": scoreAcademic, ..., "remarks": notes}`).
3. **Implement Status History Logging**:
   - `Future<void> recordStatusTransition({required String applicationId, required String fromStatus, required String toStatus, String? remarks})`.
   - Inserts into `application_status_history`.
4. **Implement In-App Notification Creation**:
   - `Future<void> createNotification({required String userId, required String title, required String message, String? targetId})`.
   - Inserts into `public.notifications`.

### C. Provider Review Drawer Integration
In `lib/features/provider/presentation/widgets/applicant_review_drawer.dart`:
- In `_handleDecision(ApplicationStatus targetStatus)`:
  1. Call `providerUpdateStatus(widget.application.id, targetStatus)`.
  2. Call `saveEvaluation(...)` with the 4 rubric slider values (`_score1`, `_score2`, `_score3`, `_score4`, `_compositeScore`) and deliberation notes.
  3. Call `recordStatusTransition(...)` logging the transition.
  4. Call `createNotification(...)` for `widget.application.userId` notifying them that their application was approved/reviewed.
  5. Ensure try/catch blocks log detailed messages and do not silently swallow persistence errors.

---

## 3. Allowed Files to Modify
- `supabase/migrations/0023_transaction_cycle_persistence.sql` (new)
- `lib/features/applications/repositories/application_repository.dart`
- `lib/features/applications/providers/applications_provider.dart`
- `lib/features/provider/presentation/widgets/applicant_review_drawer.dart`

---

## 4. Verification & Testing
Run:
```bash
flutter analyze lib/features/applications lib/features/provider
flutter test test/features/applications/
```
Ensure all tests pass and static analysis is 100% clean.
