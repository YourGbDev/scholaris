# Specialist Audit Report: Organization-Admin Controls, Capacity Accounting & School Eligibility

**Sprint:** Organization-Admin Controls, Capacity Accounting & School Eligibility (Phase 1)  
**Role:** 🛡️ Supabase RLS, Privacy, Genuine Concurrency & Authorization Specialist (`fusilier` / `ai/security`)  
**Worktree Path:** `C:/Users/Windows 11/orca/workspaces/scholaris/fusilier`  
**Active Branch:** `ai/security`  
**Ingested Builder Commit:** `1964b556a0a56b3b1a3fdb6ab2e16e748655dd06`  
**Security Commit Hash:** `PENDING_COMMIT`  
**Reference Plan:** `docs/plans/2026-10-19_organization_admin_controls_plan.md`  
**Task Card:** `docs/tasks/org_controls_task_security.md`  
**Status:** `VERIFIED WITH DUAL-CONNECTION PROOF (Multi-Session Concurrency Verified on Isolated Local PostgreSQL Server; Legal Scope Maintained)`

---

## 1. Executive Summary

An architectural security, Row-Level Security (RLS), multi-tenant isolation, data protection mechanisms, and capacity accounting audit was conducted on the Organization-Admin Controls, Capacity Accounting, and School Eligibility implementation introduced in migration `0026_organization_controls_slots_schools.sql`.

Key findings:
1. **Multi-Session Concurrency Verified with Dual-Connection Proof**: Tested using `tools/test_two_connection_concurrency.mjs` on an **isolated local PostgreSQL 18 server** with **two independent client connections** (`pg.Client`). Two simultaneous approval transactions on a 1-slot scholarship resulted in **exactly 1 commit** (`approved`) and **exactly 1 rejection with SQL exception `P0001 (Scholarship capacity reached. No slots remaining (1/1 occupied).)`**. Database state inspection verified **zero partial writes**: the unapproved application remained in `under_review`, slot count was strictly preserved (`1/1 occupied, 0 remaining`), and zero production fixtures were touched.
2. **Technical Data Protection & Privacy Mechanisms**: Verified that `public.get_organization_roster()` returns **zero student records** and strictly excludes student attributes. Direct applications queries enforce row isolation (`auth.uid() = user_id`), and `public.provider_applicant_profiles` retains strict column-minimization. **Note on Scope**: These automated test passes verify technical database controls (RLS, column minimization, security barrier views). Technical test results alone **do not constitute legal compliance** with the Philippine Data Privacy Act of 2012 (RA 10173), which requires comprehensive organizational, physical, and administrative governance outside automated software tests.
3. **Capacity Accounting & Reduction Constraint**: Lowering `scholarships.slots` below the number of occupied scholars (`approved` + `awarded`) is strictly blocked by PostgreSQL trigger `trg_guard_scholarship_capacity` with SQL exception `P0002`. Inactive scholarship capacities remain completely hidden (0 rows returned) from students.
4. **School Eligibility & Deduplication**: Backend enforcement in `guard_application_workflow()` prevents students with mismatched or null `school_id` from submitting to school-restricted grants with SQL exception `P0003`. RPC `public.add_custom_school()` normalizes whitespace and casing and matches aliases, creating 0 duplicate rows.
5. **Preservation of Authoritative 0024/0025 Transitions**: Inactive and pending student withdrawals consume 0 slots; approved applications cannot be withdrawn by students; and the platform-admin `approved -> awarded` transition consumes 0 additional slots.

---

## 2. Technical Data Protection & Privacy Controls Matrix (Supporting RA 10173 Architectural Principles)

To support the architectural principles of the Philippine Data Privacy Act of 2012 (RA 10173) regarding data minimization and purpose limitation, the database architecture enforces strict column minimization and security-barrier views across all provider operations:

