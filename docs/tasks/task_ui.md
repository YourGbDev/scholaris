# Task Card: UI/UX (`bowhead` / `ai/ui`)

**Sprint:** 3rd Increment Pre-Presentation Audit  
**Role:** 🎨 Flutter UI, Apple HIG & Motion Craft Specialist  
**Reference Plan:** `docs/plans/2026-10-19_increment3_pre_presentation_audit_plan.md`  
**Status:** `READY FOR AUDIT`

---

## 1. Objective
Audit the presentation layer across Student, Reviewer, and Org Admin portals. Rigorously enforce the instructor's ban on browser alerts ("localhost says"), verify responsive layouts across 360px, 440px, and 1280px viewports, and audit the visual hierarchy, optical typography, and animation discipline of the new official **Scholarship Approval Letter & Award Certificate** view.

---

## 2. Mandatory Design Skills to Apply
You MUST explicitly load, reference, and cite the workspace design skills in `.agents/skills/`:
- `apple-design` (`.agents/skills/apple-design/SKILL.md`): Review against Apple HIG principles (Clarity, Deference, Depth) and component standards.
- `emil-design-eng` (`.agents/skills/emil-design-eng/SKILL.md`): Review animation purpose, button tactile scale (`scale(0.97)`), and GPU-only transforms.
- `emil-apple-design` (`.agents/skills/emil-apple-design/SKILL.md`): Spring physics defaults (`damping: 1.0`, response `0.3-0.4`), optical type tracking, tactile feedback.
- `review-animations` (`.agents/skills/review-animations/SKILL.md`): The Ten Non-Negotiable Standards, zero unhandled overflow during transitions.

---

## 3. Permitted Files
- `lib/features/applications/presentation/application_decision_letter.dart`
- `lib/features/applications/presentation/application_detail_screen.dart`
- `lib/features/applications/presentation/widgets/student_notifications_sheet.dart`
- `lib/features/applications/presentation/widgets/applicant_review_drawer.dart`
- `lib/features/applications/presentation/widgets/submit_application_review_dialog.dart`
- `lib/features/provider/presentation/org/org_provider_shell.dart`
- `lib/features/provider/presentation/org/org_disbursements_tab.dart`
- `lib/shared/theme/app_motion.dart`
- `test/award_celebration_ui_test.dart`
- `test/application_decision_letter_test.dart`
- `test/features/student/bottom_nav_tab_switch_test.dart`
- `docs/reports/2026-10-19_increment3_ui_report.md` (report deliverable)

---

## 4. Specific Audit Checklist

### A. Strict Zero-Browser-Alert Verification
1. Search the presentation codebase to confirm **zero** usage of `window.alert()`, `dart:html` `window.alert`, or JavaScript alert popups.
2. Confirm that all notifications, errors, and success confirmations are delivered through:
   - In-app sliding `StudentNotificationsSheet`.
   - Themed Flutter floating `SnackBar`.
   - Native Flutter `AlertDialog` / `showDialog` modal widgets with institutional Scholaris styling.

### B. Approval Letter & Certificate Visual Craft
1. Audit `ApplicationDecisionLetter` ([`application_decision_letter.dart`](file:///C:/scholaris/lib/features/applications/presentation/application_decision_letter.dart)):
   - Verify layout and typography for both `ApplicationStatus.approved` (Letter of Approval) and `ApplicationStatus.awarded` (Official Award Certificate).
   - Ensure dynamic resolution of student full name (`profile.fullName`), scholarship title, provider name, and formatted award date.
   - Guard all text rows with `Flexible` or `Expanded` and `TextOverflow.ellipsis`.

### C. Responsive Viewport Checks & Tests
1. Run UI test suites across mobile (360px), large mobile (440px), and desktop (1280px):
   ```bash
   flutter test test/application_decision_letter_test.dart
   flutter test test/award_celebration_ui_test.dart
   flutter test test/features/student/bottom_nav_tab_switch_test.dart
   ```
2. Verify zero `RenderFlex overflowed` warnings.

---

## 5. Deliverable Report
Commit completion report to:
`docs/reports/2026-10-19_increment3_ui_report.md`

Must include:
- `### Skills Applied` (cite specific HIG sections and design engineering principles).
- `### Zero-Browser-Alert Audit Verdict`
- `### Responsive Viewport Verification Table`
- `### Implemented / Audited`
- `### Verified`
- `### Not verified`
- `### Remaining risks`
