# Task Card: QA (`cerith` / `ai/qa`)

**Sprint:** 3rd Increment Pre-Presentation Audit  
**Role:** 🔍 Independent Quality Assurance & Bug Hunting Specialist  
**Reference Plan:** `docs/plans/2026-10-19_increment3_pre_presentation_audit_plan.md`  
**Status:** `READY FOR AUDIT`

---

## 1. Objective
Perform an independent, adversarial quality audit of the complete transaction cycle to ensure bulletproof stability during the instructor's live demonstration. Verify that all automated tests pass, edge cases (unauthorized submission, withdrawal constraints, premature approval) fail safely, and the classroom demonstration script is clear and verified.

---

## 2. Permitted Files
- `test/application_workflow_transport_test.dart`
- `test/reviewer_drawer_lifecycle_test.dart`
- `test/application_decision_letter_test.dart`
- `test/award_celebration_ui_test.dart`
- `test/features/provider/provider_sub_role_test.dart`
- `test/features/student/bottom_nav_tab_switch_test.dart`
- `scratch/verify_post_cleanup_state.mjs`
- `docs/reports/3RD_INCREMENT_LIVE_DEMO_SCRIPT.md`
- `docs/reports/2026-10-19_increment3_qa_report.md` (report deliverable)

---

## 3. Specific Audit Checklist

### A. Core Transaction Cycle Validation
1. **The 4-Stage Transaction Loop**:
   - Trace the exact sequence:
     1. Student completes and submits application (`submitted`).
     2. Reviewer scores rubric and endorses (`endorsed`).
     3. Org Admin reviews evaluator rubric and approves (`approved` / `awarded`).
     4. Student receives in-app award notification and views official decision letter / certificate.
2. **Negative Edge Cases**:
   - Verify withdrawal guard: Can an application in `endorsed`, `approved`, or `awarded` status be withdrawn? (Must throw `ApplicationWithdrawalException` and display user-friendly snackbar).
   - Verify unauthenticated guard: What happens when an unauthenticated user attempts to submit an application? (Must be blocked cleanly).
   - Verify empty state handling: Check that zero applications in incoming queues render clean, explanatory empty state cards without crashing.

### B. Automated Test Suite Execution
Execute the full suite of transaction, workflow, and lifecycle tests:
```bash
flutter test test/application_workflow_transport_test.dart
flutter test test/reviewer_drawer_lifecycle_test.dart
flutter test test/application_decision_letter_test.dart
flutter test test/award_celebration_ui_test.dart
flutter test test/features/provider/provider_sub_role_test.dart
flutter test test/features/student/bottom_nav_tab_switch_test.dart
```

### C. Live Demo Readiness & Script Audit
1. Run read-only database state check:
   ```bash
   node scratch/verify_post_cleanup_state.mjs
   ```
2. Verify that:
   - Student tracker has **0 applications**.
   - Student notifications has **0 items**.
   - Reviewer queue has **0 applications**.
   - Org admin queue has **0 applications**.
   - The 3 DOST demo scholarships are active with deadlines in December 2026.
3. Review and audit `docs/reports/3RD_INCREMENT_LIVE_DEMO_SCRIPT.md` to guarantee every presentation step and credential matches current live system configuration.

---

## 4. Deliverable Report
Commit completion report to:
`docs/reports/2026-10-19_increment3_qa_report.md`

Must include:
- `### Test Execution Summary` (with exact test names, pass/fail counts, execution times)
- `### Negative & Edge Case Analysis`
- `### Live Demo Environment Status`
- `### Implemented / Audited`
- `### Verified`
- `### Not verified`
- `### Remaining risks`
