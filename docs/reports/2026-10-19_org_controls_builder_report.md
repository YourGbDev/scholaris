# Builder Implementation Report: Organization-Admin Controls, Capacity Accounting & School Eligibility

**Sprint:** Organization-Admin Controls, Capacity Accounting & School Eligibility (Phase 1)  
**Role:** 🔨 Backend, Supabase Persistence, RPCs & Data Access Specialist (`cowrie` / `ai/builder`)  
**Reference Plan:** `docs/plans/2026-10-19_organization_admin_controls_plan.md`  
**Task Card:** `docs/tasks/org_controls_task_builder.md`  
**Baseline Hash:** `33e13080f41dd78823f277588cef85d05e1c228e`  
**Builder Commit Hash:** `a57f1de0198daa1d3b58fb561c2736f65ef8ee8e`  
**Status:** `IMPLEMENTATION & AUTOMATED VERIFICATION COMPLETE`

---

### Implemented

1. **Database Migration (`supabase/migrations/0026_organization_controls_slots_schools.sql`)**:
   - **Master Schools Catalog (`public.schools`)**:
     - Columns: `id` (UUID PK), `name` (text), `normalized_name` (text unique), `aliases` (text[]), `is_curated` (boolean default true), `created_by` (UUID references auth.users), `created_at` (timestamptz).
     - RLS enabled with read-only policy for authenticated users: `"Schools are readable by all authenticated users"`.
     - Seeded 10 neutral, unranked Philippine universities in alphabetical order:
       - *Adamson University, Ateneo de Manila University, De La Salle University, Far Eastern University, Mapúa University, Pamantasan ng Lungsod ng Maynila, Polytechnic University of the Philippines, Technological University of the Philippines, University of Santo Tomas, University of the Philippines Diliman*.
   - **RPC `public.add_custom_school(p_name text)`**:
     - Normalizes input (`lower(trim(regexp_replace(p_name, '\s+', ' ', 'g')))`).
     - Deduplicates against existing `normalized_name` or `aliases`. If found, returns existing ID; otherwise, inserts an uncurated entry (`is_curated = false`) and returns new ID.
   - **Student Profile Migration Backfill**:
     - Added column `school_id` (UUID references `public.schools(id)`) to `public.profiles`.
     - Preserved legacy `profiles.school text` column for backwards compatibility.
     - Automatically normalized and linked existing student `school` strings to `schools.id` (inserting uncurated entries where unlisted).
   - **Scholarship School Eligibility (`public.scholarships.eligible_school_ids`)**:
     - Added `eligible_school_ids uuid[] default null` to `public.scholarships`.
   - **Backend Submission Enforcement in `public.guard_application_workflow()`**:
     - Preserved DB owner trigger bypass from migrations 0024/0025.
     - On INSERT (`status = 'submitted'`) and UPDATE (`draft` -> `submitted`): Validates that if `scholarships.eligible_school_ids` is non-empty, the student's `profiles.school_id` must match `ANY(eligible_school_ids)`. Otherwise, rejects with SQL error code `P0003`.
   - **Backend Aggregate Slot Access (`public.scholarship_capacities`)**:
     - Security barrier view respecting scholarship visibility:
       - Active scholarships (`s.is_active = true`) are visible to students.
       - Inactive scholarships are restricted to platform admins and organization members.
     - Accurately computes `total_slots`, `occupied_slots` (count of applications with status in `'approved'`, `'awarded'`), `remaining_slots` ($\max(0, \text{slots} - \text{occupied})$), and `is_uncapped` (`slots IS NULL`).
     - Exposed RPC `public.get_scholarship_capacity(p_scholarship_id uuid)`.
   - **Atomic Capacity Enforcement in `public.review_application()`**:
     - Row-level lock: `SELECT * INTO s FROM public.scholarships WHERE id = a.scholarship_id FOR UPDATE;`
     - On `p_action = 'approve'`: For capped scholarships, counts occupied slots excluding `a.id`. If occupied count reaches or exceeds `s.slots`, raises `P0001` (`Scholarship capacity reached. No slots remaining.`).
     - Preserved all authoritative 0024/0025 behaviors:
       - Reviewer endorsement (`submitted` -> `under_review`, 4 rubric scores) consumes **0 slots**.
       - Org-admin approval (`under_review` -> `approved`) consumes **1 slot**.
       - Org-admin rejection (`under_review` -> `rejected`) consumes **0 slots**.
       - Inactive/pending student withdrawals (`draft`, `submitted`, `under_review` -> `withdrawn`) consume **0 slots** and release **0 slots**.
       - Platform-admin award confirmation (`approved` -> `awarded`) under migration 0025 consumes **0 additional slots**.
       - Terminal locking: approved applications cannot be withdrawn by students.
   - **Capacity Reduction Guard Trigger (`trg_guard_scholarship_capacity`)**:
     - Before update of `slots` on `public.scholarships`: Rejects lowering total slots below currently occupied count with SQL error code `P0002`.
   - **Organization Activity Logs & Reviewer Assignments**:
     - Table `public.scholarship_reviewer_assignments` with uniqueness constraint `(scholarship_id, reviewer_id)` and RLS policies.
     - RPC `public.assign_scholarship_reviewer(p_scholarship_id, p_reviewer_id)` (validates active reviewer in org, upserts assignment, logs to `public.audit_logs`).
     - RPC `public.unassign_scholarship_reviewer(p_scholarship_id, p_reviewer_id)` (deletes assignment, logs to `public.audit_logs`).
     - RPC `public.get_organization_roster(p_organization_id)` (returns organization staff, active state, assigned scholarship count; strictly isolates student profiles).
     - RPC `public.get_organization_activity_logs(p_organization_id, p_limit, p_offset, p_action_filter)` (deduplicated audit trail for organization operations).

