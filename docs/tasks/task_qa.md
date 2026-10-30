# Task Card: QA (`cerith` Session)

**Sprint**: Round 6 — Inactivity Persistence, Zero Synthetic State & Pre-Integration Verification  
**Role**: 🔍 Quality Assurance, Failure Reproduction & Independent Verification Specialist  
**Assigned Workspace**: `C:\Users\Windows 11\orca\workspaces\scholaris\cerith`  
**Active Branch**: `codex/round6-qa` (Baseline: `41454588d88323db4f9cf80ac5f852a4c7bf598c`)  
**Standing Contract**: [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)  
**Status**: `READY`

---

## 1. Permitted Files (Strict Sole Ownership)

### Sole Edit Ownership:
- `test/qa_inactivity_challenge_test.dart` (QA-authored challenge suite)
- `docs/reports/task_qa_report.md`

### Read-Only / Excluded:
- Product code in `lib/` (UI/Builder ownership)
- Builder's unit test file `test/session_inactivity_test.dart` (re-run only; do not overwrite)
- UI's test files `test/applications_tracking_widget_test.dart`, `test/provider_console_desktop_test.dart` (re-run only)

---

## 2. Directives & Tasks

1. **Integration of Delivered Commits**:
   - Wait until Builder (`cowrie`) and UI/UX (`bowhead`) deliver their commits on `codex/round6-builder` and `codex/round6-ui`.
   - In `cerith`, merge/cherry-pick the exact delivered commits from Builder and UI/UX into `codex/round6-qa`.
   - Record the exact tested commit SHA and Security's report revision.
2. **Author Independent Challenge Suite (`test/qa_inactivity_challenge_test.dart`)**:
   - Do NOT merely execute tests supplied by the implementer. Author independent tests exercising:
     * **Corrupted/Implausible Timestamps**: Stored values that are null, negative, in the far future (>24h), or non-numeric strings must fail closed.
     * **System Clock Jumps (Forward & Backward)**: Verify behavior when the system clock jumps forward or backward while the app is suspended.
     * **Storage Throws**: Mock storage throwing `PlatformException` on read, write, or removal. Confirm the blocking barrier dialog is displayed and manual sign-out is offered.
     * **Rapid Account Switching & Late Writes**: Simulate User A signing out and User B signing in within milliseconds; verify User A's late queued write does not overwrite User B's deadline.
     * **Sign-Out Retry**: Simulate `signOut` network failure; confirm screen remains blocked and retry button functions.
3. **Regression Execution**:
   - Run:
     ```powershell
     flutter test test/session_inactivity_test.dart test/applications_tracking_widget_test.dart test/provider_console_desktop_test.dart test/qa_inactivity_challenge_test.dart
     ```
   - Record baseline failures separately; do not silently waive them.
4. **Independent Verdict Delivery**:
   - Record `PASS`, `FAIL`, or `NOT VERIFIED` for each acceptance criterion with full reproducible command outputs.
   - Deliver report to `docs/reports/task_qa_report.md`.