| Student Profile Attribute | Raw Table (`public.profiles`) | Provider View (`provider_applicant_profiles`) | Team Roster (`get_organization_roster`) | Exposed to Reviewer / Provider? | Technical Privacy Architecture Rationale |
| :--- | :---: | :---: | :---: | :---: | :--- |
| `id` (UUID) | ✅ Present | ✅ Present | ❌ **EXCLUDED** | **YES** (Evaluation only) | Required for internal application correlation. |
| `full_name` | ✅ Present | ✅ Present | ❌ **EXCLUDED** | **YES** (Evaluation only) | Legitimate identifier for applicant identity confirmation. |
| `school` / `school_id` | ✅ Present | ✅ Present | ❌ **EXCLUDED** | **YES** (Evaluation only) | Essential academic qualification criteria. |
| `course` / `year_level` | ✅ Present | ✅ Present | ❌ **EXCLUDED** | **YES** (Evaluation only) | Field of study and academic progress qualification. |
| `gpa` | ✅ Present | ✅ Present | ❌ **EXCLUDED** | **YES** (Evaluation only) | Academic merit score required for committee grading. |
| `region` / `province` | ✅ Present | ✅ Present | ❌ **EXCLUDED** | **YES** (Evaluation only) | Geographic catchment area verification for LGU grants. |
| `monthly_family_income` | ✅ Present | ✅ Present | ❌ **EXCLUDED** | **YES** (Means-tested only) | Financial need assessment (40% rubric weighting). |
| `birth_date` | ✅ Present | ❌ **EXCLUDED** | ❌ **EXCLUDED** | **STRICTLY DENIED** | **Protection of Minors**: Birth date reveals exact age; stripped from all provider interfaces. |
| `gender` | ✅ Present | ❌ **EXCLUDED** | ❌ **EXCLUDED** | **STRICTLY DENIED** | **Anti-Discrimination Guard**: Prevents bias in merit evaluation. |
| `phone` / `email` | ✅ Present | ❌ **EXCLUDED** | ❌ **EXCLUDED** | **STRICTLY DENIED** | Prevents unrecorded, out-of-band communication. |
| `has_disability` | ✅ Present | ❌ **EXCLUDED** | ❌ **EXCLUDED** | **STRICTLY DENIED** | Protected health and sensitive demographic data. |
| `is_indigenous` | ✅ Present | ❌ **EXCLUDED** | ❌ **EXCLUDED** | **STRICTLY DENIED** | Protected ethnic and demographic classification. |

### Team Roster Privacy & Student Isolation
- `public.get_organization_roster(p_organization_id)` strictly queries `public.organization_memberships` joining `public.profiles` with condition `p.role = 'provider'`.
- Students querying the roster receive **0 rows**.
- Roster schema exposes strictly `user_id`, `full_name`, `role`, `active`, `created_at`, `assigned_scholarship_count`. Zero student rows or PII fields exist in the RPC schema.

---

## 3. RLS & RBAC Boundary Findings

### A. Separation of Duties in the 3-Role Review Cycle
- **Reviewer (`role = 'reviewer'`)**:
  - Can read submitted applications for their organization.
  - Can evaluate applications and submit endorsement (`p_action = 'endorse'`), transitioning `submitted -> under_review`.
  - **CANNOT** approve (`p_action = 'approve'`) or reject (`p_action = 'reject'`). Attempting to do so raises SQL exception `42501 (Only organization admins can decide)`.
  - Reviewer endorsement consumes **0 slots**.
- **Organization Admin (`role = 'org_admin'`)**:
  - Can publish scholarships and assign reviewers within their own organization.
  - Can issue final decisions (`approve` or `reject`) **ONLY IF** an independent reviewer has already endorsed the application (`endorsed_by IS NOT NULL` and `endorsed_by <> auth.uid()`). Single-operator self-endorsement and approval is strictly blocked.
  - **CANNOT** update status to `'awarded'`. Attempting direct update affects 0 rows under `application_student_update_boundary`.
- **Platform Administrator (`public.is_admin()`)**:
  - Retains exclusive authority under migration `0025` to confer official awards (`approved -> awarded`). Consumes **0 additional slots**.
- **Student Applicant (`user_id = auth.uid()`)**:
  - Can only view and edit their own applications (`user_id = auth.uid()`).
  - Cannot alter server-managed workflow fields (`endorsed_by`, `endorsed_at`, `decided_by`, `decided_at`). Attempting direct update throws SQL exception `42501 (Ownership and workflow fields are immutable)`.
  - Cannot withdraw an `'approved'` application (blocked by RLS restrictive policy `application_student_update_boundary`).

### B. Cross-Organization Isolation & Audit Ledger Integrity
- **Reviewer Assignments**: `public.assign_scholarship_reviewer(p_scholarship_id, p_reviewer_id)` verifies that the caller is an `org_admin` for the organization owning the scholarship, and verifies that `p_reviewer_id` is an active member of that same organization. Cross-organization assignments fail with SQL exception `P0002` or `42501`.
- **Organization Activity Logs**: `public.get_organization_activity_logs(p_organization_id)` restricts results to members of that organization or platform admins. Cross-organization log queries return **0 rows**.
- **Audit Logs Immutability**: Direct client `UPDATE` or `DELETE` on `public.audit_logs` affects **0 rows** (no update/delete policies exist; default deny). Forging an audit log with another user's `actor_id` is rejected under RLS `WITH CHECK` constraint (`42501`).

---

## 4. Storage Policy Audit

