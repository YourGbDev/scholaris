# Increment 3 Pre-Presentation QA Audit Report

**Date:** October 19, 2026  
**Specialist:** 🔍 Quality Assurance & Bug Hunting Specialist (`cerith` / `ai/qa`)  
**Reference Plan:** `docs/plans/2026-10-19_increment3_pre_presentation_audit_plan.md`  
**Task Card:** `docs/tasks/task_qa.md`  
**Status:** `STATUS: AUDIT COMPLETE & VERIFIED`

---

## 1. Executive Summary

An independent, adversarial quality assurance audit was conducted on the Scholaris codebase and demonstration environment for the **3rd Increment / Checking in Application Development (End-to-End Transaction Cycle)**.

Key audit outcomes:
1. **Automated Test Verification**: All 6 required transaction/workflow test suites plus remediation regression test suites executed with **35 passed tests, 0 failures (100% pass rate)**.
2. **Static Analysis**: `flutter analyze` completed with **zero issues** across all core test suites and feature directories (`test/`, `lib/features/applications/`, `lib/features/provider/`, `lib/features/dashboard/`, `lib/features/auth/`, `lib/features/profile/`, `lib/features/scholarships/`).
3. **Transaction Flow & Negative Edge Cases**: Fully verified withdrawal guards (`ApplicationWithdrawalException`), authentication gates, role-separated review authority (Reviewer endorsement vs. Org Admin approval), and modal drawer lifecycle recovery.
4. **Zero Browser Alerts**: Confirmed 100% in-app UI feedback using `ScholarisSnackBar`, Apple HIG modal sheets, and the official `ApplicationDecisionLetter` view; zero `window.alert()` invocations.
5. **Live Database State Inspection**: Evaluated remote Supabase production project (`yqwbarzxpduzmtrxnrbm`) via read-only authenticated REST queries. Verified working demo accounts, identified 1 pre-demo leftover application requiring reset, identified empty `organization_memberships` requiring provider seeding, and confirmed active DOST scholarships.

---

## 2. Test Execution Summary

| Test Suite | File | Tests Run | Passed | Failed | Duration | Result |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Workflow Transport & RLS Boundaries** | `test/application_workflow_transport_test.dart` | 10 | 10 | 0 | 00:00 | **PASSED** |
| **Reviewer Drawer Lifecycle & Barrier** | `test/reviewer_drawer_lifecycle_test.dart` | 1 | 1 | 0 | 00:01 | **PASSED** |
| **Official Decision Letter Presentation** | `test/application_decision_letter_test.dart` | 6 | 6 | 0 | 00:00 | **PASSED** |
| **Award Package & Celebration UI** | `test/award_celebration_ui_test.dart` | 3 | 3 | 0 | 00:01 | **PASSED** |
| **Trusted Membership & Sub-Role RBAC** | `test/features/provider/provider_sub_role_test.dart` | 7 | 7 | 0 | 00:00 | **PASSED** |
| **Student Shell Instant Tab Switching** | `test/features/student/bottom_nav_tab_switch_test.dart` | 1 | 1 | 0 | 00:01 | **PASSED** |
| **Remediation UI & Responsive Rubric** | `test/remediation_ui_review_test.dart` | 7 | 7 | 0 | 00:03 | **PASSED** |
| **Total Automated Suites** | **7 test files** | **35** | **35** | **0** | **~7s** | **100% PASS** |

### Individual Test Breakdown by Suite:

1. **`test/application_workflow_transport_test.dart`** (10 tests):
   - ✅ `student update does not report success on a zero-row RLS response`
   - ✅ `provider status does not report success on a zero-row RLS response`
   - ✅ `provider notes does not report success on a zero-row RLS response`
   - ✅ `empty transaction response fails instead of displaying success`
   - ✅ `draft insert uses only columns that exist in the live applications schema`
   - ✅ `backend authorization/transaction failure propagates to the UI caller`
   - ✅ `one confirmed RPC row returns persisted endorsement and uses no client actor`
   - ✅ `mismatched result status is not success`
   - ✅ `document upload cannot report success when storage fails`
   - ✅ `document upload cannot report success when metadata fails`

2. **`test/reviewer_drawer_lifecycle_test.dart`** (1 test):
   - ✅ `closing drawer restores interaction; pending committed result survives disposal`

