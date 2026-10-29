# Scholaris UI Audit: Organization Providers, Individual Providers & Super-Admin Workspace

**Date:** October 24, 2026 (Asia/Manila)  
**Target:** Local working tree `C:/scholaris`, branch `fix/touch-targets-oct02`  
**Scope:** UI presentation, accessibility, visual hierarchy, honest data labels, typography, and browser runtime stability. (Zero backend / SQL / migration changes).

---

## Skills Applied

- **Superpowers:** `using-superpowers`, `brainstorming`, `writing-plans`, `executing-plans`, `systematic-debugging`, `test-driven-development`, `verification-before-completion`, `ponytail`.
- **Apple Design & Apple HIG:**
  - `accessibility.md` › Vision: 200% Dynamic Type text scaling, WCAG AA contrast (≥ 4.5:1 for normal text, ≥ 3:1 for large text), touch targets (≥ 44×44 pt).
  - `layout.md` › Visual hierarchy: Progressive disclosure, order content by relative importance, distinct control appearance.
  - `typography.md` › System font scales, single harmonious typeface hierarchy across sibling tabs.
  - `color.md` › Purposeful semantic tinting, light/dark appearance, no reliance on color alone.
  - `buttons.md` › Style & Role: Prominent visual style (`FilledButton`) for the primary action; style—not size—to differentiate hierarchy; hit regions.
  - `sidebars.md` › Desktop sidebar reachability, scrollable navigation on compact/large text heights.
  - `feedback.md` › Truthful state representation, actionable error recovery, deliberate empty states.
  - `cross-platform.md` › Flutter widget equivalents (`Scaffold`, `TextScaler`, `FilledButton`, `Semantics`).
- **Emil Kowalski Design Engineering:**
  - Responsive button press feedback (`PressableScale` / scale `0.97` on press).
  - Unseen details compound; avoid jarring scale(0) transitions.
  - UI animation durations under 300ms; instant response under `prefers-reduced-motion`.
- **Scholaris Brand Identity (Anti-Clone Rule):**
  - Filipino scholarship matching platform identity: Deep green (`#0F4D2E`), warm gold accents (`#E5A823`), clean institutional surfaces, honest data labels (no fake "escrow", "verified funds", or "zero error" claims).

---

## Prioritized Audit Findings

### Priority 1 (High): Super-Admin Overview Priority Queue Cards
- **Issue**: In `lib/admin/widgets/admin_review_priorities.dart`, the priority queue cards ("Needs your attention") are visually loose (20px uniform padding), lack visual distinction between status badges and context, and utilize `OutlinedButton` (tertiary styling) for primary operator tasks (Review Providers, Review Safety Reports).
- **HIG / Design Violation**: `buttons.md › Style`: The most likely/important action in a view must carry prominent visual styling. An `OutlinedButton` signals low priority or secondary choice.
- **Concrete Fix**:
  1. Refine card density to 18px padding with rounded container borders (`kAdminHairline`).
  2. Add an explicit status pill / badge at the top (e.g., green container for Provider reviews, alert-tinted container for Urgent Safety reports) containing an icon and clear count.
  3. Change the action button from `OutlinedButton` to a prominent `FilledButton.icon` (Scholaris green `#0F4D2E` for providers, alert coral/amber `#9A3412` / `#8E3428` for urgent reports) with arrow icon and high-contrast text.
  4. Display structured context (e.g., "X organizations · Y individuals pending" or "X urgent reports · Y distinct reporters") using clean tabular hierarchy.

### Priority 2 (High): Distinguishing Provider Applications from Student Scholarship Applications
- **Issue**: Multiple admin destinations use the unqualified word "Applications":
  - `lib/admin/screens/applications_oversight_screen.dart` has header "Applications Oversight" with subtitle "$totalCount applications on platform".
  - `lib/admin/widgets/admin_review_priorities.dart` refers to "pending provider applications".
  - `lib/features/admin/presentation/admin_home_screen.dart` lists "Student applications" in sidebar.
- **Confusion**: Admins cannot immediately distinguish between **Provider Onboarding/Accreditation Applications** and **Student Scholarship Applications**.
- **Concrete Fix**:
  1. Header in `applications_oversight_screen.dart` updated to "Student Applications Oversight" with subtitle "$totalCount student applications across all listed programs".
  2. Provider approvals screens and cards explicitly labelled "Provider Registration Applications" or "Provider Approvals".
  3. Overview priorities clearly state "Pending provider registrations" vs "Student scholarship applications".

