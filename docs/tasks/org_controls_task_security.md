# Task Card: Security (`fusilier` / `ai/security`)

**Sprint:** Organization-Admin Controls, Capacity Accounting & School Eligibility (Phase 1)  
**Role:** 🛡️ Supabase RLS, Privacy, Genuine Concurrency & Authorization Specialist  
**Worktree Path:** `C:/Users/Windows 11/orca/workspaces/scholaris/fusilier`  
**Active Branch:** `ai/security`  
**Baseline Commit:** `68dcaba65ed2e2b04e6c7d553d99e318cb5c648b`  
**Reference Plan:** `docs/plans/2026-10-19_organization_admin_controls_plan.md`  
**Status:** `UNLOCKED — READY FOR ACTIVATION`

---

## 1. Objective
Audit and verify the security, Row-Level Security (RLS) policies, concurrency locks, and authorization boundaries for:
1. **Genuine concurrency enforcement** on scholarship slot capacity executed exclusively against an **isolated local PostgreSQL database** (never production fixtures or shared demo accounts).
2. **Backend aggregate slot access** security and visibility enforcement (verifying students can read capacity metrics via `scholarship_capacities` without breaching applicant row privacy, and verifying inactive scholarships remain hidden from student capacity queries).
3. **Preservation of existing transaction permissions and transitions** from migrations `0024` and `0025` (verifying inactive/pending withdrawals consume 0 slots, and approved applications cannot be withdrawn by students).
4. **Backend school eligibility constraints** and school deduplication integrity.

---

## 2. Permitted Files
- `supabase/tests/organization_controls_security_test.sql` (new)
- `tools/test_organization_controls_security.mjs` (new)
- `test/features/provider/org_controls_security_test.dart` (new)
- `test/features/scholarships/school_security_test.dart` (new)
- `docs/reports/2026-10-19_org_controls_security_report.md` (deliverable report)

**Explicitly Forbidden**: Weakening RLS policies to pass tests, exposing student PII, using sequential mocks for concurrency testing, claiming automated verification without concrete proofs, or running concurrency tests against production or shared demo fixtures.

---

## 3. Integration Requirement: Commit-Based Ingestion
Do NOT merge an unfinished branch tip. Builder has committed their completed implementation at hash `1964b556a0a56b3b1a3fdb6ab2e16e748655dd06`. Integrate using:
```bash
git merge --no-edit 1964b556a0a56b3b1a3fdb6ab2e16e748655dd06
```

---

## 4. Concrete Security & Concurrency Test Matrix

Security must implement and execute automated assertions for the following 10 test vectors:

### 1. Genuine Parallel Concurrency Race Condition Test on Isolated Local Database
* **Test Isolation Non-Negotiable**:
  - MUST run against an **isolated local PostgreSQL database** (e.g., local ephemeral test container or dedicated local Postgres test instance).
  - **NEVER execute against production fixtures, remote staging, or shared demo accounts** (`demo_student@scholaris.ph`, `demo_provider@scholaris.ph`, Ayala Future Leaders Grant).
  - The test harness creates its own disposable test grant and mock applicants in setup, and tears them down completely.
* **Action**:
  - Implemented in `tools/test_organization_controls_security.mjs` using Node.js `pg` pool connecting as two distinct authenticated clients.
  - Setup: Disposable test scholarship with `slots = 1` and two distinct applications in `under_review` (both endorsed by a reviewer).
  - Concurrency Execution: Spawn two simultaneous, parallel client sessions and invoke `review_application(app1, 'under_review', 'approve')` and `review_application(app2, 'under_review', 'approve')` concurrently via `Promise.all()`.
* **Assertions**:
  - Exactly **1** transaction commits successfully with HTTP 200 / SQL OK.
  - Exactly **1** transaction aborts and throws SQL exception `P0001 (Scholarship capacity reached. No slots remaining.)`.
  - Database state check: `scholarship_capacities` confirms `occupied_slots = 1` and `remaining_slots = 0`.
  - The rejected application remains intact in `under_review` without corrupted state.

### 2. Capacity Reduction Constraint Test
* **Action**: Given a scholarship with `slots = 5` and 3 approved applications, attempt to execute `UPDATE public.scholarships SET slots = 2 WHERE id = ...`.
* **Assertions**:
  - PostgreSQL trigger throws `P0002 (Cannot reduce total slots below occupied count)`.
  - Scholarship slots remain 5.