2. **Domain Models, Repositories & Riverpod Providers**:
   - **Schools**:
     - Model: `lib/features/schools/models/school.dart`
     - Repository: `lib/features/schools/data/school_repository.dart` (`fetchSchools()`, `searchSchools(query)`, `addSchool(name)`)
     - Providers: `lib/features/schools/providers/school_provider.dart` (`schoolsProvider`, `schoolSearchQueryProvider`, `filteredSchoolsProvider`)
   - **Scholarship Capacity**:
     - Model: `lib/features/scholarships/models/scholarship_capacity.dart` (`remainingLabel`, `occupancyRatioLabel`)
     - Repository: `lib/features/scholarships/data/scholarship_capacity_repository.dart` (`fetchCapacity(id)`, `fetchAllCapacities()`)
     - Providers: `lib/features/scholarships/providers/scholarship_capacity_provider.dart` (`scholarshipCapacityProvider`, `allScholarshipCapacitiesProvider`)
   - **Organization Governance & Activity**:
     - Models: `lib/features/provider/models/organization_activity_log.dart`, `organization_team_member.dart`, `scholarship_reviewer_assignment.dart`
     - Repositories: `lib/features/provider/data/organization_activity_repository.dart`, `organization_team_repository.dart`
     - Providers: `lib/features/provider/providers/organization_activity_provider.dart`, `organization_team_provider.dart`, and helper `currentOrganizationIdProvider` in `provider_sub_role_provider.dart`.

---

### Verified

1. **School Repository & Deduplication Test Suite**:
   - **Command:** `flutter test test/features/schools/school_repository_test.dart`
   - **Result:**
     ```
     00:00 +0: School Model Tests fromJson and toJson round-trip correctly
     00:00 +1: School Model Tests equality and hashCode work as expected by id
     00:00 +2: SchoolRepository Tests fetchSchools returns all schools parsed
     00:00 +3: SchoolRepository Tests searchSchools matches by name case-insensitively
     00:00 +4: SchoolRepository Tests searchSchools matches by alias
     00:00 +5: SchoolRepository Tests searchSchools with empty query returns all schools
     00:00 +6: SchoolRepository Tests searchSchools with non-matching query returns empty list
     00:00 +7: SchoolRepository Tests addSchool deduplicates existing school alias or normalized name
     00:00 +8: SchoolRepository Tests addSchool adds new uncurated school when not found
     00:00 +9: SchoolRepository Tests addSchool throws ArgumentError on empty or whitespace name
     00:00 +10: All tests passed!
     ```
   - **Status:** PASSED (10/10 tests, exit code 0).