### Priority 3 (High): Typography & Data Label Inconsistencies Across Sibling Admin Tabs
- **Issue 3a (Font Inconsistency)**: In `lib/admin/screens/disbursements_oversight_screen.dart` (line 335), the screen title uses `GoogleFonts.newsreader` (a serif typeface). All other screens use `Inter` / `Outfit` / `GoogleFonts.outfit`.
  - **HIG Violation**: `typography.md`: Inconsistent typeface styles across sibling tabs create visual noise and degrade institutional credibility.
  - **Fix**: Standardize on `seqHeadlineLg` / `adminHeaderStyle` (`Inter` / `Outfit` sans-serif).
- **Issue 3b (False Claim in Scholarships Tab)**: In `lib/features/admin/presentation/admin_scholarships_tab.dart` (line 388), the committed capital card displays `badge: 'Verified Funds'`. Scholaris is a matchmaking and disbursement tracking platform, not an escrow bank holding verified funds.
  - **Violation**: Zero synthetic states / live data integrity rule.
  - **Fix**: Change badge to "Listed Value" and subtitle to "Sum of stated program amounts; not escrow or paid funds".
- **Issue 3c (Unstyled Empty States in Safety Tab)**: In `lib/admin/screens/reports_safety_screen.dart`, empty results display a plain, uncentered `Text('No reports match these filters.')` without container or clear action.
  - **Fix**: Provide a dedicated squircle empty state card matching `AdminTheme` and `StateViews`.

### Priority 4 (High): Browser Focus & Semantics Assertions (`WidgetsBindingObserver.didChangeViewFocus`)
- **Issue**: During browser viewport changes and tab switches, the development console emitted `RenderBox was not laid out: RenderSemanticsAnnotations` during `WidgetsBindingObserver.didChangeViewFocus`.
- **Root Cause**: In `OrgWorkspaceTransition` (`lib/features/provider/presentation/widgets/org_workspace_transition.dart`), `layoutBuilder` dynamically wraps outgoing transition children in `ExcludeFocus` and `ExcludeSemantics` inside the `AnimatedSwitcher` stack. When the browser focus shifts during an ongoing transition, the semantics tree traversal encounters the outgoing subtree whose render objects have not completed layout in that microtask. Additionally, `_SidebarNavItem` in `admin_home_screen.dart` wraps an already semantic `TextButton` inside an extra `Semantics` node.
- **Fix**:
  1. In `OrgWorkspaceTransition`, ensure outgoing transition widgets are wrapped cleanly so semantics pass does not crash during mid-animation view focus changes.
  2. Ensure `admin_home_screen.dart` cleanly attaches semantics properties directly or uses `MergeSemantics`.

### Priority 5 (Medium): Provider Workspaces Safety & Isolation
- **Verification**:
  - Organization provider shell (`OrgProviderShell`) and Individual provider shell (`IndividualProviderShell`) do NOT import or link to student safety reports.
  - Payment correction requests submitted by providers are strictly segregated from private student safety concerns.
  - Keep unsupported v2 features (e.g. automated alerts, evidence uploads, dispute mediation) visibly marked as unavailable.

---

## Action Plan (Polish Phase)

1. **Card Polish**: Refine `AdminReviewPriorities` and `PlatformOverviewScreen` header/hero cards.
2. **Typography & Terminology Polish**: Fix serif font in `DisbursementsOversightScreen`, fix "Verified Funds" badge in `AdminScholarshipsTab`, disambiguate Student vs Provider applications in `ApplicationsOversightScreen`.
3. **Empty/Error States Polish**: Refine empty states in `ReportsSafetyScreen` and `support_concerns_screen.dart`.
4. **Transition & Semantics Hardening**: Fix `OrgWorkspaceTransition` to eliminate `RenderSemanticsAnnotations` assertions on view focus change.
5. **Real-Browser Verification**: Run Chrome CDP script verifying 1280×800, 360×800, 440×956, 200% text, and short window (1280×420).
6. **Full Test Suite & Analysis**: Run all 963+ offline tests and scoped analyzer to ensure zero regressions.