### 3. Backend Aggregate Slot Access & Visibility Enforcement Test
* **Action**:
  - Authenticate as Student A: Query `public.scholarship_capacities` for an active scholarship with 10 applicants.
  - Authenticate as Student A: Query `public.scholarship_capacities` for an inactive/draft scholarship (`is_active = false`).
  - Attempt direct `SELECT * FROM public.applications WHERE scholarship_id = ...` as Student A.
* **Assertions**:
  - Active scholarship capacity query succeeds, returning accurate `total_slots`, `occupied_slots`, and `remaining_slots`.
  - Inactive scholarship capacity query returns **0 rows** for Student A (respecting scholarship visibility).
  - Direct `applications` query returns ONLY Student A's own row (0 other student rows exposed).

### 4. Preservation of Authoritative 0024/0025 Permissions & Transitions Audit
* **Action**: Verify `review_application` procedure permissions and workflow transition gates.
* **Assertions**:
  - `review_application` executes under `SECURITY DEFINER SET search_path = ''`.
  - Client attempts to directly `INSERT` or `UPDATE` workflow fields (`endorsed_by`, `decided_by`, `status`) fail with `42501`.
  - Platform-Admin Award Transition Boundary: Under migration 0025, the transition from `approved` $\rightarrow$ `awarded` is strictly authorized for platform admins (`public.is_admin()`). Org admins retain final approval/rejection authority, NOT awarding authority. An `org_admin` attempting to update an application to `'awarded'` is rejected with `42501 (insufficient_privilege)`. When executed by a platform admin, the transition succeeds and consumes **0 additional slots**.
  - Inactive and pending student withdrawals (`draft`, `submitted`, `under_review` $\rightarrow$ `withdrawn`) succeed and consume **0 slots** (occupied count remains 0).
  - Student attempt to withdraw an `approved` application is **rejected** under `application_student_update_boundary`.

### 5. Duplicate Decision Idempotency Test
* **Action**: Call `review_application('approve')` twice on the exact same application.
* **Assertions**:
  - Second approval does not consume an additional slot.
  - Occupied count remains unchanged.

### 6. Backend School Eligibility Submission Bypass Test
* **Action**: Student enrolled in `School_B` attempts to submit an application for a scholarship restricted to `[School_A]`.
* **Assertions**:
  - PostgreSQL throws `P0003 (School eligibility requirement not met)`.
  - Application row is not submitted.

### 7. Missing School Information Handling
* **Action**: Student with `school_id IS NULL` attempts to submit to a school-restricted grant.
* **Assertions**:
  - PostgreSQL throws `P0003`. Submission fails closed.

### 8. School Normalization & Deduplication Integrity Test
* **Action**: Call `public.add_custom_school('   university of the philippines diliman   ')` when `University of the Philippines Diliman` already exists.
* **Assertions**:
  - Returns existing school ID; zero duplicate rows created in `public.schools`.

### 9. Roster Column-Minimization & Student Isolation Test
* **Action**: Execute `public.get_organization_roster(p_organization_id)` as an authenticated Org Admin.
* **Assertions**:
  - Returned rows contain **ZERO** records with `profiles.role = 'student'`.
  - Sensitive student attributes are completely absent from the RPC schema.

### 10. Cross-Organization Isolation & Audit Ledger Integrity
* **Action**:
  - Authenticate as `Org_Admin_A` and attempt to call `get_organization_activity_logs(Org_B_ID)` or assign reviewers for Org B.
  - Attempt direct client `INSERT INTO public.audit_logs`.
* **Assertions**:
  - Both cross-org calls fail with `42501 (insufficient_privilege)`.
  - Direct audit log insert fails with `42501`. Existing triggers in 0014 and 0016 remain intact.

---

## 5. Verification & Testing Instructions
1. Run Node.js database concurrency and security test suite against isolated local database:
   ```bash
   node tools/test_organization_controls_security.mjs
   ```
2. Run Dart security test suite:
   ```bash
   flutter test test/features/provider/org_controls_security_test.dart
   flutter test test/features/scholarships/school_security_test.dart
   ```

---

## 6. Deliverable Report & Commit Hash
Commit report and test scripts to `ai/security`:
- Report: `docs/reports/2026-10-19_org_controls_security_report.md`
- Output the exact commit hash `<SECURITY_COMMIT_HASH>` in the report header so QA can review findings before sign-off.
