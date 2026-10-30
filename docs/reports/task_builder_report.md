# Builder Deliverable Report: Session Inactivity Persistence & Fail-Closed Storage Hardening (Round 6)

**Date:** 2026-10-30  
**Specialist:** 🏗️ Builder (`cowrie` worktree / `ai/builder`)  
**Active Branch:** `codex/round6-builder`  
**Baseline Commit:** `41454588d88323db4f9cf80ac5f852a4c7bf598c`  
**Standing Contract:** [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)  
**Task Card:** [`docs/tasks/task_builder.md`](../tasks/task_builder.md)  
**Status:** `DELIVERED & VERIFIED (REVISED WITH BACKWARD-CLOCK CLAMP & VISUAL CONCEALMENT)`

---

## 1. Executive Summary

Builder has implemented, hardened, and verified the transferred inactivity persistence implementation in `lib/core/security/inactivity_guard.dart` and the cross-platform storage abstraction in `lib/core/security/inactivity_storage*.dart`. Implementation test ownership in `test/session_inactivity_test.dart` has been comprehensively expanded to 25 automated widget and unit tests covering all edge cases specified in Section 4 of the Round 6 Multi-Specialist Operating Contract and the Lead Architect review directives.

Key capabilities delivered:
1. **Genuinely New Sessions**: New authenticated sessions with no saved deadline initialize a fresh 15-minute deadline and persist it immediately.
2. **Expired Deadline Restoration**: Sessions restored with elapsed timestamps immediately block access and sign out locally without flashing protected content.
3. **Protected Content Concealment**: When session access is unverified or denied (`_loading`, `_expired`, or `_storageFailed`), `widget.child` is completely unmounted and concealed behind a solid `ColoredBox` surface (`Colors.white`), preventing any visual exposure of applicant data beneath modal barriers. During the pre-expiration warning window (`_warning`), `widget.child` remains visible beneath the warning dialog.
4. **Backward-Clock Clamping & Controllable Clock**:
   - Introduced `inactivityClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);` for controllable time injection.
   - When a system clock rollback occurs (e.g. backward jump smaller than 24 hours), `remaining` time in `_scheduleDeadline`, `_restore`, and `didChangeAppLifecycleState` is strictly clamped to `_timeout` (15 minutes), preventing artificial session inflation.
5. **Fail-Closed Validation**: Negative, zero, or implausible far-future timestamps (>24 hours) fail closed by triggering immediate session expiration.
6. **Storage Hardware Exception Resilience**: Read, write, or remove failures from underlying platform storage (e.g., `SharedPreferences` or `sessionStorage`) trigger a modal barrier error dialog (*"Security check unavailable"*) offering manual sign-out instead of crashing or resetting the timer, while concealing protected content.
7. **Monotonic Generation Protection**: Rapid account switching purges the outgoing user's deadline key immediately, and any asynchronous writes queued by the previous session are discarded via monotonic `_generation` tracking.
8. **Sign-Out Retry**: Network or platform failures during sign-out retain modal blocking and present both *"Try again"* and *"Sign out"* actions.
9. **Local Inactivity Scope**: Enforces client-side session destruction (`SignOutScope.local`) to defend against physical device abandonment without confounding local protection with server-side token revocation.

---

## 2. Exact Files Modified & Owned

Under the strict sole edit ownership assigned in `SPECIALIST_CONTRACT.md`:

| File | Status | Description |
| :--- | :--- | :--- |
| `lib/core/security/inactivity_guard.dart` | Modified | Added `inactivityClockProvider`, backward-clock clamping to `_timeout`, and complete visual concealment of `widget.child` on unverified/denied states |
| `lib/core/security/inactivity_storage.dart` | Added | Conditional platform export routing native vs web JS interop storage |
| `lib/core/security/inactivity_storage_native.dart` | Added | Native persistent storage backed by `SharedPreferences` with fail-closed throw semantics |
| `lib/core/security/inactivity_storage_web.dart` | Added | Web browser session storage backed by `package:web/web.dart` (`window.sessionStorage`) |
| `test/session_inactivity_test.dart` | Modified | 25 comprehensive implementation tests covering all contract criteria, edge cases, viewports, controllable clock jumps, and visual concealment |
| `docs/reports/task_builder_report.md` | Modified | This deliverable report documenting technical acceptance, verification evidence, and skills applied |

---

## 3. Technical Acceptance Matrix

| # | Acceptance Criterion | Verdict | Evidence / Verification Method |
| :-: | :--- | :-: | :--- |
| **1** | **Genuinely New Authenticated Session**: Initialize and persist 15-minute deadline immediately. | `PASS` | `test/session_inactivity_test.dart`: Test 1 |
| **2** | **Expired Deadline Restoration & Content Concealment**: Restored expired sessions immediately conceal content and trigger local sign-out. | `PASS` | `test/session_inactivity_test.dart`: Test 2 & Test 23 |
| **3** | **Malformed, Negative, or Far-Future (>24h) Fail-Closed**: Clamps/expires timestamps $\le 0$ or $>24\text{h}$. | `PASS` | `test/session_inactivity_test.dart`: Tests 3 & 4 |
| **4** | **Repeated Relaunch**: Never silently grants a fresh 15-minute window if original deadline passed. | `PASS` | `test/session_inactivity_test.dart`: Test 5 |
| **5** | **Clock Manipulation (Time Travel)**: Forward jumps expire; backward jumps $<24\text{h}$ are clamped to 15 minutes. | `PASS` | `test/session_inactivity_test.dart`: Test 7 & Test 22 |
| **6** | **Hardware/Storage Exceptions & Content Concealment**: Read/write/remove throws conceal content and render modal barrier dialog. | `PASS` | `test/session_inactivity_test.dart`: Tests 9, 10, 11, & 24 |
| **7** | **Rapid Account Switching & Late Writes**: Outgoing key purged; monotonic `_generation` drops stale async writes. | `PASS` | `test/session_inactivity_test.dart`: Test 12 |
| **8** | **Sign-Out Retry**: Network failure retains modal barrier and offers *"Try again"* and *"Sign out"*. | `PASS` | `test/session_inactivity_test.dart`: Test 20 |
| **9** | **Evidence Boundaries**: Local inactivity storage vs server JWT revocation. | `PASS` | `test/session_inactivity_test.dart`: Test 21 |
| **10** | **Pre-Expiration Warning Presentation**: Warning dialog renders with protected content visible underneath. | `PASS` | `test/session_inactivity_test.dart`: Test 25 |