3. **`test/application_decision_letter_test.dart`** (6 tests):
   - ✅ `ApplicationStatus.approved displays only the corresponding saved decision`
   - ✅ `ApplicationStatus.awarded displays only the corresponding saved decision`
   - ✅ `ApplicationStatus.rejected displays only the corresponding saved decision`
   - ✅ `letter fits 360.0 with large text and missing optional fields`
   - ✅ `letter fits 440.0 with large text and missing optional fields`
   - ✅ `letter fits 1280.0 with large text and missing optional fields`

4. **`test/award_celebration_ui_test.dart`** (3 tests):
   - ✅ `CeremonyScreen Celebration Mode renders custom title, subtitle, and top-right close button`
   - ✅ `ApplicationDetailScreen decision letter approved application opens an approval letter and returns safely`
   - ✅ `ApplicationDetailScreen decision letter responsive layout on 360px mobile and 1280px desktop without overflow`

5. **`test/features/provider/provider_sub_role_test.dart`** (7 tests):
   - ✅ `UI authority comes only from trusted membership: reviewer`
   - ✅ `UI authority comes only from trusted membership: org_admin`
   - ✅ `UI authority comes only from trusted membership: finance`
   - ✅ `UI authority comes only from trusted membership: null`
   - ✅ `membership fetch failure does not grant review or decision authority`
   - ✅ `ProviderSubRole & Identity Tests Evaluator identity displays correct DOST academic desk info`
   - ✅ `ProviderSubRole & Identity Tests Finance Officer identity displays correct DOST treasury info`

6. **`test/features/student/bottom_nav_tab_switch_test.dart`** (1 test):
   - ✅ `Student Bottom Navigation Tab Switch (QA Suite) Tapping across all 4 tabs switches IndexedStack instantly without white flash`

7. **`test/remediation_ui_review_test.dart`** (7 tests):
   - ✅ `1. Ceremony Screen UI/UX Motion & Latency CeremonyScreen auto-advance timer cancels instantly on tap`
   - ✅ `2. Account Settings Notification Preferences & Ergonomics renders 5 notification switches with Apple HIG >= 44pt touch targets`
   - ✅ `3. Applications Tracker Pull-to-Refresh & Fluid Physics wraps list with brand kPrimary RefreshIndicator and Apple bouncing scroll`
   - ✅ `4. Provider Review Rubric Multi-Viewport Responsiveness 360x640 narrow mobile viewport: renders rubric with zero RenderFlex overflow`
   - ✅ `4. Provider Review Rubric Multi-Viewport Responsiveness 440x956 iPhone 16 Pro Max viewport: renders rubric and score sliders smoothly`
   - ✅ `4. Provider Review Rubric Multi-Viewport Responsiveness 768x1024 tablet portrait: renders drawer layout without collision`
   - ✅ `4. Provider Review Rubric Multi-Viewport Responsiveness 1200x800 desktop viewport: renders with spacious alignment`

### Static Analysis Verification:
- **Command**: `flutter analyze test/ lib/features/applications/ lib/features/provider/ lib/features/dashboard/ lib/features/auth/ lib/features/profile/ lib/features/scholarships/`
- **Output**: `Analyzing 7 items... No issues found! (ran in 55.1s)`
- **Exit Code**: `0`

---

## 3. Negative & Edge Case Analysis

### 3.1. Application Withdrawal Guard
- **Mechanism**: `ApplicationRepository.withdraw(applicationId)` checks current database status before issuing any mutation:
  ```dart
  final status = ApplicationStatus.fromDbValue(current['status'] as String);
  if (!status.isPending) {
    throw const ApplicationWithdrawalException();
  }
  ```
  `isPending` is strictly defined as `draft || submitted || underReview`.
- **Terminal States**: Applications in `approved`, `rejected`, `withdrawn`, or `awarded` cannot be withdrawn.
- **UI Error Presentation**: In `ApplicationDetailScreen._confirmWithdraw()`, catching `ApplicationWithdrawalException` displays a localized in-app `SnackBar(content: Text('This application can no longer be withdrawn.'))`. No unhandled exceptions or browser popups occur.