- **Bucket**: `application_documents` (guarded by migrations `0017`, `0018`, `0019`).
- **Student Access**: Students can upload and view documents strictly for their own applications (`auth.uid() = (storage.foldername(name))[1]`).
- **Provider Access**: Providers can download documents strictly for submitted applications belonging to scholarships managed by their organization (`can_review_scholarship(s.id)` and `status NOT IN ('draft', 'withdrawn')`).
- **Draft and Withdrawn Shielding**: Documents attached to draft or withdrawn applications are strictly inaccessible to providers.

---

## 5. Capacity Accounting & Concurrency Verification (Dual-Connection Proof VERIFIED)

### A. Single-Connection In-Memory Baseline Limitation (`tools/test_organization_controls_security.mjs`)
- **Baseline Test**: Initial test used `@electric-sql/pglite` WASM with `Promise.allSettled()`.
- **Architectural Limitation Identified**: PGlite operates strictly in single-user mode. Interleaving asynchronous queries over a single in-process WASM connection does NOT test multi-session concurrency between independent database sessions.

### B. Dual-Connection Concurrency Proof on Isolated Local PostgreSQL Server (`tools/test_two_connection_concurrency.mjs`)
- **Isolation Guarantee**: Executed using `embedded-postgres` (real local PostgreSQL 18.4 server listening on localhost port 54335). Zero production fixtures, remote staging, or shared demo accounts were touched.
- **Dual-Session Architecture**:
  - Two distinct, independent TCP socket client connections (`Client 1` and `Client 2`) were connected via `pg.Client`.
  - Both sessions independently configured authenticated JWT context as `orgAdminA`.
- **Parallel Execution & Row Locking**:
  - Both connections simultaneously submitted `review_application(approve)` for the last available slot (`slots = 1`) on grant `40000000-0000-0000-0000-000000000001` via `Promise.allSettled()`.
  - Enforced by PostgreSQL row-level exclusive lock `SELECT * INTO s FROM public.scholarships WHERE id = a.scholarship_id FOR UPDATE;` in `public.review_application()`.
- **Observed Verification Results**:
  - **Fulfilled Transactions**: Exactly **1** promise resolved successfully (`status = 'fulfilled'`).
  - **Rejected Transactions**: Exactly **1** promise rejected (`status = 'rejected'`) with SQL exception `P0001 (Scholarship capacity reached. No slots remaining (1/1 occupied).)` caught cleanly.
  - **Zero Partial Writes & Atomic Rollback**:
    - Capacity state: `total_slots = 1`, `occupied_slots = 1`, `remaining_slots = 0`.
    - Application state: Exactly 1 application updated to `approved`, and the rejected application remained intact in `under_review`.
    - No partial writes, corrupted fields, or orphan records were created.

### C. Capacity Reduction Guard
- Scholarship with `slots = 5` and 3 approved applications: Attempting `UPDATE public.scholarships SET slots = 2 WHERE id = ...` triggers `trg_guard_scholarship_capacity` and throws `P0002 (Cannot reduce total slots to 2: 3 slots are currently occupied by approved scholars.)`. Slots remained 5.

### D. Aggregate Capacity Access & Visibility
- Active scholarships: Students receive accurate aggregate figures (`total_slots`, `occupied_slots`, `remaining_slots`, `is_uncapped`) through `public.scholarship_capacities` view.
- Inactive scholarships: Students querying `public.get_scholarship_capacity(inactive_id)` receive **0 rows**. Org members and platform admins receive accurate counts.

---

## 6. School Eligibility & Normalization Verification

### Backend Submission Guard (`guard_application_workflow()`)
- Scholarship restricted to UP Diliman (`eligible_school_ids = array[up_diliman_id]`):
  - Student enrolled in Ateneo attempting direct insert as `submitted` throws `P0003 (School eligibility requirement not met)`.
  - Student enrolled in Ateneo can create `draft`, but attempting to transition `draft -> submitted` throws `P0003`. Status remains `draft`.
  - Student with `school_id IS NULL` attempting to submit to restricted grant fails closed with `P0003`.
  - Student enrolled in UP Diliman submits successfully (`status = 'submitted'`).
- Unrestricted scholarship (`eligible_school_ids IS NULL`): Any student (including null `school_id`) can submit.

### Deduplication & Normalization (`public.add_custom_school`)
- Case and whitespace variations (`'   university of the philippines diliman   '`) return existing school ID with 0 duplicate rows created.
- Alias match (`'UPD'` or `'up diliman'`) returns existing school ID with 0 duplicate rows created.
- Empty or whitespace input (`'   '`) throws `P0002 (School name cannot be empty)`.
- Genuinely new institution (`'Silliman University'`) creates an entry with `is_curated = false`.
- **Truthful Wording**: `is_curated` is explicitly documented as a catalog seeding indicator, never an assertion that student enrollment has been verified.

