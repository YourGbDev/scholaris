# Builder Deliverable Report: Session Inactivity Persistence & Fail-Closed Storage Hardening (Round 6)

**Date:** 2026-10-30  
**Specialist:** 🏗️ Builder (`cowrie` worktree / `ai/builder`)  
**Active Branch:** `codex/round6-builder`  
**Baseline Commit:** `41454588d88323db4f9cf80ac5f852a4c7bf598c`  
**Delivered Code Commit SHA:** `e1cb62ed737172c909cfd3c22005c974c417d9f5`  
**Delivered Branch Commit SHA:** `190ecc07df868cd1ad4429c05abc2eb7c821f408`  
**Standing Contract:** [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)  
**Task Card:** [`docs/tasks/task_builder.md`](../tasks/task_builder.md)  
**Status:** `DELIVERED & VERIFIED`

---

## 1. Executive Summary

Builder has finalized and hardened the transferred inactivity persistence implementation in `lib/core/security/inactivity_guard.dart` and the cross-platform storage abstraction in `lib/core/security/inactivity_storage*.dart`. Implementation test ownership in `test/session_inactivity_test.dart` has been comprehensively expanded to 21 automated widget and unit tests covering all edge cases specified in Section 4 of the Round 6 Multi-Specialist Operating Contract.

Key capabilities delivered:
1. **Genuinely New Sessions**: New authenticated sessions with no saved deadline initialize a fresh 15-minute deadline and persist it immediately.
2. **Expired Deadline Restoration**: Sessions restored with elapsed timestamps immediately block access and sign out locally without flashing protected content.
3. **Fail-Closed Validation**: Negative, zero, or implausible far-future timestamps (>24 hours) fail closed by triggering immediate session expiration.
4. **Storage Hardware Exception Resilience**: Read, write, or remove failures from underlying platform storage (e.g., `SharedPreferences` or `sessionStorage`) trigger a modal barrier error dialog (*"Security check unavailable"*) offering manual sign-out instead of crashing or resetting the timer.
5. **Monotonic Generation Protection**: Rapid account switching purges the outgoing user's deadline key immediately, and any asynchronous writes queued by the previous session are discarded via monotonic `_generation` tracking.
6. **Sign-Out Retry**: Network or platform failures during sign-out retain modal blocking and present both *"Try again"* and *"Sign out"* actions.
7. **Local Inactivity Scope**: Enforces client-side session destruction (`SignOutScope.local`) to defend against physical device abandonment without confounding local protection with server-side token revocation.

---

## 2. Exact Files Modified & Owned

Under the strict sole edit ownership assigned in `SPECIALIST_CONTRACT.md`:

| File | Status | Description |
| :--- | :--- | :--- |
| `lib/core/security/inactivity_guard.dart` | Modified | Hardened session restore, storage exception handling, monotonic generation guards, far-future/negative timestamp validation, and retry actions |
| `lib/core/security/inactivity_storage.dart` | Added | Conditional platform export routing native vs web JS interop storage |
| `lib/core/security/inactivity_storage_native.dart` | Added | Native persistent storage backed by `SharedPreferences` with fail-closed throw semantics |
| `lib/core/security/inactivity_storage_web.dart` | Added | Web browser session storage backed by `package:web/web.dart` (`window.sessionStorage`) |
| `test/session_inactivity_test.dart` | Modified | 21 comprehensive implementation tests covering all contract criteria, edge cases, viewports, and race conditions |
| `docs/reports/task_builder_report.md` | Added | This deliverable report documenting technical acceptance, verification evidence, and skills applied |

*Note: Unrelated files and dirty states from other specialist worktrees remain strictly untouched.*

---

## 3. Technical Acceptance Matrix

