# 3rd Increment Checking: End-to-End Transaction Cycle Master Plan

**Reference:** `docs/plans/2026-10-15_3rd_increment_transaction_cycle_plan.md`  
**Date:** October 14–15, 2026  
**Architect:** 🧠 `ai/architect` (`whelk`)  
**Target Deadline:** 3rd Increment Checking (October 15–16, 2026)  
**Status:** `STATUS: READY FOR SPECIALIST EXECUTION`

---

## 1. Executive Summary & Grading Objectives

To achieve 100% on the **3rd Increment Checking in Application Development**, Scholaris must execute and prove a **live, multi-role transaction cycle** across three actors/steps backed entirely by real Supabase tables:

1. **Actor 1 (Student):**
   - Authenticate & Complete Profile (GWA, Academic Level, Household Income, Avatar).
   - Discover Scholarship & evaluate matching breakdown.
   - Complete 3-step Application Review Dialog & Submit -> Persisted in `public.applications` (`status: submitted`).
2. **Actor 2 (Provider / Committee Reviewer):**
   - Access Provider Console (`/provider-home` -> Incoming Applications).
   - Open Institutional Reviewer Decisioning Drawer.
   - Adjust 4 Rubric Sliders (Academic 40%, Need 30%, Leadership 20%, Vision 10%) & enter Deliberation Notes.
   - Click "Approve Award" -> Persisted in Supabase:
     - `applications` table: status updated to `approved`.
     - `application_evaluations` table: rubric scores & notes saved.
     - `application_status_history` table: transition logged.
     - `notifications` table: recipient student notification created.
3. **Actor 1 (Student Confirmation):**
   - Student receives in-app notification in Notification Center.
   - Taps notification -> Opens Application Detail Screen.
   - Application status displays "Approved" with green badge and celebratory UI.
   - Student taps "🎉 Celebrate Award & View Package" -> Opens full Ceremony Screen celebration with award confirmation.
4. **Strict System UI Constraint:**
   - Zero browser alerts (`window.alert` / "localhost says").
   - Zero raw unhandled exceptions. All actions provide branded feedback via `ScholarisSnackBar`, Toasts, and confirmation Dialogs.

---

## 2. Gap Analysis & Architecture Fixes

| Step | Current State | Defect / Blocker | Remediation Required | Responsible Agent |
| :--- | :--- | :--- | :--- | :--- |
| **Rubric Scoring** | Sliders exist in `ApplicantReviewDrawer` | **Not persisted to database**; transient widget state only. | Create `application_evaluations` table; persist scores & remarks in `ApplicationRepository`. | 🔨 **Builder** & 🛡️ **Security** |
| **Deliberation Notes** | `_notesController` text | `updateNotes` executes with `eq('user_id', providerId)` which matches 0 rows. Silently swallowed in `catch (_) {}`. | Add `providerUpdateNotes(applicationId, notes)` or include in evaluation save. | 🔨 **Builder** |
| **Transaction History** | Status updated in-place | No status transition audit trail. Violates "status history tables" criterion. | Create `application_status_history` table and log transitions. | 🔨 **Builder** & 🛡️ **Security** |
| **Notifications** | Client-side derivation in sheet | No persisted `notifications` table in Supabase. | Create `notifications` table and persist notification on approval. | 🔨 **Builder** & 🛡️ **Security** |
| **Ceremony Navigation** | `/ceremony` route | `router.dart` redirects authenticated users to `/home`. Ceremony always routes to `/login`. | Update `CeremonyScreen` to support celebration mode; add celebration trigger on application detail screen. | 🎨 **UI/UX** |
| **UI Feedback & Error Handling** | Mixed generic SnackBars | Need standardized, branded feedback on all transactions without raw errors. | Audit all action buttons; polish SnackBars, loading spinners, and dialogs. | 🎨 **UI/UX** |
| **Demo Script & Verification** | None | No structured script for the instructor demo. | Create step-by-step verification checklist and test suite. | 🔍 **QA** |

---

## 3. Worktree Assignments

- 🔨 **`cowrie` (`ai/builder`)**:
  - Implement Supabase migration `0023_transaction_cycle_persistence.sql` (`application_evaluations`, `application_status_history`, `notifications`).
  - Update `ApplicationRepository` with `saveRubricEvaluation`, `providerUpdateNotes`, and `recordStatusTransition`.
  - Wire `ApplicantReviewDrawer` decision handler to persist evaluation and notify student.
- 🎨 **`bowhead` (`ai/ui`)**:
  - Upgrade `CeremonyScreen` to support student award celebration with custom message and dismiss/return callback.
  - Add "🎉 View Award Ceremony & Package" action card in `ApplicationDetailScreen` when status is approved.
  - Standardize in-app feedback (zero browser alerts, haptic feedback, custom error/success SnackBars).
- 🛡️ **`fusilier` (`ai/security`)**:
  - Audit RLS policies for `0020-0022` and write RLS policies for the new migration `0023`.
  - Guarantee that student cannot be blocked from submitting and provider cannot be blocked from scoring/approving.
  - Verify RA 10173 compliance.
- 🔍 **`cerith` (`ai/qa`)**:
  - Produce `docs/reports/3RD_INCREMENT_LIVE_DEMO_SCRIPT.md` with explicit student & provider credentials, click paths, and expected database states.
  - Run regression test suite and verify complete cycle.
