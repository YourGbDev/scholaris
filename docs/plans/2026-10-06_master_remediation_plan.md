# Scholaris Master Remediation Plan (UI/UX Audit Triage)

**Plan Reference:** `docs/plans/2026-10-06_master_remediation_plan.md`  
**Creation Date:** October 6, 2026  
**Architect:** 🧠 `ai/architect` (`whelk`)  
**Source Audit:** `docs/reports/2026-10-06-full-ui-ux-audit.md` (Commit `3566429`)  
**Status:** `STATUS: AWAITING HUMAN APPROVAL`

---

## 1. Executive Summary

A comprehensive architectural triage was conducted on the **46 findings** documented in the October 6, 2026 Scholaris UI/UX Comprehensive Audit. 

While the Scholaris frontend exhibits an ambitious visual identity anchored in Philippine education financing (Stitch design tokens, `LiquidGlass` acrylic surfaces, and Google Fonts Outfit/Poppins), the audit uncovered **critical disconnects** between presentation and functionality:
1. Valid Philippine GPA grades (such as `1.25` or `88.5%`) are rejected by a hardcoded domain validator (`gpa < 1.0 || gpa > 4.0`), trapping students in onboarding.
2. Direct navigation actions trigger non-existent routes (e.g. `/profile-setup/location`), crashing to the 404 handler.
3. Multiple profile cards and application submission views render simulated, hardcoded "Verified" badges without binding to live database records, violating `GEMINI.md` Section 5.
4. Key discovery controls and support recovery buttons contain empty no-op closures (`onTap: () {}`).
5. Multi-nested `BackdropFilter` layers in `LiquidGlass` cause GPU rasterization bottlenecks on mid-range Android devices.

This Master Remediation Plan organizes all 46 findings into **six sequential, dependency-aware workstreams**, assigns clear responsibilities across our four specialist worktrees (**🔨 Builder**, **🎨 UI/UX**, **🔍 QA**, and **🛡️ Security**), and establishes strict verification criteria.

---

## 2. Audit Findings Triage & Classification

The 46 findings are triaged into eight functional domains:

| Domain | Finding Count | Critical (P0) | High (P1) | Medium (P2) | Low (P3) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Domain & Data Integrity** | 6 | 2 | 2 | 2 | 0 |
| **Routing & Navigation** | 4 | 1 | 1 | 2 | 0 |
| **Buttons & Interaction Dead-Ends**| 5 | 0 | 3 | 2 | 0 |
| **Responsive & Flex Layouts** | 6 | 0 | 3 | 2 | 1 |
| **Rendering & Performance** | 4 | 0 | 2 | 2 | 0 |
| **Design System & Visual Craft** | 7 | 0 | 1 | 4 | 2 |
| **Accessibility (WCAG 2.1 AA)** | 6 | 0 | 3 | 3 | 0 |
| **Microcopy & Native Conventions**| 8 | 0 | 0 | 4 | 4 |
| **Total** | **46** | **3** | **15** | **21** | **7** |

---

## 3. Remediation Workstreams

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SCHOLARIS REMEDIATION WORKSTREAMS                        │
├─────────────────────────────────────────────────────────────────────────────┤
│ WS-1: Critical Blockers & Domain Integrity (P0)                             │
│   ├── GPA scale validation & matching semantics                             │
│   ├── Fix broken /profile-setup/location navigation                         │
│   ├── Purge hardcoded fake verification badges                              │
│   └── Network timeout & explicit error recovery states                      │
├─────────────────────────────────────────────────────────────────────────────┤
│ WS-2: Core Transaction & Interaction Dead-Ends (P1)                         │
│   ├── Wire Discovery filter chips (Match >90%, stipend brackets)            │
│   ├── Recommender draft persistence across navigation                       │
│   ├── Identity photo requirement upfront alignment                          │
│   └── Support recovery bottom sheet on VerifyEmailScreen                    │
├─────────────────────────────────────────────────────────────────────────────┤
│ WS-3: Mobile Responsive Layouts & Touch Targets (P1)                        │
│   ├── Floating bottom nav bar scaling on 320px–360px viewports              │
│   ├── Touch target expansion to 44×44pt on sheet dismissals and icons       │
│   ├── Keyboard inset padding and obscured CTA resolution                    │
│   └── Provider evaluation rubric RenderFlex overflow fix                    │
├─────────────────────────────────────────────────────────────────────────────┤
│ WS-4: Rendering Performance & Motion Restraint (P2)                         │
│   ├── Optimize LiquidGlass GPU overdraw (opacity fallback for low-spec)     │
│   ├── Tab entry animation caching (eliminate repetitive 15-item stagger)    │
│   └── Unified spring physics (AppMotion.springCurve & PressableScale)       │
├─────────────────────────────────────────────────────────────────────────────┤
│ WS-5: Design System & Visual Hierarchy (P2)                                 │
│   ├── Standardize corner radii to 4 semantic tokens (8, 14, 20, 999)        │
│   ├── Provider portal styling unification (Stitch design tokens)            │
│   └── Currency and metric compact formatting (₱150k/yr via FittedBox)       │
├─────────────────────────────────────────────────────────────────────────────┤
│ WS-6: Accessibility, Semantics & Microcopy (P2/P3)                          │
│   ├── WCAG AA contrast fixes (light glass borders, error text, gold text)   │
│   ├── Screen reader semantic labels on icon buttons and doodle avatars      │
│   ├── Pull-to-refresh indicator on Applications tracker                     │
│   └── Microcopy tone elevation (replace AI jargon with authentic copy)      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Architectural Analysis of High-Risk Findings

