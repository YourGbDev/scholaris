# Task Card: UI/UX (`bowhead` / `ai/ui`)

**Sprint:** Organization-Admin Controls, Capacity Accounting & School Eligibility (Phase 1)  
**Role:** 🎨 Flutter UI, Apple HIG & Responsive Layout Specialist  
**Worktree Path:** `C:/Users/Windows 11/orca/workspaces/scholaris/bowhead`  
**Active Branch:** `ai/ui`  
**Baseline Commit:** `f5716726d44a4f8d3c724a80e36147bfb493a3e9`  
**Reference Plan:** `docs/plans/2026-10-19_organization_admin_controls_plan.md`  
**Status:** `AWAITING ACTIVATION (HUMAN APPROVAL GATE)`

---

## 1. Objective
Design and implement the presentation layer for:
1. **Org-Admin Sidebar Controls**: Functional Activity Log View and Team & Reviewers View in `OrgProviderShell`.
2. **Scholarship Slot Accounting UI**: Clear display of total, occupied, and remaining seats consuming authoritative backend aggregate capacity (`scholarship_capacities` view respecting scholarship visibility; inactive/pending withdrawals consume zero slots); clean in-app error feedback when capacity is reached.
3. **School Eligibility Interface**:
   - In `ScholarshipFormScreen`: "Open to all schools" vs. "Restricted to selected schools" multi-select dropdown with 10 neutral pre-populated universities (zero arbitrary rankings) + "+ Add School" dialog.
   - In `ProfileSetupScreen` and `ProfileTabScreen`: Upgrade student school text field to searchable dropdown with dual-write (`school_id` and `school`).
   - In `ScholarshipDetailScreen`: Pre-submission eligibility guidance card and **truthful verification wording** disclosing self-declared status.

---

## 2. Permitted Files
- `lib/features/provider/presentation/org/org_activity_log_view.dart` (new)
- `lib/features/provider/presentation/org/org_team_view.dart` (new)
- `lib/features/provider/presentation/org/widgets/assign_reviewer_dialog.dart` (new)
- `lib/features/provider/presentation/org/org_provider_shell.dart` (Org Admin sidebar navigation items)
- `lib/features/provider/presentation/org/org_scholarships_tab.dart` (slot badge & reviewer assign button)
- `lib/features/provider/presentation/org/org_incoming_applications_tab.dart` ("Assigned to Me" filter chip)
- `lib/features/provider/presentation/scholarship_form_screen.dart` (school multi-select + Add School modal)
- `lib/features/scholarships/presentation/scholarship_detail_screen.dart` (truthful school eligibility guidance & slot capacity)
- `lib/features/profile/presentation/profile_setup_screen.dart` (school dropdown selection)
- `lib/features/profile/presentation/profile_tab_screen.dart` (school display & edit)
- `test/features/provider/org_activity_log_ui_test.dart` (new)
- `test/features/provider/org_team_ui_test.dart` (new)
- `test/features/scholarships/school_eligibility_ui_test.dart` (new)
- `docs/reports/2026-10-19_org_controls_ui_report.md` (deliverable report)

**Explicitly Forbidden**: Writing database migrations, editing authentication redirect gates, or using `window.alert()`.

---

## 3. Installed Workspace Design Skills (Exact Absolute Paths)
You MUST load and apply the 5 installed skills in `.agents/skills/`:
1. `animate`: `C:\Users\Windows 11\orca\workspaces\scholaris\whelk\.agents\skills\animate\SKILL.md`
2. `apple-design`: `C:\Users\Windows 11\orca\workspaces\scholaris\whelk\.agents\skills\apple-design\SKILL.md`
3. `emil-apple-design`: `C:\Users\Windows 11\orca\workspaces\scholaris\whelk\.agents\skills\emil-apple-design\SKILL.md`
4. `emil-design-eng`: `C:\Users\Windows 11\orca\workspaces\scholaris\whelk\.agents\skills\emil-design-eng\SKILL.md`
5. `review-animations`: `C:\Users\Windows 11\orca\workspaces\scholaris\whelk\.agents\skills\review-animations\SKILL.md`

