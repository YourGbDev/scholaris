# Scholaris — Organization-Admin Controls, Capacity Accounting & School Eligibility Plan (Phase 1 Revised)

**Date:** October 19, 2026  
**Author:** 🧠 Architect (`whelk` / `ai/architect`)  
**Strict Implementation Scope:**  
1. Organization-Admin Sidebar Integration (Activity Log & Team / Reviewer Assignments)  
2. Scholarship Slot Capacity Accounting (Backend Aggregate Slot Access Respecting Visibility, Atomic PostgreSQL Enforcement, Genuine Concurrency Tests on Isolated Local DB, Inactive/Pending Withdrawals Consume Zero Slots, In-App Feedback)  
3. School Eligibility (Normalized Schools, 10 Pre-Populated Seed Universities Without Arbitrary Rankings, Searchable Multi-Select + Add School, Backend Submission Enforcement, Student Profile Migration & Truthful Verification Wording)  
**Future Scope (Preserved for Later Sprints):** Treasury Payout Batches & Financial Disbursements, Demographics CSV Export Engine, Scholar Renewal Workflows  
**Status:** `AWAITING HUMAN APPROVAL (NON-NEGOTIABLE GATE)`  
**Baseline Git Ancestry Base:** `26094165d3824f8d75cf81c2069fa89487c80ee9` (Verified across all branches)

---

## 1. Context & Authoritative Baseline Summary

Following the Increment 3 demo checking, our teacher provided actionable requirements to harden Scholaris for production deployment:
1. **Sidebar Navigation**: Provide direct, functional access to **Activity Log** and **Team / Reviewer Assignments** from the Organization-Admin sidebar, reusing existing controls without placeholder pages or duplicate routes.
2. **Accurate Slot Accounting**: During the demo, a scholarship configured with 25 slots continued to display 25 slots after an applicant was approved. Capacity must be rigorously accounted for:
   - Configured slots represent total capacity; total, occupied, and remaining seats must be derived dynamically and displayed clearly.
   - Authoritative Migration 0024/0025 Behavior: Final approval (`under_review` $\rightarrow$ `approved`) reserves 1 slot; reviewer endorsement reserves 0 slots.
   - Moving from `approved` $\rightarrow$ `awarded` represents an administrative grant confirmation and must not consume an additional slot.
   - Inactive/pending withdrawals (from `draft`, `submitted`, or `under_review`) consume **0 slots** (and release 0 slots, as pending records never occupy capacity).
   - Under authoritative 0024/0025 rules, `approved` is terminal for students; students cannot withdraw an approved application, and no arbitrary status reversals are invented.
   - Repeated requests or duplicate decisions must never double-count.
   - Capacity must be enforced atomically in PostgreSQL using row-level locking (`FOR UPDATE`) to prevent race-condition overbooking.
   - Capacity queries must respect scholarship visibility so students only view capacity for active, published scholarships.
   - Genuine concurrency tests must execute against an **isolated local PostgreSQL database**—never against production fixtures or shared demo accounts.
   - Uncapped scholarships (`slots IS NULL`) must be preserved without artificial limits. Reducing capacity below occupied count must be strictly rejected.
3. **School Eligibility**:
   - Provide dual modes in scholarship creation/editing: "Open to all schools" vs. "Restricted to selected schools".
   - When restricted, offer a searchable multi-select dropdown seeded with 10 pre-populated universities (without arbitrary rankings), plus an "Add School" option if an institution is missing.
   - Replace fragile free-text student school strings with normalized school entities and deduplicated master records (`public.schools`).
   - Define student school-profile migration for legacy data and form editing paths.
   - Enforce school eligibility on the backend when an application is submitted (UI filtering alone is insufficient).
   - Use strictly truthful verification wording: enrollment is self-declared on profile and verified via submitted credentials (COR/ID); zero claims of automated verification.

---

## 2. Preservation of Existing Transaction Permissions & Transitions

All existing transaction policies, actor permissions, and workflow triggers established in migrations `0024_organization_review_cycle.sql` and `0025_preserve_existing_award_transition.sql` are treated as **authoritative** and strictly preserved:

1. **Transaction Function Security & Grants**:
   - `public.review_application(uuid, text, text, jsonb, text)` remains `SECURITY DEFINER SET search_path = ''`.
   - Execution permissions remain revoked from `public, anon` and granted exclusively to `authenticated`.