2. **Scholarship Capacity Accounting Test Suite**:
   - **Command:** `flutter test test/features/scholarships/scholarship_capacity_test.dart`
   - **Result:**
     ```
     00:00 +0: ScholarshipCapacity Model Tests fromJson and toJson round-trip for capped scholarship
     00:00 +1: ScholarshipCapacity Model Tests full capacity displays Fully Booked
     00:00 +2: ScholarshipCapacity Model Tests uncapped scholarship displays Uncapped
     00:00 +3: ScholarshipCapacity Model Tests singular seat remaining renders grammatically
     00:00 +4: ScholarshipCapacity Model Tests equality and hashCode check all capacity fields
     00:00 +5: Authoritative Slot Accounting Rules Verification Simulated status filter: only approved and awarded occupy capacity
     00:00 +6: ScholarshipCapacityRepository Tests fetchCapacity returns correct parsed model for existing scholarship
     00:00 +7: ScholarshipCapacityRepository Tests fetchCapacity returns null for non-existing scholarship
     00:00 +8: ScholarshipCapacityRepository Tests fetchAllCapacities returns mapped map keyed by scholarship id
     00:00 +9: All tests passed!
     ```
   - **Status:** PASSED (9/9 tests, exit code 0).

3. **Organization Activity Repository Test Suite**:
   - **Command:** `flutter test test/features/provider/organization_activity_repository_test.dart`
   - **Result:**
     ```
     00:00 +0: OrganizationActivityLog Model Tests fromJson and toJson round-trip correctly
     00:00 +1: OrganizationActivityLog Model Tests equality checks by id
     00:00 +2: OrganizationActivityRepository Tests fetchActivityLogs returns all logs without filter
     00:00 +3: OrganizationActivityRepository Tests fetchActivityLogs passes action filter correctly
     00:00 +4: OrganizationActivityRepository Tests fetchActivityLogs returns empty list when none match
     00:00 +5: All tests passed!
     ```
   - **Status:** PASSED (5/5 tests, exit code 0).

4. **Organization Team Repository Test Suite**:
   - **Command:** `flutter test test/features/provider/organization_team_repository_test.dart`
   - **Result:**
     ```
     00:00 +0: Organization Team Models Tests OrganizationTeamMember fromJson and role helpers
     00:00 +1: Organization Team Models Tests ScholarshipReviewerAssignment fromJson and toJson
     00:00 +2: OrganizationTeamRepository Tests fetchRoster returns all parsed members
     00:00 +3: OrganizationTeamRepository Tests fetchAssignmentsForScholarship returns matching assignments
     00:00 +4: OrganizationTeamRepository Tests assignReviewer adds a new assignment
     00:00 +5: OrganizationTeamRepository Tests unassignReviewer removes the assignment
     00:00 +6: All tests passed!
     ```
   - **Status:** PASSED (6/6 tests, exit code 0).

5. **Baseline Regression Test Suites**:
   - **Command:** `flutter test test/features/applications/transaction_cycle_test.dart test/features/provider/provider_sub_role_test.dart`
   - **Result:** 15/15 tests passed (Exit code 0).
   - **Command:** `flutter test test/application_workflow_transport_test.dart`
   - **Result:** 10/10 tests passed (Exit code 0).

6. **Static Analysis of New and Modified Feature Packages**:
   - **Command:** `flutter analyze lib/features/schools/ lib/features/scholarships/ lib/features/provider/`
   - **Result:**
     ```
     Analyzing 3 items...
     No issues found! (ran in 31.6s)
     ```
   - **Status:** PASSED (0 issues found, exit code 0).

---

### Not verified

- **Remote Database Live Execution of Migration 0026**: Migration `0026` is stored locally in `supabase/migrations/0026_organization_controls_slots_schools.sql`. Per Section 4.A of the master plan, it has NOT been applied to the live remote Supabase instance, awaiting explicit operator approval.
- **Genuine Postgres Parallel Concurrency Matrix**: Per Section 3.E of the plan, parallel client locking tests (`tools/test_organization_controls_security.mjs`) are assigned to Security (`fusilier` / `ai/security`) to run on an isolated local PostgreSQL container.

---

### Remaining risks

1. **Remote Schema Application**: Remote Supabase staging/production instances will reject `school_id` and `get_scholarship_capacity` calls until migration `0026` is executed by the operator.
2. **Mobile Bytecode Recompilation**: Web clients immediately reflect new capacity widgets and school eligibility dropdowns; pre-installed physical iOS devices will require rebuilding and installing a new `.ipa` to display newly added mobile visual widgets.