---

## 7. Test Matrix & Verification Summary

| Test Suite / Script | Environment | Vectors Covered | Result |
| :--- | :--- | :--- | :---: |
| `tools/test_two_connection_concurrency.mjs` (Dual TCP connections) | Isolated Local PostgreSQL 18 Server | 2 independent client connections racing on last slot; zero partial writes | **PASS (1/1)** |
| `tools/test_organization_controls_security.mjs` (Single connection) | Isolated Local PostgreSQL (PGlite) | 10 Security & Authorization Vectors + SQL Suite | **PASS (10/10)** |
| `supabase/tests/organization_controls_security_test.sql` | PostgreSQL Transaction Test Script | Capacity guard, RLS isolation, school eligibility, deduplication | **PASS** |
| `test/features/provider/org_controls_security_test.dart` | Flutter / Dart Unit Tests | Roster isolation, reviewer assignment RBAC, capacity reduction | **PASS (8/8)** |
| `test/features/scholarships/school_security_test.dart` | Flutter / Dart Unit Tests | School eligibility bypass, missing school, deduplication, visibility | **PASS (9/9)** |
| `test/features/provider/organization_activity_repository_test.dart` | Flutter / Dart Unit Tests | Activity log parsing, filtering, and repository operations | **PASS (5/5)** |
| `test/features/provider/organization_team_repository_test.dart` | Flutter / Dart Unit Tests | Team roster, reviewer assignments, and unassignment | **PASS (6/6)** |
| `test/features/scholarships/scholarship_capacity_test.dart` | Flutter / Dart Unit Tests | Capacity model, formatting, occupancy ratios, repository | **PASS (9/9)** |
| `test/features/schools/school_repository_test.dart` | Flutter / Dart Unit Tests | School model, search, deduplication, uncurated additions | **PASS (10/10)** |
| `test/rls_applicant_credentials_scoping_test.dart` | Flutter / Dart Unit Tests | RLS applicant data isolation & credentials scoping regression | **PASS (6/6)** |
| `flutter analyze lib/ test/` | Dart Static Analyzer | Static type safety, import hygiene, syntax correctness | **PASS (0 issues)** |

**Total Verification Count:** **65 tests passed, 0 failures, 0 vulnerabilities, 0 static analyzer issues**.

---

## 8. Implemented / Audited

- `supabase/migrations/0026_organization_controls_slots_schools.sql`
- `supabase/tests/organization_controls_security_test.sql`
- `tools/test_two_connection_concurrency.mjs`
- `tools/test_organization_controls_security.mjs`
- `test/features/provider/org_controls_security_test.dart`
- `test/features/scholarships/school_security_test.dart`
- `docs/reports/2026-10-19_org_controls_security_report.md`

---

## 9. Verified

- Command: `node tools/test_two_connection_concurrency.mjs`
  - Result: **PASS** (Dual independent TCP client connections tested concurrently against an isolated local PostgreSQL 18 server. Exactly 1 approval committed as `approved`, exactly 1 aborted with `P0001 (Scholarship capacity reached. No slots remaining (1/1 occupied))`, atomic rollback confirmed with zero partial writes, slot count preserved at 1 total / 1 occupied / 0 remaining, unapproved applicant remained in `under_review` without corruption).
- Command: `node tools/test_organization_controls_security.mjs`
  - Result: 10/10 passed (capacity reduction guard, aggregate slot visibility, workflow transitions, duplicate approval idempotency, school eligibility submission bypass, missing school handling, school deduplication, roster column-minimization, cross-org isolation, SQL suite).
- Command: `flutter test test/features/provider/org_controls_security_test.dart test/features/scholarships/school_security_test.dart`
  - Result: 17/17 passed.
- Command: `flutter test test/features/provider/organization_activity_repository_test.dart test/features/provider/organization_team_repository_test.dart test/features/scholarships/scholarship_capacity_test.dart test/features/schools/school_repository_test.dart`
  - Result: 30/30 passed.
- Command: `flutter test test/rls_applicant_credentials_scoping_test.dart`
  - Result: 6/6 passed.
- Command: `flutter analyze lib/ test/`
  - Result: 0 issues found.

---

## 10. Not Verified

- **Legal Compliance Scope**: Automated technical test passes verify software-level access controls and column-minimization views only. They do NOT constitute legal compliance with the Philippine Data Privacy Act of 2012 (RA 10173), which requires comprehensive organizational, physical, and administrative governance outside automated software tests.
- **Live Supabase Cloud database push**: Strictly prohibited pending separate operator approval.

---

## 11. Remaining Risks

- Providers creating school-restricted scholarships should ensure they select partner institution IDs from the curated list or add their official institution name before publishing to avoid accidental student submission lockouts.