2. **Actor Permissions & Allowed Transitions**:
   - `reviewer` endorsement: Only members with active `role = 'reviewer'` in the grantor organization can endorse. Transitions `submitted` $\rightarrow$ `under_review`, records 4 rubric scores into `public.application_evaluations` with `decision = 'endorsed'`, sets `endorsed_by = auth.uid()` and `endorsed_at = now()`. Consumes **0 slots**.
   - `org_admin` approval: Only active `org_admin` can decide. Transitions `under_review` $\rightarrow$ `approved`, asserts independent endorsement (`endorsed_by <> auth.uid()`), sets `decided_by = auth.uid()` and `decided_at = now()`, inserts into `public.notifications`. Consumes **1 slot**. Org admins retain final approval and rejection authority.
   - `org_admin` rejection: Transitions `under_review` $\rightarrow$ `rejected`. Consumes **0 slots**.
   - Platform Admin award transition: Under migration 0025, only platform administrators (`public.is_admin()`) are authorized to update an application from `approved` $\rightarrow$ `awarded` ("Admins can update approved applications to awarded"). Org admins retain final approval/rejection authority, NOT awarding authority. When a platform admin executes the `approved` $\rightarrow$ `awarded` transition, it consumes **0 additional slots** (both statuses occupy 1 slot in aggregate capacity).
   - Student withdrawal: transitions `draft`, `submitted`, or `under_review` $\rightarrow$ `withdrawn`, authorized under `application_student_update_boundary`. Inactive and pending withdrawals consume **0 slots**. Terminal states (`approved`, `rejected`, `awarded`) cannot be withdrawn by students.
3. **Trigger Bypass Defense**:
   - In `guard_application_workflow()`, the check:
     ```sql
     if current_user = pg_catalog.pg_get_userbyid((select proowner from pg_catalog.pg_proc
       where oid = 'public.review_application(uuid,text,text,jsonb,text)'::regprocedure)) then return new; end if;
     ```
     is strictly maintained so that security-definer internal writes are never blocked while client-initiated direct updates to workflow fields remain rejected (`42501`).

---

## 3. Core Features Technical Design

### Feature 1: Organization-Admin Sidebar Integration
1. **Sidebar Navigation Additions in `OrgProviderShell`**:
   - For authenticated users with `identity.isOrgAdmin`:
     - Under "Organization & Governance":
       - **Team & Reviewers** (Tab index 6): Opens `OrgTeamView` showing active staff roster and grant assignment modal.
       - **Activity Log** (Tab index 7): Opens `OrgActivityLogView` showing real-time deduplicated audit events.
   - Reuses existing shell layout, theme tokens (`#F5F5F7` sidebar, `#0F4D2E` active indicator), and tab switching mechanisms (`TabContentCrossFade`).
2. **Functional Completeness**:
   - Every added button maps directly to an active view or modal dialog; zero dead links, zero placeholder snackbars, and zero `window.alert()` calls.

---

### Feature 2: Scholarship Slot Capacity Accounting & Backend Aggregate Access

#### A. Status Occupancy & Mathematical Definition
* **Total Capacity**: Defined by `scholarships.slots`. If `slots IS NULL`, the scholarship is **Uncapped**.
* **Occupied Count**: Defined dynamically from live application records:
  $$\text{Occupied Slots} = \operatorname{COUNT}(*) \text{ WHERE scholarship\_id} = s.id \text{ AND status} \in ('approved', 'awarded')$$
* **Remaining Seats**:
  - If `slots IS NULL`: `null` (rendered in UI as **"Uncapped"**).
  - If `slots IS NOT NULL`: $\max(0, \text{slots} - \text{Occupied Slots})$.
* **Authoritative Lifecycle Rules**:
  - `draft`, `submitted`, `under_review`, and `withdrawn` (inactive/pending): Occupy **0 slots**. Withdrawing an application from a pending status consumes no slots and releases no slots, as pending applications never occupy capacity.
  - `approved`: Occupies **1 slot**.
  - `approved` $\rightarrow$ `awarded`: Net change is **0 slots** (both statuses belong to the occupied set). Executed exclusively by platform admin (`public.is_admin()`) under migration 0025; org admins retain approval/rejection authority only.
  - Terminal statuses: Under 0024/0025, students cannot withdraw `approved` applications. No arbitrary status reversals are invented.
  - Duplicate requests (calling `review_application` on an already approved application): Idempotently succeeds without double-incrementing.