### 3.2. Authentication & Authorization Boundaries
- **Unauthenticated Submissions**: `ApplicationRepository._requireUserId()` throws `ApplicationNotAuthenticatedException` when `currentUserId()` is null. UI captures this exception in `ScholarshipDetailScreen` and presents a branded floating `SnackBar` (`"You must be signed in to apply."`) with `Icons.lock_outline_rounded`.
- **Role Isolation & Forgery Protection**:
  - Reviewer/Evaluator sub-role (`ProviderSubRole.evaluator`) only has authority to score the 4 rubric sliders and submit an **endorsement** (`review_application` RPC action `'endorse'`), which transitions the application from `submitted` to `under_review`.
  - Organization Admin (`ProviderSubRole.orgAdmin`) holds sole authority to execute final decisions (`'approve'` or `'reject'`).
  - Attempting to invoke unauthorized decision RPCs fails with PostgreSQL code `42501` (`PostgrestException: Only organization admins can decide`), verified in `application_workflow_transport_test.dart`.

### 3.3. Empty State Handling
- In `provider_incoming_applications.dart`:
  ```dart
  if (applications.isEmpty) {
    return const EmptyView(
      icon: Icons.inbox_outlined,
      title: 'No applications yet',
      message: 'Applications submitted to scholarships you own will appear here.',
    );
  }
  ```
- In `OrgIncomingApplicationsTab._buildEmptyState()`:
  - Renders a responsive squircle card with `Icons.inbox_outlined`, title `"No Applications in this View"`, and descriptive subtitle.
  - Zero `RenderFlex` overflow warnings across all viewports (360px mobile, 440px phone, 768px tablet, 1280px desktop).

### 3.4. Drawer Lifecycle & Interaction Recovery
- Verified in `reviewer_drawer_lifecycle_test.dart`: Dismissing `ApplicantReviewDrawer` while a server transaction is in-flight safely releases the underlying modal barrier, prevents leaks/exceptions on disposed contexts, and restores tap responsiveness immediately to parent buttons.

---

## 4. Live Demo Environment Status

Database state was inspected via read-only authenticated REST verification (`scratch/verify_post_cleanup_state.mjs`) against the production Supabase instance (`https://yqwbarzxpduzmtrxnrbm.supabase.co`):

### 4.1. Verified Account Credentials Matrix

| Role | Email | Password | Live Auth Status | Bound Profile ID |
| :--- | :--- | :--- | :---: | :--- |
| **Student** | `student.demo@scholaris.edu.ph` | `Scholaris2026!` | ✅ **SUCCESS** | `d0570001-0000-0000-0000-000000000001` |
| **Provider (DOST)** | `provider.dost@scholaris.gov.ph` | `Scholaris2026!` | ✅ **SUCCESS** | `d0570002-0000-0000-0000-000000000002` |
| **Finance Officer** | `finance.dost@scholaris.gov.ph` | `Scholaris2026!` | ✅ **SUCCESS** | `d0570004-0000-0000-0000-000000000004` |
| **System Admin** | `admin@scholaris.edu.ph` | `Scholaris2026!` | ✅ **SUCCESS** | `d0570000-0000-0000-0000-000000000000` |

> [!CAUTION]
> **Credential Alert**: Alternative emails formatted as `@scholaris.ph` (e.g. `demo_student@scholaris.ph`, `demo_provider@scholaris.ph`, `demo_evaluator@scholaris.ph`) returned `invalid_credentials` from Supabase Auth. The presenter MUST use the verified `@scholaris.edu.ph` and `@scholaris.gov.ph` accounts listed above.

### 4.2. Database State & Pre-Demo Findings

1. **Active DOST Scholarships**:
   - `[d0570003-0000-0000-0000-000000000003]` `"DOST-SEI Undergraduate Scholarship (RA 7687)"`  
     • Owner: `d0570002-0000-0000-0000-000000000002` (`provider.dost@scholaris.gov.ph`)  
     • Deadline: `2026-11-28` (Active)  
     • **Primary Target Scholarship for Classroom Demo**.
   - `[bcb518b3-f789-45f9-997e-df6db19aab5c]` `"DOST-SEI STEM Leadership Grant 2026"`  
     • Owner: `0574ae43-93ca-4961-a90a-efba58f373ef`  
     • Deadline: `2026-12-31` (Active).
   - `[ff0922be-e3ca-4276-b341-92707c5c03b2]` `"DOST-SEI Undergraduate Scholarship"`  
     • Owner: `null`  
     • Deadline: `2026-10-15` (**EXPIRED legacy record**; do not select during demo).

2. **Student Tracker Queue**:
   - Found **1 existing application** (`ID: 7a68e990-77f7-4c1d-954c-d7eaac389226`, Status: `submitted`) submitted on 2026-10-18.
   - **Required Action Before Presentation**: Run `SELECT public.reset_demo_student();` in the Supabase SQL Editor to reset the student to 0 applications.

