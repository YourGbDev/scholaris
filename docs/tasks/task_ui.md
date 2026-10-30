# Task Card: UI/UX (`bowhead` Session)

**Sprint**: Round 6 — Inactivity Persistence, Zero Synthetic State & Pre-Integration Verification  
**Role**: 🎨 Presentation, Responsive Layout & Accessibility Specialist  
**Assigned Workspace**: `C:\Users\Windows 11\orca\workspaces\scholaris\bowhead`  
**Active Branch**: `codex/round6-ui` (Baseline: `41454588d88323db4f9cf80ac5f852a4c7bf598c`)  
**Standing Contract**: [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)  
**Status**: `READY`

---

## 1. Permitted Files (Strict Sole Ownership)

### Sole Edit Ownership:
- `lib/features/applications/presentation/applications_screen.dart`
- `lib/features/provider/presentation/org/org_incoming_applications_tab.dart`
- `test/applications_tracking_widget_test.dart`
- `test/provider_console_desktop_test.dart`
- `docs/reports/task_ui_report.md`

### Read-Only / Excluded:
- `lib/core/security/inactivity_guard.dart` (inspect dialog layout only; Builder owns code edits)
- `landing/` (landing page redesign/polish held out of round)
- `test/session_inactivity_test.dart` (Builder ownership)
- `test/qa_inactivity_challenge_test.dart` (QA ownership)
- Global brand identity (Geist typography, student lavender theme, mascots, navbar)

---

## 2. Directives & Tasks

1. **Zero Synthetic State in Applications Draft**:
   - Verify that all hardcoded mock checklist rows (*"Personal Statement (750 words)"*, *"UP Diliman Academic Transcript"*, *"Faculty Recommendation"*) are completely removed from `_ApplicationCard`.
   - Ensure the honest text (*"Review your draft and attached documents."*) and fallback (*"Deadline unavailable"*) render clearly across narrow mobile viewports.
2. **Provider KPI Card Title Alignment**:
   - Verify the KPI card title in `org_incoming_applications_tab.dart` displays *"Approved / Awarded"* consistent with live status.
3. **Inactivity Dialog Inspection (Collaboration with Builder)**:
   - Inspect the warning dialog (*"Your session is about to expire"*) and blocking dialog (*"Your session has expired"*, *"Security check unavailable"*) in `lib/core/security/inactivity_guard.dart`.
   - Check layout at 360×800, 440×956, and 1280×800 viewports under 1.0x and 2.0x Dynamic Type scaling.
   - Document any layout or contrast findings in `docs/reports/task_ui_report.md` for Builder; do NOT edit `inactivity_guard.dart` directly.
4. **Verification & Delivery**:
   - Run `flutter analyze lib/features/applications/ lib/features/provider/presentation/org/ test/applications_tracking_widget_test.dart test/provider_console_desktop_test.dart`.
   - Run `flutter test test/applications_tracking_widget_test.dart test/provider_console_desktop_test.dart`.
   - Commit changes to `codex/round6-ui` with descriptive commit message.
   - Deliver report to `docs/reports/task_ui_report.md` including mandatory "Skills Applied" section citing Apple HIG references.