#### B. Backend Aggregate Slot Access (Respecting Scholarship Visibility & Privacy)
* **The Problem**: Students cannot query `public.applications` for other applicants due to strict Row-Level Security (`user_id = auth.uid()`). A student client cannot perform `COUNT(*)` over another applicant's record.
* **The Solution**: Migration `0026` introduces a security barrier aggregate view that strictly **respects scholarship visibility**:
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
    -- Students and general users only see active/published scholarships
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
  - **Visibility Enforcement**: Ordinary students only see capacity for active scholarships (`s.is_active = true`). Draft or inactive scholarships created by providers are completely hidden from student capacity queries. Organization members and admins can view capacity for scholarships belonging to their organization.
  - Also exposes `public.get_scholarship_capacity(p_scholarship_id uuid)` with identical visibility checks.

#### C. Atomic PostgreSQL Enforcement
Inside `public.review_application(p_application_id, p_expected_status, p_action, p_scores, p_notes)`:
```sql
-- Lock the scholarship row to serialize concurrent approvals and eliminate race conditions
select * into s from public.scholarships where id = a.scholarship_id for update;

if p_action = 'approve' then
  if actor_role <> 'org_admin' then raise exception 'Only organization admins can decide' using errcode = '42501'; end if;
  if a.status <> 'under_review' or a.endorsed_by is null or a.endorsed_by = auth.uid()
    or not exists (select 1 from public.application_evaluations e where e.application_id = a.id
      and e.reviewer_id = a.endorsed_by and e.decision = 'endorsed') then
    raise exception 'A separate reviewer endorsement is required';
  end if;

  -- Capacity check (only for capped scholarships)
  if s.slots is not null then
    declare
      v_occupied int;
    begin
      select count(*) into v_occupied
      from public.applications
      where scholarship_id = s.id
        and status in ('approved', 'awarded')
        and id <> a.id;

      if v_occupied >= s.slots then
        raise exception 'Scholarship capacity reached. No slots remaining (%/% occupied).'
          , v_occupied, s.slots using errcode = 'P0001';
      end if;
    end;
  end if;

  target_status := 'approved';
  update public.applications set status = target_status, decided_by = auth.uid(), decided_at = now()
    where id = a.id;
```

#### D. Guard Against Capacity Reduction Below Occupied Count
When editing a scholarship (`UPDATE public.scholarships`):
```sql
create or replace function public.guard_scholarship_capacity() returns trigger
language plpgsql as $$
declare
  v_occupied int;
begin
  if new.slots is not null then
    select count(*) into v_occupied
    from public.applications
    where scholarship_id = new.id
      and status in ('approved', 'awarded');

    if new.slots < v_occupied then
      raise exception 'Cannot reduce total slots to %: % slots are currently occupied by approved scholars.'
        , new.slots, v_occupied using errcode = 'P0002';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_guard_scholarship_capacity on public.scholarships;
create trigger trg_guard_scholarship_capacity
  before update of slots on public.scholarships
  for each row execute function public.guard_scholarship_capacity();
```

#### E. Genuine Concurrency Tests on Isolated Local Database (Never Production Fixtures)
* **Strict Test Environment Boundary**:
  - All concurrency race condition tests must execute against an **isolated local PostgreSQL database** (e.g., local ephemeral test container or dedicated local Postgres test instance).
  - **NEVER run concurrency tests against production fixtures, remote staging, or shared demo accounts** (`demo_student@scholaris.ph`, `demo_provider@scholaris.ph`, Ayala Future Leaders Grant).
  - Test harnesses must create their own temporary test scholarships and mock applicants in `beforeAll` and tear them down in `afterAll`.
