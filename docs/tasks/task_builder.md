# Task Card: Builder (`cowrie` Session)

**Sprint**: Round 6 — Inactivity Persistence, Zero Synthetic State & Pre-Integration Verification  
**Role**: 🏗️ Backend, Security Storage & Implementation Specialist  
**Assigned Workspace**: `C:\Users\Windows 11\orca\workspaces\scholaris\cowrie`  
**Active Branch**: `codex/round6-builder` (Baseline: `41454588d88323db4f9cf80ac5f852a4c7bf598c`)  
**Standing Contract**: [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)  
**Status**: `READY`

---

## 1. Permitted Files (Strict Sole Ownership)

### Sole Edit Ownership:
- `lib/core/security/inactivity_guard.dart`
- `lib/core/security/inactivity_storage.dart`
- `lib/core/security/inactivity_storage_native.dart`
- `lib/core/security/inactivity_storage_web.dart`
- `test/session_inactivity_test.dart`
- `docs/reports/task_builder_report.md`

### Read-Only / Excluded:
- `lib/features/applications/` (UI/UX ownership)
- `landing/` (held out of round)
- `test/applications_tracking_widget_test.dart` (UI/UX ownership)
- `test/qa_inactivity_challenge_test.dart` (QA ownership)
- Remote Supabase / live migrations (held closed)

---

## 2. Directives & Tasks

1. **Harden `InactivityStorage` & `InactivityGuard`**:
   - Ensure clean conditional compilation across web (`inactivity_storage_web.dart`) and native (`inactivity_storage_native.dart`).
   - Maintain async queue serialization `_queue` so concurrent storage writes do not race.
   - Enforce monotonic `_generation` tracking: late operations resolving after an account switch must never overwrite the new user's deadline.
   - Implement fail-closed storage error handling: if `storage.read`, `write`, or `remove` throws an exception, present the blocking dialog (*"Security check unavailable"*) offering manual sign-out instead of crashing or silently resetting the timer.
   - When a session is genuinely new (no saved deadline), initialize a fresh 15-minute deadline and persist it immediately.
   - When a session is restored with an elapsed timestamp, immediately trigger expiration and sign out without briefly flashing protected screens.
   - If an invalid, negative, or far-future (>24h) timestamp is loaded, fail closed (treat as expired).
2. **Implementation & Unit Tests (`test/session_inactivity_test.dart`)**:
   - Verify unit coverage for expired session restore, storage failure fail-closed modal, sign-out deadline clearing, generation race protection, and viewport layout.
   - Add any meaningful tests required to prove the agreed behavior; do not artificially cap at a fixed number.
3. **Verification & Delivery**:
   - Run `flutter analyze lib/core/security/ test/session_inactivity_test.dart`.
   - Run `flutter test test/session_inactivity_test.dart`.
   - Commit changes to `codex/round6-builder` with descriptive commit message.
   - Deliver report to `docs/reports/task_builder_report.md` recording commit SHA, files changed, and test logs.
