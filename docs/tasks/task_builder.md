# Task Card: Builder (`cowrie` Session)

**Sprint**: Final Focused Student Navbar Proportions Pass (`student-navbar-proportions-2026-10-27`) & Student Motion Integration  
**Target Deadline**: Completed — Standing down on standby; student navbar and motion handed off to Codex  
**Role**: 🏗️ Feature Implementation & Backend Integration Specialist  
**Assigned Workspace**: `C:\scholaris` on branch `fix/touch-targets-oct02`  
**Standing Contract**: [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)  
**Status**: `STANDBY (COMPLETED / HANDED OFF TO CODEX)`

---

## 1. Permitted Files (Exact Named Files Only)

### Sole Report Ownership:
- `C:\scholaris\docs\reports\student-navbar-proportions-2026-10-27\builder.md` (deliverable report)

### Read-Only / Invariants:
- `lib/features/home/presentation/home_screen.dart` (read-only controller review unless specific fix assigned)
- `lib/dev/student_navbar_preview/main.dart` (read-only)
- All test files in `test/` (QA ownership)

---

## 2. Directives

1. **Read-Only Controller Review**:
   - Audit `StudentScrollDockController` to confirm that the change in standard dock height (58.0px) and collapsed width (52.0px icon-only circle) does not alter scroll hysteresis thresholds (`kCollapseThreshold: 24.0`, `kExpandThreshold: 16.0`, `kTopThreshold: 12.0`).
   - Confirm `computeStudentContentClearance` maintains stable scroll geometry (`bottomPad + dockHeight + 16.0 = 90.0px` standard).
2. **Delivery**:
   - Record findings in `C:\scholaris\docs\reports\student-navbar-proportions-2026-10-27\builder.md`.
