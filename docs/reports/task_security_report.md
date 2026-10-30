# Task Report: Security Controls & Inactivity Storage Audit (Round 6)

**Sprint**: Round 6 — Inactivity Persistence, Zero Synthetic State & Pre-Integration Verification  
**Role**: 🛡️ Information Assurance, Privacy & Security Controls Specialist  
**Assigned Workspace**: `C:\Users\Windows 11\orca\workspaces\scholaris\fusilier`  
**Active Branch**: `codex/round6-security`  
**Baseline Commit**: `41454588d88323db4f9cf80ac5f852a4c7bf598c`  
**Audited Target**: Builder (`cowrie` worktree on `codex/round6-builder`)  
**Audited Target State**: Baseline `41454588d88323db4f9cf80ac5f852a4c7bf598c` + uncommitted evolving working tree (`lib/core/security/`)  
**Audit Document**: [`docs/reviews/2026-10-30-inactivity-storage-audit.md`](../reviews/2026-10-30-inactivity-storage-audit.md)  
**Contract Reference**: [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)  
**Status**: `COMPLETE (INITIAL AUDIT DELIVERED; BUILDER REMEDIATION PENDING)`

---

## 1. Executive Summary

Security audited Builder's evolving session inactivity persistence implementation in `cowrie/lib/core/security/` across nine core security and privacy vectors: cold-start restart persistence, timestamp validation, storage failures, cross-user isolation, late queued operations, clock manipulation, sign-out retry, key/value privacy exposure, and client vs. server enforcement scope.

The overall architecture is well-structured, modular, and fail-closed against storage exceptions, offline sign-out errors, and race conditions. However, an important defect was uncovered: **timestamps in the far future (>24 hours) and corrupted non-numeric web strings are not clamped or rejected**, which allows an attacker or corrupted storage to disable inactivity locking indefinitely. A secondary risk was identified regarding **backwards system clock manipulation**, which expands the inactivity window.

A **Conditional Pass / Action Required** verdict is rendered. Builder must address the two validation recommendations before final integration.

---

## 2. Skills Applied

In accordance with `AGENTS.md` (Section 2 & 3) and `GEMINI.md` (Section 0):

1. **`systematic-debugging`** (`.agents/skills/systematic-debugging/SKILL.md`):
   - *Guidelines/Rules*: Phase 1 (Root Cause Investigation) and Phase 2 (Pattern Analysis).
   - *Application*: Traced call stacks backward from `_scheduleDeadline` to `_restore` and `_key`. Identified that `DateTime.fromMillisecondsSinceEpoch(saved!)` does not assert bounds against `DateTime.now() + 24 hours`. Traced web `inactivity_storage_web.dart` to identify that `int.tryParse` returns `null` for corrupted strings, causing `_restore` to treat corrupted storage as a fresh session.
   - *Evidence Produced*: Documented exact code execution paths in Section 3.2 of the audit review.

2. **`verification-before-completion`** (`.agents/skills/verification-before-completion/SKILL.md`):
   - *Guidelines/Rules*: Iron Law ("No completion claims without fresh verification evidence").
   - *Application*: Executed full unit test and analyzer runs against Builder's code in `cowrie` before making audit assertions.
   - *Evidence Produced*: Recorded complete stdout and exit codes for `flutter test test/session_inactivity_test.dart` (11/11 passing, exit 0) and `flutter analyze` (0 issues, exit 0).

3. **`ponytail`** (`.agents/skills/ponytail/SKILL.md`):
   - *Guidelines/Rules*: Minimal complete engineering change without over-engineering; strict file ownership boundaries.
   - *Application*: Scoped recommendations to 3 lines of defensive clamping in `_restore` and `_scheduleDeadline`. Confined all work strictly to `docs/reviews/2026-10-30-inactivity-storage-audit.md` and `docs/reports/task_security_report.md`.

---

## 3. Implemented

1. **Comprehensive Information Assurance Audit**:
   - Authored [`docs/reviews/2026-10-30-inactivity-storage-audit.md`](../reviews/2026-10-30-inactivity-storage-audit.md) covering:
     - Restart persistence and modal barrier blanking during storage hydration.
     - Timestamp bounds checking and corrupted storage parsing.
     - Storage read/write/remove failure fail-closed modal barrier verification.
     - Cross-user key isolation (`inactivity_deadline_$userId`) and account-switch purging (`storage.remove(_key(previous))`).
     - Late queued operation cancellation via monotonic `_generation` tracking.
     - Forward vs. backward clock tampering defenses.
     - Offline sign-out retry loops with persistent modal locking.
     - Privacy exposure analysis: verified zero tokens, passwords, or PII stored in local preferences.
     - Technical boundary between client-side UI locking and server-side JWT revocation (`SignOutScope.local`).
     - Philippine Data Privacy Act (RA 10173) compliance disclaimer.

