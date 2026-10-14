# Task Card: QA (`cerith` / `ai/qa`)

**Sprint:** 3rd Increment Checking (End-to-End Transaction Cycle)  
**Role:** 🔍 Testing, Edge Cases & Compliance Specialist  
**Reference Plan:** `docs/plans/2026-10-15_3rd_increment_transaction_cycle_plan.md`  
**Status:** `READY FOR IMPLEMENTATION`

---

## 1. Objective
1. Produce the official **3rd Increment Live Demo Script & Verification Guide** (`docs/reports/3RD_INCREMENT_LIVE_DEMO_SCRIPT.md`) with concrete step-by-step instructions, demo credentials, click targets, and Supabase query validations.
2. Independently verify the end-to-end Student -> Provider -> Student transaction path, confirming zero unhandled exceptions, zero browser alerts, and verified database persistence.

---

## 2. Deliverables & Specifications

### A. Live Demo Script (`docs/reports/3RD_INCREMENT_LIVE_DEMO_SCRIPT.md`)
Draft a bulletproof demo script structured into three chronological acts:

#### Act 1: Student Application Submission
- **Initial Setup**: Demo student account credentials (or sign-up email/password). Ensure student profile has GWA, Course, and photo/avatar configured so `IdentityPhotoRequiredDialog` does not block.
- **Action**:
  1. Navigate to Discover (`/discover`).
  2. Select targeted scholarship (e.g., LGU / Provincial Partner Grant).
  3. Inspect eligibility breakdown and match score.
  4. Tap "Start Application".
  5. Complete 3-step Review dialog (certifications checked, digital signature).
  6. Tap "Submit Application".
- **Verification**:
  - Show in-app success SnackBar.
  - Verify row in Supabase: `SELECT id, status, applied_at FROM public.applications WHERE status = 'submitted'`.

#### Act 2: Provider Deliberation & Rubric Scoring
- **Initial Setup**: Provider account login (`/provider-login` or `/provider-home`).
- **Action**:
  1. Open Provider Console -> Incoming Applications tab.
  2. Locate the student's submitted application.
  3. Tap "Review Application" -> Opens Reviewer Drawer.
  4. Demonstrate 4 Rubric Sliders:
     - Academic Excellence (40%)
     - Financial Need (30%)
     - Leadership & Community (20%)
     - Innovation Essay (10%)
     - Composite Score calculation.
  5. Type Deliberation Remarks.
  6. Tap "Approve Award" and confirm dialog.
- **Verification**:
  - Show in-app success confirmation banner.
  - Verify rows in Supabase:
    - `public.applications`: `status = 'approved'`.
    - `public.application_evaluations`: composite & criteria scores saved.
    - `public.application_status_history`: transition from `submitted` to `approved` logged.
    - `public.notifications`: row created for student `user_id`.

#### Act 3: Student Confirmation & Award Ceremony
- **Action**:
  1. Switch to Student session.
  2. Open Notification Center -> Observe active notification: `"Application Approved!"`.
  3. Tap notification -> Opens Application Detail Screen.
  4. Observe Status badge changed to `"Approved"`.
  5. Tap `"🎉 View Award Ceremony & Package"`.
  6. Experience full graduation ceremony celebration with award confirmation.
- **Verification**:
  - Confirm zero browser `window.alert` dialogs encountered.
  - Confirm full transaction state reflected in live UI.

### B. Automated Verification Suite
- Write or update `test/features/applications/transaction_cycle_test.dart` (or `test/transaction_cycle_smoke_test.dart`):
  - Exercise application submission, rubric score saving, status history transition, and notification generation.
  - Verify terminal output with exit code 0.

---

## 3. Allowed Files to Modify / Create
- `docs/reports/3RD_INCREMENT_LIVE_DEMO_SCRIPT.md` (new)
- `test/features/applications/transaction_cycle_test.dart` (or similar smoke test)

---

## 4. Verification & Testing
Execute:
```bash
flutter test test/features/applications/
flutter analyze
```
Confirm all tests pass and static analysis passes with zero warnings.