| # | Acceptance Criterion (from `SPECIALIST_CONTRACT.md` Section 4) | Verdict | Evidence / Verification Method |
| :-: | :--- | :-: | :--- |
| **1** | **Genuinely New Authenticated Session**: When a user signs in and no stored deadline exists, initialize a fresh deadline (`DateTime.now() + 15m`) and persist immediately. | `PASS` | Verified via test `genuinely new session with no saved deadline initializes 15-minute deadline and persists immediately`. Confirms `inactivity_deadline_student` is written with difference in [14, 15] minutes. |
| **2** | **Existing Expired Deadline**: When restoring a session whose stored deadline is in the past, immediately block access and trigger local sign-out without briefly flashing protected UI. | `PASS` | Verified via test `restored session past its inactivity deadline signs out`. Transition sets `_loading = false` and `_expired = true` atomically; protected child is wrapped in `ExcludeFocus`, `ExcludeSemantics`, and covered by `ModalBarrier`. |
| **3** | **Malformed, Negative, or Implausible Stored Values**: Values `<= 0` or in far future (`> 24h`) enforce fail-closed policy (treat as expired) rather than extending the session. | `PASS` | Verified via tests `restored session with implausible far-future deadline (>24h) fails closed and expires` and `restored session with negative stored timestamp fails closed and expires`. |
| **4** | **Repeated Relaunch**: Relaunching the app repeatedly must NEVER silently grant a fresh 15-minute window if original deadline has passed. | `PASS` | Verified via test `repeated relaunch of expired session never silently grants a fresh 15-minute window` (multi-lifecycle relaunch check). |
| **5** | **Clock Manipulation (Time Travel)**: Evaluate forward and backward system clock jumps against `DateTime.now()`. | `PASS` | Verified via test `forward clock jump during active session triggers immediate expiration` and restore/schedule checks rejecting `deadline.difference(now) > 24 hours`. |
| **6** | **Hardware/Storage Exceptions**: Read, write, or removal throws fail closed with modal barrier (*"Security check unavailable"*) offering manual sign-out instead of crashing or resetting timer. | `PASS` | Verified via tests `storage failure blocks access instead of resetting the timer`, `storage write failure during activity triggers security check unavailable dialog`, and `storage failure on key removal during account switch fails closed`. |
| **7** | **Rapid Account Switching & Late Writes**: Signing out User A and signing in User B purges User A's key immediately. Late writes queued by User A resolving after User B logs in are discarded via monotonic `_generation` check. | `PASS` | Verified via test `rapid account switching purges previous user key and discards late queued writes`. Delayed write from User A does not overwrite storage after User B signs in. |
| **8** | **Sign-Out Retry**: If network failure prevents `signOut(scope: SignOutScope.local)` from completing remotely, the screen remains locked with *"Try again"* and *"Sign out"*. | `PASS` | Verified via test `failed automatic sign-out keeps the screen blocked and offers retry with Try again and Sign out`. Tapping either action retries invocation while `ModalBarrier` remains active. |
| **9** | **Evidence Boundaries**: Local inactivity storage vs server JWT revocation. | `PASS` | Verified via test `distinguishes local inactivity enforcement from server token revocation: executes local scope sign-out and purges local storage`. Confirms local scope invocation and storage cleanup. |

---

## 4. Skills Applied

As mandated by `AGENTS.md` Section 2, the following skills were read and applied during this implementation:

### 1. `test-driven-development` (`.agents/skills/test-driven-development/SKILL.md`)
* **Guidelines Applied**: Iron Law ("No production code without a failing test first"), Red-Green-Refactor cycle.
* **Concrete Evidence**:
  - Wrote test `restored session with implausible far-future deadline (>24h) fails closed and expires` before implementing the far-future check in `lib/core/security/inactivity_guard.dart`.
  - Executed `flutter test test/session_inactivity_test.dart` and recorded the RED failure:
    `Expected: <1> Actual: <0>` (TestFailure at `session_inactivity_test.dart:95:7`).
  - Implemented the fail-closed check in `_restore`, `_scheduleDeadline`, and `_activity`, then re-ran `flutter test` to achieve GREEN (`All tests passed!`).

### 2. `systematic-debugging` (`.agents/skills/systematic-debugging/SKILL.md`)
* **Guidelines Applied**: Phase 1 (Root Cause Investigation: carefully reading compilation and analyzer diagnostic errors; avoiding symptom guesses).
* **Concrete Evidence**:
  - When introducing `savedDeadline = isInvalid ? null : DateTime.fromMillisecondsSinceEpoch(saved!)`, the Dart compiler reported: `Error: Method 'isAfter' cannot be called on 'DateTime?' because it is potentially null`.
  - Rather than force-unwrapping with `!`, investigated null safety flow and handled the null condition explicitly: `savedDeadline == null || !savedDeadline.isAfter(now)`. Verified clean compilation and zero analyzer diagnostics.