---

## 4. Integration Requirement: Commit-Based Ingestion
Do NOT merge an unfinished branch tip. Wait until Builder commits their completed implementation and provides their exact commit hash `<BUILDER_COMMIT_HASH>`. Integrate using:
```bash
git merge --no-edit <BUILDER_COMMIT_HASH>
```

---

## 5. UI Specification Details

### A. Sidebar Navigation Additions (`org_provider_shell.dart`)
- For `identity.isOrgAdmin`:
  - Add **"Team & Reviewers"** (Tab index 6) opening `OrgTeamView`.
  - Add **"Activity Log"** (Tab index 7) opening `OrgActivityLogView`.
- Match existing Apple design DNA: `#F5F5F7` sidebar, `#0F4D2E` active indicator, responsive drawer for mobile viewports.

### B. Slot Capacity UI from Backend Aggregate (`scholarship_capacities`)
- Consume `scholarshipCapacityProvider` which reads `public.scholarship_capacities` (inherits scholarship visibility; inactive scholarships hidden from students).
- **Capacity Badges**:
  - Show total, occupied, and remaining seats clearly:
    - `"25 total • 1 occupied • 24 remaining"` (or `"24 of 25 slots remaining"` with progress bar).
    - If uncapped (`is_uncapped == true`): `"Uncapped capacity • 1 scholar approved"`.
  - Note: Pending applications and student withdrawals consume 0 slots. Only `approved` and `awarded` consume 1 slot.
- **In-App Error Handling**:
  - When an admin attempts to approve an applicant for an overbooked scholarship:
    - Display error snackbar / banner inside the app: `"Cannot approve: Scholarship capacity reached."`
    - Invalidate capacity and application providers so the latest live numbers render immediately.

### C. School Eligibility in Scholarship Creation (`scholarship_form_screen.dart`)
- Radio/Segmented Control:
  - **"Open to all schools"** (Default).
  - **"Restricted to selected schools"**.
- When restricted:
  - Display searchable multi-select dropdown populated with the 10 pre-populated universities from `SchoolRepository` (unranked, neutral presentation).
  - Search field filters the list smoothly.
  - If a user types a school not in the list, show an **"+ Add School"** tile.
  - Clicking "+ Add School" opens a modal dialog allowing the provider to enter the institution name and submit via `SchoolRepository.addSchool()`.
  - Selected schools appear as dismissible chips with university icons.

### D. Student Profile School Editing (`profile_setup_screen.dart` & `profile_tab_screen.dart`)
- Replace the raw school text field with a searchable dropdown populated by `SchoolRepository.fetchSchools()`.
- On selection, saves both `school_id` and the display text `school` (dual-write).
- If the student's institution is unlisted, the student can use "+ Add School", creating an uncurated entry and immediately linking it.

### E. Truthful Verification Wording (`scholarship_detail_screen.dart`)
- **Strict Verification Policy**: Zero false claims of "Verified School" or "Verified Student".
- Standardized Copy:
  - Header / Label: **"Self-Declared Academic Information"** or **"Student-Declared Enrolled Institution"**.
  - Match Guidance:
    - Match: Green badge **"Eligible based on declared profile (Matches: [School Name])"**.
    - Ineligible: Amber badge **"Ineligible based on profile: Restricted to partner institutions."** with Apply button disabled.
  - Truth Disclosure:
    - **"Academic enrollment is self-declared on your student profile and verified by scholarship administrators through your uploaded Certificate of Registration (COR) or Student ID."**

---

## 6. Responsive Viewport Verification Matrix
Validate zero `RenderFlex overflow` across:
1. **Narrow Mobile**: 360×800
2. **Large Mobile**: 440×956
3. **Desktop**: 1280×800

---

## 7. Deliverable Report & Commit Hash
Commit report and code to `ai/ui`:
- Report: `docs/reports/2026-10-19_org_controls_ui_report.md`
- Output the exact commit hash `<UI_COMMIT_HASH>` in the report header so QA can integrate against it.