---

## 4. Verified

### Check 1: Unit Test Suite in Builder Worktree
- **Command**: `powershell -Command "cd 'C:\Users\Windows 11\orca\workspaces\scholaris\cowrie'; flutter test test/session_inactivity_test.dart"`
- **Result**: `00:01 +11: All tests passed!` (Exit Code `0`).
- **Pass Log**:
  - `restored session past its inactivity deadline signs out`
  - `a different user does not inherit another user deadline`
  - `storage failure blocks access instead of resetting the timer`
  - `sign-out clears the deadline before the same user signs in again`
  - `inactivity warning fits a 360.0x800.0 viewport`
  - `inactivity warning fits a 440.0x956.0 viewport`
  - `inactivity warning fits a 1280.0x800.0 viewport`
  - `ordinary user activity postpones the warning`
  - `warns a signed-in user before 15 minutes of inactivity`
  - `stay signed in resets the warning and expiration`
  - `failed automatic sign-out keeps the screen blocked and offers retry`

### Check 2: Static Analyzer in Builder Worktree
- **Command**: `powershell -Command "cd 'C:\Users\Windows 11\orca\workspaces\scholaris\cowrie'; flutter analyze lib/core/security/ test/session_inactivity_test.dart"`
- **Result**: `Analyzing 2 items... No issues found! (ran in 3.5s)` (Exit Code `0`).

### Check 3: Zero Plaintext Credential Exposure
- **Inspection**:
  - `lib/core/security/inactivity_storage_native.dart`: Writes integer millisecond timestamp via `setInt(key, value)`.
  - `lib/core/security/inactivity_storage_web.dart`: Writes integer string via `setItem(key, value.toString())`.
- **Result**: Verified zero plaintext passwords, tokens, API keys, or personal profile data stored in client-side preferences.

### Check 4: Fail-Closed Modal Barrier on Storage & Sign-Out Exceptions
- **Inspection & Test**:
  - When storage throws `StateError`, `_storageFailed` renders a non-dismissible `ModalBarrier` and `"Security check unavailable"` dialog offering `"Sign out"`.
  - When `signOut()` throws `StateError('offline')`, screen remains locked with `"We could not sign you out. Please try again."` and `"Try again"`.
- **Result**: Verified 100% fail-closed behavior on storage and network failures.

---

## 5. Not Verified

1. **Builder's Final Immutable Commit**:
   - Builder has not yet created a Git commit in `cowrie` (`git status` shows uncommitted changes on baseline `41454588d88323db4f9cf80ac5f852a4c7bf598c`).
   - Final audit endorsement requires re-verifying against Builder's exact delivered commit SHA once committed.
2. **Real Web Browser DOM SessionStorage**:
   - Evaluated code logic for `inactivity_storage_web.dart` statically; headless test ran against mocked native `SharedPreferences`. Real browser web execution must be verified during integration.

---

## 6. Remaining Risks & Action Items for Builder

1. **Far-Future Timestamp Bypass (High Severity)**:
   - *Risk*: A stored deadline far in the future (>24 hours) is accepted as valid, extending the inactivity window indefinitely.
   - *Action*: In `_restore`, Builder must clamp or expire any timestamp where `parsed.isAfter(now.add(const Duration(hours: 24)))` or `saved < 0`.
2. **Backward System Clock Manipulation (Medium Risk)**:
   - *Risk*: Moving the system clock backward inflates `remaining = _deadline.difference(DateTime.now())` beyond 15 minutes.
   - *Action*: In `_scheduleDeadline`, clamp `if (remaining > _timeout) remaining = _timeout;`.
3. **Web Non-Numeric Storage Handling**:
   - *Risk*: `int.tryParse` returning `null` causes corrupted data to be treated as a brand new session.
   - *Action*: Differentiate between missing key and invalid string.

---

## 7. Compliance & Statutory Limitation (RA 10173)

This report provides factual technical findings on client-side access barriers, storage keys, and error handling. It does **not** constitute legal certification or statutory compliance under Republic Act No. 10173 (Philippine Data Privacy Act of 2012) or National Privacy Commission (NPC) circulars.