### 3. `verification-before-completion` (`.agents/skills/verification-before-completion/SKILL.md`)
* **Guidelines Applied**: The Gate Function ("No completion claims without fresh verification evidence; run the full command, inspect exit codes, confirm output before making assertions").
* **Concrete Evidence**:
  - Fresh execution of `flutter test test/session_inactivity_test.dart` resulting in 21 passed tests with exit code 0 (Task ID `task-136`).
  - Fresh execution of `flutter analyze lib/core/security/ test/session_inactivity_test.dart` resulting in zero diagnostics with exit code 0 (Task ID `task-140`).

### 4. `ponytail` (`.agents/skills/ponytail/SKILL.md`)
* **Guidelines Applied**: "The smallest change that fully solves the task; no abstraction, wrapper, type conversion, option, config, boilerplate or 'for later' code nobody asked for."
* **Concrete Evidence**:
  - Leveraged Dart's native async queue chaining (`_storageQueue.then((_) => operation())`) rather than introducing third-party queue libraries or excessive concurrency wrappers.
  - Implemented monotonic generation tracking with a simple integer increment (`++_generation`), cleanly invalidating stale async tasks across session transitions with zero overhead.

---

## 5. Verification Commands & Outputs

### 5.1 Test Suite Verification
```powershell
flutter test test/session_inactivity_test.dart
```
**Output:**
```
00:00 +0: loading C:/Users/Windows 11/orca/workspaces/scholaris/cowrie/test/session_inactivity_test.dart
00:00 +0: genuinely new session with no saved deadline initializes 15-minute deadline and persists immediately
00:00 +1: restored session past its inactivity deadline signs out
00:01 +2: restored session with implausible far-future deadline (>24h) fails closed and expires
00:01 +3: restored session with negative stored timestamp fails closed and expires
00:01 +4: repeated relaunch of expired session never silently grants a fresh 15-minute window
00:01 +5: restart persistence resumes unexpired deadline without resetting to 15 minutes
00:01 +6: forward clock jump during active session triggers immediate expiration
00:01 +7: a different user does not inherit another user deadline
00:01 +8: storage failure blocks access instead of resetting the timer
00:01 +9: storage write failure during activity triggers security check unavailable dialog
00:01 +10: storage failure on key removal during account switch fails closed
00:01 +11: rapid account switching purges previous user key and discards late queued writes
00:01 +12: sign-out clears the deadline before the same user signs in again
00:01 +13: inactivity warning fits a 360.0x800.0 viewport
00:01 +14: inactivity warning fits a 440.0x956.0 viewport
00:01 +15: inactivity warning fits a 1280.0x800.0 viewport
00:01 +16: ordinary user activity postpones the warning
00:01 +17: warns a signed-in user before 15 minutes of inactivity
00:01 +18: stay signed in resets the warning and expiration
00:02 +19: failed automatic sign-out keeps the screen blocked and offers retry with Try again and Sign out
00:02 +20: distinguishes local inactivity enforcement from server token revocation: executes local scope sign-out and purges local storage
00:02 +21: All tests passed!
```
*Result:* **PASS** (21/21 tests passed, 0 failures, exit code 0).

### 5.2 Static Analysis Verification
```powershell
flutter analyze lib/core/security/ test/session_inactivity_test.dart
```
**Output:**
```
Analyzing 2 items...
No issues found! (ran in 6.8s)
```
*Result:* **PASS** (0 warnings, 0 errors, exit code 0).

---

## 6. Limitations & Evidence Boundaries

1. **Client-Side Physical Device Defense Only**:
   - Stored inactivity deadlines in `InactivityStorage` (`SharedPreferences` on mobile/desktop, `window.sessionStorage` on web) provide defensive boundaries against physical device abandonment.
   - Client inactivity enforcement calls `Supabase.instance.client.auth.signOut(scope: SignOutScope.local)` to destroy local tokens and clear local state. It is not an assertion of server-side global JWT revocation across all user devices.
2. **Platform Storage Dependency**:
   - Storage writes rely on platform subsystem availability. If storage is disabled, unmounted, or quota-exceeded, `InactivityGuard` fails closed by design with *"Security check unavailable"* and requires manual sign out.
3. **Operational Scope**:
   - Zero remote mutations, live database updates, remote git pushes, or IPA releases were performed. All work is committed locally on branch `codex/round6-builder`.