* **Harness Architecture**:
  - Implemented in `tools/test_organization_controls_security.mjs` using Node.js `pg` pool connecting as two distinct authenticated clients against the local test database.
  - Setup: Disposable test scholarship with `slots = 1` and two mock applications in `under_review` (both independently endorsed).
  - Concurrency Execution: Executes `Promise.all([connA.query('select review_application(...)'), connB.query('select review_application(...)')])`.
  - Assertions:
    1. Exactly one promise resolves successfully (HTTP 200 / SQL OK).
    2. Exactly one promise rejects with SQL error code `P0001`.
    3. `scholarship_capacities` verifies `occupied_slots = 1` and `remaining_slots = 0`.
    4. The rejected application remains intact in `under_review` without corrupted state.

---

### Feature 3: School Eligibility Architecture

#### A. Master Schools Catalog (Zero Arbitrary Rankings)
* **Design Philosophy**: Pre-populate a neutral, unranked seed set of 10 established Philippine universities commonly targeted by national and institutional scholarship programs, with zero arbitrary rankings or prestige tiers.
* **Table Schema (`public.schools`)**:
  ```sql
  create table public.schools (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    normalized_name text not null unique,
    aliases text[] not null default '{}',
    is_curated boolean not null default true, -- Seeded vs user-added; NOT a claim of student enrollment verification
    created_by uuid references auth.users(id),
    created_at timestamptz not null default now()
  );
  alter table public.schools enable row level security;
  create policy "Schools are readable by all authenticated users"
    on public.schools for select to authenticated using (true);
  ```
* **Pre-Populated 10 Seed Universities (Alphabetical / Neutral)**:
  1. `Adamson University` (aliases: `adamson`, `adu`)
  2. `Ateneo de Manila University` (aliases: `ateneo de manila`, `admu`, `ateneo`)
  3. `De La Salle University` (aliases: `de la salle`, `dlsu`, `la salle`)
  4. `Far Eastern University` (aliases: `feu`, `far eastern university`)
  5. `Mapúa University` (aliases: `mapua`, `mapua university`)
  6. `Pamantasan ng Lungsod ng Maynila` (aliases: `plm`, `pamantasan ng lungsod ng maynila`)
  7. `Polytechnic University of the Philippines` (aliases: `pup`, `polytechnic university`)
  8. `Technological University of the Philippines` (aliases: `tup`, `technological university`)
  9. `University of Santo Tomas` (aliases: `university of santo tomas`, `ust`)
  10. `University of the Philippines Diliman` (aliases: `up diliman`, `upd`, `up`)

#### B. Student School-Profile Migration & Editing
1. **Database Schema Expansion**:
   - `ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS school_id uuid REFERENCES public.schools(id);`
   - Existing `profiles.school text` column is **preserved** to prevent breaking legacy readers.
2. **Data Migration Backfill Script in Migration `0026`**:
   - For every existing student profile with non-null `school text`:
     - Computes normalized string: `v_norm := lower(trim(regexp_replace(school, '\s+', ' ', 'g')));`
     - Searches `public.schools` where `normalized_name = v_norm` or `v_norm = any(aliases)`.
     - If match found: updates `profiles.school_id = matched_school.id`.
     - If no match found: dynamically inserts a new uncurated school row (`is_curated = false`, `name = profiles.school`, `normalized_name = v_norm`) and links `profiles.school_id`.
3. **Student Profile Form Editing (`ProfileSetupScreen` & `ProfileTabScreen`)**:
   - The free-text field is upgraded to a searchable institution dropdown powered by `SchoolRepository`.
   - On selection, saves both `school_id` and the display text `school` (dual-write).
   - If a student's institution is unlisted, the student can use "+ Add School", creating an uncurated entry and immediately linking it.
   - Updating school on profile later does not retroactively withdraw submitted applications; eligibility is locked at submission timestamp, and grantors verify credentials against the submitted documents.

#### C. Searchable Multi-Select & "Add School" in Scholarship Form
* **Scholarship Form (`scholarship_form_screen.dart`)**:
  - Dual Radio/Toggle:
    - **"Open to all schools"** (Default, `eligible_school_ids = null`)
    - **"Restricted to selected schools"** (`eligible_school_ids = [uuid, ...]`)
  - When restricted:
    - Renders searchable multi-select field listing the 10 pre-populated universities.
    - If a school is not found in the search, an **"+ Add School"** tile is displayed.
    - RPC `public.add_custom_school(p_name text)` normalizes name, checks against existing `normalized_name` and `aliases`, returns the existing record if found (preventing duplicates), or inserts a new uncurated record (`is_curated = false`).