### 4.1. Finding 3.2.1: Philippine GPA Scale Validation & Matching Semantics
* **Codebase Reality**:
  - `ProfileValidator.validateGpa(double? gpa)` (`profile_validator.dart:88`) hardcodes `gpa < 1.0 || gpa > 4.0`.
  - In `ProfileSetupScreen`, students can pick `"1.0 – 5.0 (PH Standard)"` or `"Percentage (%)"`.
  - In `MatchingEngine.failedCriteria` (`matching_engine.dart:36`), the check is `student.gpa < scholarship.minGpa`.
  - *Conflict*: On a Philippine 1.0–5.0 scale, `1.0` is the highest honor (equivalent to 4.0 or 100%) and `5.0` is failing. If a student with `1.25` applies for a scholarship with `minGpa: 1.75`, standard numeric comparison `1.25 < 1.75` incorrectly flags the student as failed!
* **Architectural Remedy**:
  1. Expand `ProfileValidator.validateGpa` to accept the selected `GpaScale` enum:
     - `GpaScale.fourPoint`: `1.0 <= gpa <= 4.0`
     - `GpaScale.fivePoint`: `1.0 <= gpa <= 5.0`
     - `GpaScale.percentage`: `60.0 <= gpa <= 100.0`
  2. Normalize stored GPA or add scale-aware comparison to `MatchingEngine`:
     - If `scholarship.gpaScale == GpaScale.fivePoint`, student passes if `student.gpa <= scholarship.minGpa`.
     - If `scholarship.gpaScale == GpaScale.fourPoint`, student passes if `student.gpa >= scholarship.minGpa`.
* **Lead Role**: 🔨 Builder (validation & matching engine) + 🔍 QA (unit tests).

### 4.2. Finding 3.2.2: Broken Route `/profile-setup/location`
* **Codebase Reality**:
  - `profile_tab_screen.dart:686` calls `context.go('/profile-setup/location')`.
  - `router.dart:455-474` only defines `personal`, `academic`, and `financial`.
  - Location attributes (`region`, `province`, `cityMunicipality`) are rendered in Step 3 (`financial`).
* **Architectural Remedy**:
  - Do NOT invent a redundant 4th step in the wizard.
  - Route the edit badge to `/profile-setup/financial?focus=location`, or open an in-place `LocationEditSheet`.
* **Lead Role**: 🔨 Builder + 🎨 UI/UX.

### 4.3. Finding 3.2.3: Purging Hardcoded Fake Badges
* **Codebase Reality**:
  - `profile_tab_screen.dart:572, 599, 769, 935, 978` renders hardcoded text: `"STEM Priority • CHED Category A"`, `"True Copy of Grades (TCG) Validated ✓"`, `"BIR 2316 Verified"`, `"First-Generation College Scholar"`.
  - This violates Section 5 of `GEMINI.md` (*"Never render placeholder or mock data as completed user state"*).
* **Architectural Remedy**:
  - Bind each badge directly to `profile` attributes.
  - If a document is missing or unverified, display a neutral badge: `"TCG Required • Tap to upload"` or `"Income Document Unverified"`.
* **Lead Role**: 🎨 UI/UX + 🔨 Builder.

---

## 5. Implementation Sequence & Dependencies

