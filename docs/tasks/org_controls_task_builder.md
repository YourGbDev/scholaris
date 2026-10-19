# Task Card: Builder (`cowrie` / `ai/builder`)

**Sprint:** Organization-Admin Controls, Capacity Accounting & School Eligibility (Phase 1)  
**Role:** 🔨 Backend, Supabase Persistence, RPCs & Data Access Specialist  
**Worktree Path:** `C:/Users/Windows 11/orca/workspaces/scholaris/cowrie`  
**Active Branch:** `ai/builder`  
**Baseline Commit:** `33e13080f41dd78823f277588cef85d05e1c228e`  
**Reference Plan:** `docs/plans/2026-10-19_organization_admin_controls_plan.md`  
**Status:** `COMPLETED (Commit: 1964b556a0a56b3b1a3fdb6ab2e16e748655dd06)`

---

## 1. Objective
Implement database migration `0026_organization_controls_slots_schools.sql`, data models, repositories, and Riverpod providers to support:
1. Organization-scoped activity logs and reviewer assignment management.
2. Atomic scholarship slot capacity accounting with **backend aggregate slot access respecting scholarship visibility**, treating migrations 0024/0025 as authoritative.
3. School eligibility infrastructure: master `public.schools` catalog seeded with 10 neutral pre-populated universities (zero arbitrary rankings), `add_custom_school` RPC with deduplication, student profile backfill migration, and backend submission enforcement.

---

## 2. Permitted Files
- `supabase/migrations/0026_organization_controls_slots_schools.sql` (new)
- `lib/features/schools/models/school.dart` (new)
- `lib/features/schools/data/school_repository.dart` (new)
- `lib/features/schools/providers/school_provider.dart` (new)
- `lib/features/scholarships/models/scholarship_capacity.dart` (new)
- `lib/features/scholarships/data/scholarship_capacity_repository.dart` (new)
- `lib/features/scholarships/providers/scholarship_capacity_provider.dart` (new)
- `lib/features/provider/models/organization_activity_log.dart` (new)
- `lib/features/provider/models/organization_team_member.dart` (new)
- `lib/features/provider/models/scholarship_reviewer_assignment.dart` (new)
- `lib/features/provider/data/organization_activity_repository.dart` (new)
- `lib/features/provider/data/organization_team_repository.dart` (new)
- `lib/features/provider/providers/organization_activity_provider.dart` (new)
- `lib/features/provider/providers/organization_team_provider.dart` (new)
- `lib/features/provider/providers/provider_sub_role_provider.dart` (read/minor helper export only)
- `test/features/provider/organization_activity_repository_test.dart` (new)
- `test/features/provider/organization_team_repository_test.dart` (new)
- `test/features/schools/school_repository_test.dart` (new)
- `test/features/scholarships/scholarship_capacity_test.dart` (new)
- `docs/reports/2026-10-19_org_controls_builder_report.md` (deliverable report)

**Explicitly Forbidden**: Modifying presentation UI files, altering student application screens, touching migrations 0001–0025, or resetting demo seed data.

---

## 3. Implementation Requirements

### A. Authoritative Baseline (Preservation of 0024/0025 Permissions & Transitions)
* Treat the current migration `0024` and `0025` behavior as **authoritative**:
  - `review_application()` remains `SECURITY DEFINER SET search_path = ''`.
  - `REVOKE ALL ... FROM public, anon; GRANT EXECUTE ... TO authenticated;`.
  - Preserve DB owner trigger bypass in `guard_application_workflow()`.
  - Actor permissions & transitions:
    - `reviewer` endorsement: only active reviewer in grantor org can endorse (`submitted` $\rightarrow$ `under_review`, 4 rubric scores). Consumes **0 slots**.
    - `org_admin` approval: only active org admin can approve from `under_review` (requires independent reviewer endorsement). Consumes **1 slot**. Org admins retain final approval and rejection authority.
    - `org_admin` rejection: transitions `under_review` $\rightarrow$ `rejected`. Consumes **0 slots**.
    - Platform-Admin award transition: Under migration 0025, only platform admins (`public.is_admin()`) are authorized to update an application from `approved` $\rightarrow$ `awarded` under policy `"Admins can update approved applications to awarded"`. Org admins retain final approval/rejection authority, NOT awarding authority. When a platform admin executes this transition, it consumes **0 additional slots**.
    - Student withdrawal: only allowed for pending applications (`draft`, `submitted`, `under_review`). Inactive/pending withdrawals consume **0 slots** (and release 0 slots, as pending applications never occupy capacity).
    - Students cannot withdraw `approved` applications. No arbitrary status reversals are invented.

### B. Backend Aggregate Slot Access (Respecting Scholarship Visibility)
* Students cannot query other students' application records due to RLS.
* Create security barrier view `public.scholarship_capacities`:
  ```sql
  create or replace view public.scholarship_capacities with (security_barrier = true) as
  select
    s.id as scholarship_id,
    s.slots as total_slots,
    coalesce(count(a.id) filter (where a.status in ('approved', 'awarded')), 0)::int as occupied_slots,
    case
      when s.slots is null then null
      else greatest(0, s.slots - coalesce(count(a.id) filter (where a.status in ('approved', 'awarded')), 0)::int)
    end as remaining_slots,
    (s.slots is null) as is_uncapped
  from public.scholarships s
  left join public.applications a on a.scholarship_id = s.id
  where (
    -- Visibility rule: students only see active grants; org members see their own
    s.is_active = true
    or public.is_admin()
    or exists (
      select 1 from public.organization_memberships m
      where m.user_id = auth.uid()
        and m.organization_id = s.created_by
        and m.active = true
    )
  )
  group by s.id, s.slots, s.is_active, s.created_by;

  grant select on public.scholarship_capacities to authenticated;
  ```