#### D. Backend Submission Enforcement
* **Column**: `public.scholarships.eligible_school_ids uuid[] default null`.
* **Submission Check in `guard_application_workflow()`**:
  ```sql
  -- On INSERT (as 'submitted') or UPDATE ('draft' -> 'submitted'):
  declare
    v_eligible_schools uuid[];
    v_student_school_id uuid;
  begin
    select s.eligible_school_ids into v_eligible_schools
    from public.scholarships s where s.id = new.scholarship_id;

    if v_eligible_schools is not null and array_length(v_eligible_schools, 1) > 0 then
      select p.school_id into v_student_school_id
      from public.profiles p where p.id = new.user_id;

      if v_student_school_id is null or not (v_student_school_id = any(v_eligible_schools)) then
        raise exception 'School eligibility requirement not met. This scholarship is restricted to designated partner institutions.'
          using errcode = 'P0003';
      end if;
    end if;
  end;
  ```

#### E. Truthful Verification Wording (Zero Synthetic Claims)
* **Strict Verification Policy**: Scholaris does NOT have an automated live API connection to university registrar databases. Therefore, the UI must NEVER claim a student or school is "Verified".
* **Standardized Copy**:
  - Student Profile: **"Student-Declared Enrolled Institution"** or **"Self-Declared Academic Information"**.
  - Detail Screen Pre-Submission Card:
    - If matched: **"Eligible based on declared profile (Matches: [School Name])"**.
    - If restricted: **"Restricted Grant: Open to students of [School 1, School 2, ...]"**.
    - If mismatched: **"Ineligible based on profile: Restricted to partner institutions."**
  - Verification Truth Disclosure: **"Academic enrollment is self-declared on your student profile and verified by scholarship administrators through your uploaded Certificate of Registration (COR) or Student ID."**

---

## 4. Migration & IPA Distribution Strategy

### A. Proposed vs. Applied Migrations
* **Migration File**: `supabase/migrations/0026_organization_controls_slots_schools.sql`.
* **Current State**: **PROPOSED LOCAL CODE ONLY**.
* **Non-Negotiable Gate**: Migration `0026` will **NOT** be pushed or applied to the remote Supabase staging/production instance until human approval is given.
* **Local Verification**: Unit and widget tests will execute against local mocks and schema definitions.

### B. Student-Facing Changes & iOS IPA Analysis
* **Web Consoles (Immediate)**:
  - Provider Console (`http://localhost:5001`) and Org Admin Console (`http://localhost:5002`) update immediately upon code compilation/run.
  - Student Web app updates immediately.
* **Physical iPhone with Pre-Installed IPA**:
  - **Backend Protection is Immediate**: If a student attempts to apply to a disallowed school or overbooked scholarship from the existing iOS app, Supabase immediately rejects the submission and displays the returned error message in the existing app snackbar.
  - **Visual Elements Require New IPA**: Any new mobile UI widgets (such as the school eligibility match indicator chip on mobile or the updated capacity display widget) are compiled into Flutter Dart bytecode. Rendering these new visual widgets on the physical iPhone will require building and signing an updated `.ipa`.

---

## 5. Worktree File Ownership & Commit Integration Sequence

### Baseline Commit Matrix & Worktree Status

| Worktree | Branch | Role | Baseline Hash | Sprint Status |
| :--- | :--- | :--- | :--- | :--- |
| `whelk` | `ai/architect` | 🧠 Architecture, Coordination & Planning | `7273934` | Active (Monitoring & Consolidation) |
| `cowrie` | `ai/builder` | 🔨 Backend, Migrations, Repositories & RPCs | `1964b55` | **Completed (`1964b556a0a56b3b1a3fdb6ab2e16e748655dd06`)** |
| `bowhead` | `ai/ui` | 🎨 Flutter UI, Apple HIG, Motion & Viewports | `f571672` | **Unlocked — Ready for Activation** |
| `fusilier` | `ai/security` | 🛡️ Supabase RLS, Privacy & Concurrency Tests | `68dcaba` | **Unlocked — Ready for Activation** |
| `cerith` | `ai/qa` | 🔍 Acceptance, Regression & E2E Verification | `7423c3e` | Gated on UI & Security Commits |