```
[Phase 1: WS-1 (Blockers & Integrity)]
  │ 1.1 Fix GPA Validation & Scale Logic
  │ 1.2 Fix Profile Location Route
  │ 1.3 Purge Hardcoded Verification Badges
  │ 1.4 Network Timeout & Retry States
  ▼
[Phase 2: WS-2 & WS-3 (Flows, Layout & Touch Targets)]
  │ 2.1 Wire Discovery Filter Chips
  │ 2.2 Recommender Draft Persistence
  │ 2.3 Upfront Avatar Photo Requirements
  │ 2.4 Floating Nav Bar Responsive Scaling
  │ 2.5 Expand Touch Targets (min 44×44pt)
  │ 2.6 Fix Rubric Flex Overflow
  ▼
[Phase 3: WS-4 & WS-5 (Performance & Design System)]
  │ 3.1 LiquidGlass Opacity Fallback
  │ 3.2 Dashboard Animation Caching
  │ 3.3 Corner Radius & Typography Unification
  │ 3.4 Compact Currency Formatter
  ▼
[Phase 4: WS-6 (Accessibility & Microcopy)]
  │ 4.1 Contrast Adjustments (WCAG AA)
  │ 4.2 Semantic Screen Reader Labels
  │ 4.3 Tracker Pull-to-Refresh
  │ 4.4 Authentic Microcopy Polish
```

---

## 6. Role Assignment Matrix

| Workstream | 🔨 Builder | 🎨 UI/UX | 🔍 QA | 🛡️ Security |
| :--- | :--- | :--- | :--- | :--- |
| **WS-1: Critical Blockers** | Lead (Validator, Router, Models) | Support (Live Badges) | Independent Test (P0 Edge cases) | Audit (Profile schema & integrity) |
| **WS-2: Core Flow Gaps** | Lead (Chips, Draft Riverpod) | Lead (Support Sheet, Photo dialog) | Test (State persistence) | Audit (Email recovery flow) |
| **WS-3: Layout & Responsive** | Support (Form Insets) | Lead (Nav pill, Rubric, 44pt targets) | Viewport Test (320px, 440px, 1280px) | N/A |
| **WS-4: Performance & Motion** | Support (Animation caching) | Lead (LiquidGlass, spring physics) | FPS & Frame-drop audit | N/A |
| **WS-5: Design System** | Support (Tokens) | Lead (Radii, Stitch components) | Visual regression check | N/A |
| **WS-6: A11y & Content** | Support (Pull-to-refresh) | Lead (Contrast, Semantics, Copy) | Screen reader & WCAG check | Audit (Sensitive wording) |

---

## 7. Database, Schema & RLS Implications

* **Schema Migrations**:
  - If we introduce an explicit `gpa_scale` column to `public.profiles`, a Supabase migration (`0023_profile_gpa_scale.sql`) is required.
  - *Recommendation*: To keep Increment 3 lightweight, we can store normalized GPA in `profiles.gpa` while adding client-side scale conversion, avoiding schema migration unless required.
* **RLS Policies**:
  - No weakening of existing RLS policies (`0018`, `0019`, `0022`).
  - Provider access remains strictly scoped through `public.provider_applicant_profiles`.
* **Human Approval**: Any proposed `.sql` migration requires explicit human approval before being executed.

---

## 8. Definition of Done

A remediation workstream is complete only when:
1. All target files are modified strictly according to the task card.
2. `flutter analyze` passes with zero errors on modified paths.
3. Relevant unit/widget tests in `test/` execute with exit code 0.
4. UI has been verified on narrow mobile (320px–360px) and desktop (1280px) without `RenderFlex` overflows.
5. All completion indicators bind to live database records (zero synthetic mocks).
6. Independent verification reports are produced by QA and Security.
7. Verification status is marked `VERIFIED` based on concrete test output.

---

## 9. Task Card Assignments

The task cards have been populated for specialist execution upon approval:

* **🔨 Builder**: [`docs/tasks/task_builder.md`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/whelk/docs/tasks/task_builder.md) (WS-1, WS-2 domain logic, validation, router, draft state)
* **🎨 UI/UX**: [`docs/tasks/task_ui.md`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/whelk/docs/tasks/task_ui.md) (WS-2, WS-3, WS-4, WS-5, WS-6 layouts, design skills, touch targets, badges)
* **🔍 QA**: [`docs/tasks/task_qa.md`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/whelk/docs/tasks/task_qa.md) (P0 validation tests, viewport checks, edge cases)
* **🛡️ Security**: [`docs/tasks/task_security.md`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/whelk/docs/tasks/task_security.md) (Profile integrity, RLS verification, RA 10173 compliance)

---

## 10. Coordination State

```text
STATUS: AWAITING HUMAN APPROVAL
The master remediation plan and specialist task cards have been formulated.
Execution will NOT begin until the Human Tech Lead approves this plan.
```