* Expose helper RPC `public.get_scholarship_capacity(p_scholarship_id uuid)` with identical visibility enforcement.

### C. Atomic Capacity Enforcement & Reduction Guard
1. **Inside `review_application()`**:
   - `SELECT * INTO s FROM public.scholarships WHERE id = a.scholarship_id FOR UPDATE;`
   - When `p_action = 'approve'`:
     - If `s.slots IS NOT NULL`:
       - Count occupied slots excluding `a.id`:
         `SELECT count(*) INTO v_occupied FROM public.applications WHERE scholarship_id = s.id AND status IN ('approved', 'awarded') AND id <> a.id;`
       - If `v_occupied >= s.slots`:
         `RAISE EXCEPTION 'Scholarship capacity reached. No slots remaining (%/% occupied).' USING errcode = 'P0001';`
2. **Trigger `guard_scholarship_capacity()` on `public.scholarships`**:
   - On `BEFORE UPDATE OF slots`:
     - If `new.slots < (SELECT count(*) FROM public.applications WHERE scholarship_id = new.id AND status IN ('approved', 'awarded'))`:
       `RAISE EXCEPTION 'Cannot reduce total slots below occupied count.' USING errcode = 'P0002';`

### D. School Catalog & Profile Migration (Truthful Wording)
1. **Table `public.schools`**:
   - `id uuid primary key default gen_random_uuid()`, `name text not null`, `normalized_name text not null unique`, `aliases text[] not null default '{}'`, `is_curated boolean not null default true`, `created_by uuid references auth.users(id)`, `created_at timestamptz not null default now()`.
   - Seed 10 neutral, unranked universities in alphabetical order:
     - Adamson University, Ateneo de Manila University, De La Salle University, Far Eastern University, Mapúa University, Pamantasan ng Lungsod ng Maynila, Polytechnic University of the Philippines, Technological University of the Philippines, University of Santo Tomas, University of the Philippines Diliman.
2. **RPC `public.add_custom_school(p_name text)`**:
   - Normalizes input (`lower(trim(regexp_replace(p_name, '\s+', ' ', 'g')))`).
   - If normalized name or alias matches existing row, returns existing ID (deduplication).
   - Otherwise, inserts new row with `is_curated = false`.
3. **Student Profile Migration Backfill**:
   - `ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS school_id uuid REFERENCES public.schools(id);`
   - In migration `0026`, match existing non-null `profiles.school` text against `schools.normalized_name` or `aliases`; update `profiles.school_id`. If unlisted, auto-insert an uncurated school row and link it.
   - Keep existing `profiles.school text` column intact for backward compatibility.
4. **Backend Submission Enforcement in `guard_application_workflow()`**:
   - On student insert or update to `status = 'submitted'`:
     - If `scholarships.eligible_school_ids` has items:
       - Validate student's `profiles.school_id = ANY(scholarships.eligible_school_ids)`.
       - If null or not matching: `RAISE EXCEPTION 'School eligibility requirement not met.' USING errcode = 'P0003';`

### E. Activity Log & Reviewer Assignment RPCs
- `public.assign_scholarship_reviewer(p_scholarship_id, p_reviewer_id)` (idempotent, logs to `audit_logs`).
- `public.unassign_scholarship_reviewer(p_scholarship_id, p_reviewer_id)`.
- `public.get_organization_roster(p_organization_id)` (zero student profiles).
- `public.get_organization_activity_logs(p_organization_id, p_limit, p_offset, p_action_filter)` (deduplicated, stable ordering).

---

## 4. Repositories & Riverpod Providers
1. `ScholarshipCapacityRepository`: Connects directly to `public.scholarship_capacities` view and `get_scholarship_capacity` RPC. Exposes `fetchCapacity(scholarshipId)`.
2. `SchoolRepository`: Methods to `fetchSchools()`, `searchSchools(query)`, and `addSchool(name)`.
3. `OrganizationActivityRepository` & `OrganizationTeamRepository`: Connect directly to PostgREST RPCs.

---

## 5. Verification & Testing Instructions
1. Run static analysis:
   ```bash
   flutter analyze lib/features/schools/ lib/features/scholarships/ lib/features/provider/
   ```
2. Run targeted repository tests:
   ```bash
   flutter test test/features/schools/school_repository_test.dart
   flutter test test/features/scholarships/scholarship_capacity_test.dart
   flutter test test/features/provider/organization_activity_repository_test.dart
   flutter test test/features/provider/organization_team_repository_test.dart
   ```
3. Run baseline regression tests:
   ```bash
   flutter test test/features/applications/transaction_cycle_test.dart
   flutter test test/features/provider/provider_sub_role_test.dart
   ```

---

## 6. Deliverable Report & Commit Hash
Commit report and code to `ai/builder`:
- Report: `docs/reports/2026-10-19_org_controls_builder_report.md`
- Output the exact commit hash `<BUILDER_COMMIT_HASH>` in the report header.