*Common Ancestor: `26094165d3824f8d75cf81c2069fa89487c80ee9`.*

### Worktree Execution Order & File Ownership

```
[Builder: cowrie] ──(1964b55)──┬──► [UI/UX: bowhead] ─────(commit hash)───┐
  (COMPLETED)                  │     (UNLOCKED)                            ▼
                               └──► [Security: fusilier] ──(report)──► [QA: cerith] ──► [Architect Final]
                                     (UNLOCKED)                         (GATED)
```

#### 1. 🔨 Builder (`cowrie` / `ai/builder`)
* **Task Card**: [`docs/tasks/org_controls_task_builder.md`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/whelk/docs/tasks/org_controls_task_builder.md)
* **Permitted Files**:
  - `supabase/migrations/0026_organization_controls_slots_schools.sql`
  - `lib/features/schools/models/school.dart`
  - `lib/features/schools/data/school_repository.dart`
  - `lib/features/schools/providers/school_provider.dart`
  - `lib/features/scholarships/models/scholarship_capacity.dart`
  - `lib/features/scholarships/data/scholarship_capacity_repository.dart`
  - `lib/features/scholarships/providers/scholarship_capacity_provider.dart`
  - `lib/features/provider/models/organization_activity_log.dart`
  - `lib/features/provider/models/organization_team_member.dart`
  - `lib/features/provider/models/scholarship_reviewer_assignment.dart`
  - `lib/features/provider/data/organization_activity_repository.dart`
  - `lib/features/provider/data/organization_team_repository.dart`
  - `lib/features/provider/providers/organization_activity_provider.dart`
  - `lib/features/provider/providers/organization_team_provider.dart`
  - `test/features/provider/organization_activity_repository_test.dart`
  - `test/features/provider/organization_team_repository_test.dart`
  - `test/features/schools/school_repository_test.dart`
  - `test/features/scholarships/scholarship_capacity_test.dart`
  - `docs/reports/2026-10-19_org_controls_builder_report.md`

#### 2. 🎨 UI/UX (`bowhead` / `ai/ui`)
* **Task Card**: [`docs/tasks/org_controls_task_ui.md`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/whelk/docs/tasks/org_controls_task_ui.md)
* **Permitted Files**:
  - `lib/features/provider/presentation/org/org_activity_log_view.dart`
  - `lib/features/provider/presentation/org/org_team_view.dart`
  - `lib/features/provider/presentation/org/widgets/assign_reviewer_dialog.dart`
  - `lib/features/provider/presentation/org/org_provider_shell.dart`
  - `lib/features/provider/presentation/org/org_scholarships_tab.dart` (slot badge & assign button)
  - `lib/features/provider/presentation/org/org_incoming_applications_tab.dart` ("Assigned to Me" chip)
  - `lib/features/provider/presentation/scholarship_form_screen.dart` (school multi-select + Add School)
  - `lib/features/scholarships/presentation/scholarship_detail_screen.dart` (truthful school eligibility guidance & slot capacity)
  - `lib/features/profile/presentation/profile_setup_screen.dart` (school dropdown selection)
  - `lib/features/profile/presentation/profile_tab_screen.dart` (school display & edit)
  - `test/features/provider/org_activity_log_ui_test.dart`
  - `test/features/provider/org_team_ui_test.dart`
  - `test/features/scholarships/school_eligibility_ui_test.dart`
  - `docs/reports/2026-10-19_org_controls_ui_report.md`

#### 3. 🛡️ Security (`fusilier` / `ai/security`)
* **Task Card**: [`docs/tasks/org_controls_task_security.md`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/whelk/docs/tasks/org_controls_task_security.md)
* **Permitted Files**:
  - `supabase/tests/organization_controls_security_test.sql`
  - `tools/test_organization_controls_security.mjs`
  - `test/features/provider/org_controls_security_test.dart`
  - `test/features/scholarships/school_security_test.dart`
  - `docs/reports/2026-10-19_org_controls_security_report.md`

#### 4. 🔍 QA (`cerith` / `ai/qa`)
* **Task Card**: [`docs/tasks/org_controls_task_qa.md`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/whelk/docs/tasks/org_controls_task_qa.md)
* **Permitted Files**:
  - `test/features/provider/organization_controls_e2e_test.dart`
  - `test/features/scholarships/school_eligibility_e2e_test.dart`
  - `scratch/verify_org_controls_state.mjs`
  - `docs/reports/2026-10-19_org_controls_qa_report.md`