3. **Student Notification Queue**: Clean (**0 items**).

4. **Organization Memberships & Provider Incoming Queue**:
   - `public.organization_memberships` currently has **0 records** in the remote database.
   - Under Migration 0024 RLS, `application_org_read` restricts incoming application queries via `public.can_review_scholarship()`, which checks `public.organization_role(s.created_by) in ('org_admin', 'reviewer')`.
   - Because memberships are currently empty, `provider.dost@scholaris.gov.ph` queries return 0 incoming applications.
   - **Required Action Before Presentation**: Run operator provisioning SQL to grant `d0570002-0000-0000-0000-000000000002` membership as `org_admin`:
     ```sql
     INSERT INTO public.organization_memberships (user_id, organization_id, role, active)
     VALUES ('d0570002-0000-0000-0000-000000000002', 'd0570002-0000-0000-0000-000000000002', 'org_admin', true)
     ON CONFLICT (user_id) DO UPDATE SET active = true, role = 'org_admin';
     ```

---

## 5. Live Demonstration Script Audit

`docs/reports/3RD_INCREMENT_LIVE_DEMO_SCRIPT.md` was audited and updated:
1. **Act 1 (Student Submission)**: Exact click targets for Discover -> `"DOST-SEI Undergraduate Scholarship (RA 7687)"` -> Eligibility Breakdown -> 3-Step Review -> Digital Signature -> Submit.
2. **Act 2 (Provider Deliberation)**: Added explicit differentiation between **Reviewer Endorsement** (`"Endorse to Org Admin for Decision"`) and **Org Admin Final Decision** (`"Approve Award"`).
3. **Act 3 (Student Confirmation & Package)**: Added direct step for mounting and inspecting the official **Scholarship Approval Letter & Award Certificate** (`ApplicationDecisionLetter`), followed by the celebratory animated **CeremonyScreen**.
4. **Pre-Demo Preparation Notes**: Added explicit reminders for resetting the student application state and ensuring provider organization membership is active.

---

## 6. Audit Verdict & Sign-Off

### Implemented / Audited
- [x] Automated test execution across 7 test suites (35 tests total, 100% pass).
- [x] Static analysis across 7 package subsystems (`flutter analyze` with 0 issues).
- [x] Negative edge-case verification for withdrawal guard, unauthenticated access, and authorization boundaries.
- [x] Remote database state audit via read-only authenticated inspection script (`scratch/verify_post_cleanup_state.mjs`).
- [x] Live demonstration script audit and alignment with verified live database configuration.

### Verified
- `flutter test test/application_workflow_transport_test.dart`: 10 passed (00:00)
- `flutter test test/reviewer_drawer_lifecycle_test.dart`: 1 passed (00:01)
- `flutter test test/application_decision_letter_test.dart`: 6 passed (00:00)
- `flutter test test/award_celebration_ui_test.dart`: 3 passed (00:01)
- `flutter test test/features/provider/provider_sub_role_test.dart`: 7 passed (00:00)
- `flutter test test/features/student/bottom_nav_tab_switch_test.dart`: 1 passed (00:01)
- `flutter test test/remediation_ui_review_test.dart`: 7 passed (00:03)
- `flutter analyze`: 0 issues found across all targeted directories (ran in 55.1s).
- Remote database audit: 4 verified active accounts authenticated via Supabase REST API (`student.demo@scholaris.edu.ph`, `provider.dost@scholaris.gov.ph`, `finance.dost@scholaris.gov.ph`, `admin@scholaris.edu.ph`).

### Not verified
- Write mutations on remote database: By directive (Rule 3 of Pre-Presentation Audit Plan), all live database checks were strictly read-only.
- Physical iOS device execution: Verified in Flutter Web and headless Flutter test environments.

### Remaining risks
- **Rehearsal Leftover Cleanup**: The demo student account currently holds 1 submitted application record from Oct 18 rehearsal. Must run `SELECT public.reset_demo_student();` before the live presentation so the presenter starts at 0 applications.
- **Provider Membership Provisioning**: Must ensure `organization_memberships` has an `org_admin` row for `d0570002-0000-0000-0000-000000000002` so incoming applications appear in the provider console under migration 0024 RLS.
- **Credential Domain Awareness**: Presenters must not use `@scholaris.ph` aliases; use verified `@scholaris.edu.ph` and `@scholaris.gov.ph` credentials.
