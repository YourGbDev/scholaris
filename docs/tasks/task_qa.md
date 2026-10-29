# Task Card: QA (`cerith` Session)

**Sprint**: Final Focused Student Navbar Proportions Pass (`student-navbar-proportions-2026-10-27`) & Student Motion Integration  
**Target Deadline**: Completed — Standing down on standby; student navbar and motion handed off to Codex  
**Role**: 🔍 Testing, Regressions & Failure Reproduction Specialist  
**Assigned Workspace**: `C:\scholaris` on branch `fix/touch-targets-oct02`  
**Standing Contract**: [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)  
**Status**: `STANDBY (COMPLETED / HANDED OFF TO CODEX)`

---

## 1. Permitted Files (Exact Named Files Only)

### Sole Edit Ownership:
- `C:\scholaris\test\student_scroll_dock_test.dart` (update collapsed assertions: icon-only `find.byIcon(...)` instead of `find.text('Home')` / `find.text('Discover')`; update clearance expectation to `90.0px` = `16 + 58 + 16`)
- `C:\scholaris\test\student_nav_rebuild_test.dart` (update 62.0px height assertions to 58.0px)
- `C:\scholaris\test\student_navbar_accessibility_test.dart` (update dock height 62.0px to 58.0px; verify touch targets $\ge 44\text{pt}$)
- `C:\scholaris\docs\reports\student-navbar-proportions-2026-10-27\qa.md` (deliverable report)

### Read-Only / Invariants:
- All product files in `lib/` (UI/Builder owned)

---

## 2. Tasks & Acceptance Criteria

### Task QA-1: Update `student_scroll_dock_test.dart`
1. **Collapsed Icon-Only Verification**:
   - In Test 1 (lines 68–72) and Test 6 (line 208): update descendant check of `student-nav-compact-control` from `find.text(...)` to `find.byIcon(Icons.home_rounded)` / `find.byIcon(Icons.explore)`.
   - Confirm visible text is absent (`find.descendant(of: compactControl, matching: find.byType(Text))` findsNothing), while `Semantics` label remains present (`tester.getSemantics(compactControl).label` contains active tab name).
2. **Clearance Expectation**:
   - In Test 9 (line 338): update `clearanceExpanded` check from `16.0 + 62.0 + 16.0` (`94.0`) to `16.0 + 58.0 + 16.0` (`90.0`).

### Task QA-2: Update `student_nav_rebuild_test.dart`
- Update lines 62–90: change `62.0` height expectation for outer SizedBox, 4-tab pill, and `+` button to `58.0`.

### Task QA-3: Update `student_navbar_accessibility_test.dart`
- Update lines 255, 305, 337–338: change `62.0` dock height and `+` button size to `58.0`.
- Verify touch targets remain $\ge 44\text{pt}$ (58.0px $\ge$ 44.0px).

### Task QA-4: Execute 35 Navigation Tests + 47 Security Regression Tests (82/82)
- Run:
  ```powershell
  flutter test test/student_scroll_dock_test.dart test/student_navbar_accessibility_test.dart test/student_nav_rebuild_test.dart test/features/student/bottom_nav_tab_switch_test.dart
  flutter test test/cross_tab_logout_test.dart test/ias_security_test.dart test/codex_auth_transition_review_test.dart test/admin_auth_boundary_invalidation_test.dart
  ```
- Deliver report to `C:\scholaris\docs\reports\student-navbar-proportions-2026-10-27\qa.md` and mark `QA_FINAL`.