---

## 6. Automated Monitoring & Scheduling Proof

1. **Native Scheduling Mechanism**:
   - The Architect uses the Antigravity native `schedule` tool:
     `schedule(CronExpression="*/5 * * * *", Prompt="Poll specialist branches for completion reports and consolidate progress", IsDaemon=false)`
   - This fires in the background every 5 minutes without blocking or polling loops.
2. **Active Task ID**:
   - Background monitoring task is active:
     - **Exact Task ID**: `de5a1e5e-acf2-405a-b418-7130d31eecb9/task-742`
     - **Cadence**: Every 5 minutes (`*/5 * * * *`)
3. **Self-Termination**:
   - The moment all 4 specialist reports are committed and consolidated, Architect calls `manage_task(Action="kill", TaskId=...)` to terminate the cron schedule cleanly.

---

## 7. Specialist Activation Messages & Task Retrieval Protocol

### 🔨 1. Builder in `cowrie` (`ai/builder`):
* **Sprint Status**: `COMPLETED`
* Completed Commit: [`1964b556a0a56b3b1a3fdb6ab2e16e748655dd06`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/whelk/docs/reports/2026-10-19_org_controls_builder_report.md)
* Completed Report: [`docs/reports/2026-10-19_org_controls_builder_report.md`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/whelk/docs/reports/2026-10-19_org_controls_builder_report.md)
* All unit tests passed (30/30 tests passed, 0 analyzer errors).

---

### Safe Task-File Retrieval Protocol for Specialists
> [!WARNING]
> **Preserve Local Modifications Before Retrieval**:  
> Running `git status && git checkout` does not prevent file replacement because `git status` exits with `0`.  
> Before retrieving updated files from `ai/architect`, always inspect working tree status (`git status --short docs/plans/ docs/tasks/`). If any planning or task files contain uncommitted local edits, preserve them (e.g. `git stash push -m "local-task-backup" docs/plans/ docs/tasks/` or copy to `.bak`) before checkout.  
> Using `git diff --exit-code <files> && git checkout ai/architect -- <files>` ensures that if local modifications exist, the command halts and outputs the diff rather than clobbering your changes.

---

### 🎨 2. Trigger UI/UX in `bowhead` (UNLOCKED):
```text
> execute assigned task

Inspect working tree and preserve any modified planning files before retrieval:
git diff --exit-code docs/plans/2026-10-19_organization_admin_controls_plan.md docs/tasks/org_controls_task_ui.md && git checkout ai/architect -- docs/plans/2026-10-19_organization_admin_controls_plan.md docs/tasks/org_controls_task_ui.md
# (If local edits are detected, git diff halts with exit code 1 to protect your work. Preserve files via stash or backup, then checkout)

Integrate Builder's completed commit hash:
git merge --no-edit 1964b556a0a56b3b1a3fdb6ab2e16e748655dd06

Implement presentation layer:
1. OrgProviderShell: Add Activity Log and Team & Reviewers to Org Admin sidebar.
2. OrgActivityLogView and OrgTeamView with AssignReviewerDialog.
3. ScholarshipFormScreen: School eligibility (Open to all vs Restricted to selected schools with 10 pre-populated universities + Add School modal).
4. ProfileSetupScreen & ProfileTabScreen: School dropdown selection with dual-write to school_id and school.
5. Slot capacity badges displaying total, occupied, and remaining seats derived from scholarship_capacities view (respecting visibility; pending withdrawals consume 0 slots).
6. ScholarshipDetailScreen: Truthful school eligibility guidance card & self-declared attendance disclosure.
Verify viewports at 360px, 440px, and 1280px with zero browser alerts.
Write report to docs/reports/2026-10-19_org_controls_ui_report.md, output your commit hash, and commit to ai/ui.
```