---

## 4. Skills Applied

As mandated by `AGENTS.md` Section 2:

### 1. `test-driven-development` (`.agents/skills/test-driven-development/SKILL.md`)
* **Guidelines Applied**: Iron Law ("No production code without a failing test first"), Red-Green-Refactor cycle.
* **Concrete Evidence**:
  - Wrote test `backward clock jump smaller than 24 hours clamps remaining time to 15-minute timeout` verifying that a 2-hour rollback is clamped to 15 minutes.
  - Wrote tests asserting `find.text('Protected Confidential Document')` is absent during `_loading`, `_expired`, and `_storageFailed`.
  - Verified RED failure before implementing clamping and concealment, followed by clean GREEN pass across all 25 tests.

### 2. `systematic-debugging` (`.agents/skills/systematic-debugging/SKILL.md`)
* **Guidelines Applied**: Phase 1 (Root Cause Investigation) and Phase 2 (Boundary Testing).
* **Concrete Evidence**:
  - Investigated ProviderScope override changes across multiple pumps, isolating Riverpod's assertion requirement to unmount between different override configurations.

### 3. `verification-before-completion` (`.agents/skills/verification-before-completion/SKILL.md`)
* **Guidelines Applied**: The Gate Function ("No completion claims without fresh verification evidence; run the full command, inspect exit codes, confirm output before making assertions").
* **Concrete Evidence**:
  - Fresh execution of `flutter test test/session_inactivity_test.dart` resulting in 25 passed tests with exit code 0.
  - Fresh execution of `flutter analyze lib/core/security/ test/session_inactivity_test.dart` resulting in zero diagnostics with exit code 0.

### 4. `ponytail` (`.agents/skills/ponytail/SKILL.md`)
* **Guidelines Applied**: "The smallest change that fully solves the task; no abstraction, wrapper, type conversion, option, config, boilerplate or 'for later' code nobody asked for."
* **Concrete Evidence**:
  - Implemented `inactivityClockProvider` with a direct `DateTime Function()` typedef, avoiding heavy clock abstraction libraries.
  - Implemented content concealment via conditional widget inclusion (`if (concealContent) const ColoredBox(...) else ...`) with zero layout overhead.

---

## 5. Verification Commands & Outputs

### 5.1 Test Suite Verification
```powershell
flutter test test/session_inactivity_test.dart
```
**Output:**
```
00:00 +0: genuinely new session with no saved deadline initializes 15-minute deadline and persists immediately
00:00 +1: restored session past its inactivity deadline signs out
00:00 +2: restored session with implausible far-future deadline (>24h) fails closed and expires
00:00 +3: restored session with negative stored timestamp fails closed and expires
00:00 +4: repeated relaunch of expired session never silently grants a fresh 15-minute window
00:00 +5: restart persistence resumes unexpired deadline without resetting to 15 minutes
00:00 +6: forward clock jump during active session triggers immediate expiration
00:00 +7: a different user does not inherit another user deadline
00:00 +8: storage failure blocks access instead of resetting the timer
00:00 +9: storage write failure during activity triggers security check unavailable dialog
00:00 +10: storage failure on key removal during account switch fails closed
00:01 +11: rapid account switching purges previous user key and discards late queued writes
00:01 +12: sign-out clears the deadline before the same user signs in again
00:01 +13: inactivity warning fits a 360.0x800.0 viewport
00:01 +14: inactivity warning fits a 440.0x956.0 viewport
00:01 +15: inactivity warning fits a 1280.0x800.0 viewport
00:01 +16: ordinary user activity postpones the warning
00:01 +17: warns a signed-in user before 15 minutes of inactivity
00:01 +18: stay signed in resets the warning and expiration
00:01 +19: failed automatic sign-out keeps the screen blocked and offers retry with Try again and Sign out
00:01 +20: distinguishes local inactivity enforcement from server token revocation: executes local scope sign-out and purges local storage
00:01 +21: backward clock jump smaller than 24 hours clamps remaining time to 15-minute timeout
00:01 +22: protected content is completely concealed during loading and expired-restore
00:01 +23: protected content is completely concealed during storage failure
00:01 +24: protected content remains visible beneath warning dialog during pre-expiration warning
00:01 +25: All tests passed!
```
*Result:* **PASS** (25/25 tests passed, 0 failures, exit code 0).

### 5.2 Static Analysis Verification
```powershell
flutter analyze lib/core/security/ test/session_inactivity_test.dart
```
**Output:**
```
Analyzing 2 items...
No issues found! (ran in 4.8s)
```
*Result:* **PASS** (0 warnings, 0 errors, exit code 0).