### 🛡️ 3. Trigger Security in `fusilier` (UNLOCKED):
```text
> execute assigned task

Inspect working tree and preserve any modified planning files before retrieval:
git diff --exit-code docs/plans/2026-10-19_organization_admin_controls_plan.md docs/tasks/org_controls_task_security.md && git checkout ai/architect -- docs/plans/2026-10-19_organization_admin_controls_plan.md docs/tasks/org_controls_task_security.md
# (If local edits are detected, git diff halts with exit code 1 to protect your work. Preserve files via stash or backup, then checkout)

Integrate Builder's completed commit hash:
git merge --no-edit 1964b556a0a56b3b1a3fdb6ab2e16e748655dd06

Execute automated security & genuine concurrency test matrix:
1. Genuine parallel concurrency test on ISOLATED LOCAL DATABASE (never production fixtures): two simultaneous connections executing review_application('approve') on last slot; exactly one succeeds, one fails with P0001.
2. Capacity reduction constraint test (reject lowering slots below occupied count with P0002).
3. Backend aggregate slot access test (verify scholarship visibility is respected and students cannot read inactive grant capacities or other applicants' data).
4. Authoritative 0024/0025 permissions audit: confirm inactive/pending withdrawals consume 0 slots, and approved applications cannot be withdrawn by students.
5. School eligibility submission bypass test (backend rejects non-matching school with P0003).
6. School deduplication test in add_custom_school().
7. Column minimization & student isolation on get_organization_roster().
8. Cross-org isolation on activity logs and reviewer assignments.
Write report to docs/reports/2026-10-19_org_controls_security_report.md, output commit hash, and commit to ai/security.
```

### 🔍 4. Trigger QA in `cerith` (After UI & Security Commit):
```text
> execute assigned task

Inspect working tree and preserve any modified planning files before retrieval:
git diff --exit-code docs/plans/2026-10-19_organization_admin_controls_plan.md docs/tasks/org_controls_task_qa.md && git checkout ai/architect -- docs/plans/2026-10-19_organization_admin_controls_plan.md docs/tasks/org_controls_task_qa.md
# (If local edits are detected, git diff halts with exit code 1 to protect your work. Preserve files via stash or backup, then checkout)

Integrate completed Builder and UI commit hashes:
git merge --no-edit 1964b556a0a56b3b1a3fdb6ab2e16e748655dd06
git merge --no-edit <UI_COMMIT_HASH>

Inspect Security's report: docs/reports/2026-10-19_org_controls_security_report.md.
Confirm Security executed concurrency tests exclusively against an isolated local database (zero production/demo fixture tampering).
Do not mark VERIFIED if Security reports any unresolved vulnerability.

Execute acceptance and regression test suite:
1. Main acceptance cycle: Student submission -> Reviewer endorsement -> Org-admin decision -> Student notification.
2. Platform-admin awarding regression: Test platform-admin awarding (approved -> awarded under migration 0025) separately as regression coverage with 0 additional slots consumed.
3. Slot accounting: Last slot reservation, duplicate decision idempotency, inactive/pending withdrawals consume 0 slots, uncapped grant capacity.
4. Capacity visibility: Confirm capacity queries respect scholarship visibility (inactive grants hidden from students).
5. School eligibility: Allowed school submission success, disallowed school rejection, missing school handling, legacy data compatibility.
6. Student profile school editing and truthful wording audit across UI.
7. Full regression: flutter test test/features/applications/transaction_cycle_test.dart.
Write completion report to docs/reports/2026-10-19_org_controls_qa_report.md and commit to ai/qa.
```

---

> [!IMPORTANT]
> **GATE STATUS: COORDINATION RESUMED — BUILDER RE-VERIFIED; UI/UX & SECURITY UNLOCKED**  
> Coordination resumed per operator instruction.  
> 1. Background monitoring is running under Task ID `de5a1e5e-acf2-405a-b418-7130d31eecb9/task-742` (`*/5 * * * *`).  
> 2. Builder (`cowrie`) implementation (`a57f1de`) and report (`1964b55`) verified with 30/30 unit tests passing and 0 analyzer errors.  
> 3. UI/UX (`bowhead`) and Security (`fusilier`) triggers are unlocked and pinned to verified Builder commit `1964b556a0a56b3b1a3fdb6ab2e16e748655dd06`.  
> 4. QA (`cerith`) remains strictly gated until UI/UX and Security completion reports are delivered.  
> 5. Remote migrations, final merging, deployment, and IPA builds remain strictly prohibited pending separate explicit approval.
