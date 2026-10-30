# Technical Information Assurance Audit: Session Inactivity Persistence & Storage Boundaries

**Audit Reference**: `SEC-REV-2026-10-30-INACTIVITY-STORAGE`  
**Date**: October 30, 2026  
**Auditor**: Security Specialist (`fusilier` worktree on `codex/round6-security`)  
**Audited Target**: Builder Implementation (`cowrie` worktree on `codex/round6-builder`)  
**Target Files Inspected (Read-Only)**:
- `C:\Users\Windows 11\orca\workspaces\scholaris\cowrie\lib\core\security\inactivity_guard.dart`
- `C:\Users\Windows 11\orca\workspaces\scholaris\cowrie\lib\core\security\inactivity_storage.dart`
- `C:\Users\Windows 11\orca\workspaces\scholaris\cowrie\lib\core\security\inactivity_storage_native.dart`
- `C:\Users\Windows 11\orca\workspaces\scholaris\cowrie\lib\core\security\inactivity_storage_web.dart`
- `C:\Users\Windows 11\orca\workspaces\scholaris\cowrie\test\session_inactivity_test.dart`  
**Target Base Commit**: `41454588d88323db4f9cf80ac5f852a4c7bf598c` (with evolving uncommitted modifications in `cowrie`)  
**Operating Contract**: [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)

---

## 1. Executive Summary & Audit Verdict

| Domain | Assessment | Severity / Status |
| :--- | :--- | :--- |
| **Restart Persistence** | Verified safe cold-start hydration; expired deadlines block immediately. New session defaults to 15 min. | **PASS** |
| **Timestamp Validation** | Far-future (>24h) and web non-numeric inputs rejected fail closed (`FormatException` triggers `_storageFailed`). | **PASS** |
| **Storage Failures** | Read/write/remove exceptions trigger non-dismissible modal barrier (`Security check unavailable`). | **PASS** |
| **Cross-User Isolation** | Storage keys scoped with `userId`; previous user key purged on sign-out and switch. | **PASS** |
| **Late Queued Operations** | Monotonic `_generation` tracking and FIFO `_storageQueue` discard stale async writes. | **PASS** |
| **Clock Manipulation** | Forward jumps fail closed. Backward jumps $< 24\text{h}$ clamped to 15m in `_restore`, `_scheduleDeadline`, and resume. | **PASS** |
| **Sign-Out Retry** | Sign-out failure retains non-dismissible modal lock with retry option. | **PASS** |
| **Key & Value Exposure** | Values contain strictly integer timestamps. Zero tokens/credentials exposed. | **PASS** |
| **Enforcement Scope** | Client-side presentation/storage barrier only; distinct from server-side JWT revocation. | **DOCUMENTED** |
| **Compliance Scope** | Technical verification of access controls; not statutory RA 10173 certification. | **DISCLAIMED** |

**Final Audit Verdict**: **UNCONDITIONAL PASS (COMMIT `59527ad`)**.  
Builder resolved all identified vulnerabilities in commit `59527ad`. Web storage parsing now strictly distinguishes absent keys from malformed/corrupted strings (`parseInactivityDeadline`), and backward-clock manipulation is clamped across all state transitions.

---

## 2. Skills Applied

In accordance with `AGENTS.md` and `GEMINI.md`, the following skills were inspected and directly applied:

1. **`systematic-debugging`** (`.agents/skills/systematic-debugging/SKILL.md`):
   - *Phase 1 (Root Cause Investigation)*: Traced asynchronous data flow through `_startSession()`, `_restore()`, `_scheduleDeadline()`, `_resetTimer()`, and `_expire()`. Identified unvalidated boundary conditions where `saved` values are parsed directly from storage into `DateTime.fromMillisecondsSinceEpoch(saved!)`.
   - *Phase 2 (Pattern Analysis)*: Analyzed divergence between native (`SharedPreferences.getInt`) and web (`int.tryParse(window.sessionStorage.getItem(key))`). Found that malformed non-integer web strings return `null`, which causes `_restore()` to incorrectly treat corrupted storage as a brand new session and grant a fresh 15-minute window.
   - *Phase 3 (Hypothesis & Boundary Testing)*: Modeled time-travel attacks (forward/backward system clock shifts) against `DateTime.now()` and calculated timer scheduling implications.

2. **`verification-before-completion`** (`.agents/skills/verification-before-completion/SKILL.md`):
   - *Iron Law Application*: Executed full test and analyzer commands against Builder's active worktree before recording findings.
   - Ran `flutter test test/session_inactivity_test.dart` in `cowrie` (11/11 tests passed, exit code 0).
   - Ran `flutter analyze lib/core/security/ test/session_inactivity_test.dart` in `cowrie` (0 issues, exit code 0).
   - Recorded exact command outputs, timestamps, and commit states without speculative assertions.

3. **`ponytail`** (`.agents/skills/ponytail/SKILL.md`):
   - Formulated minimal, surgical remediation proposals (3-4 lines of clamping logic in `_restore` and `_scheduleDeadline`) without requiring architectural rewrites or new dependencies.

---

## 3. Detailed Technical Findings

### 3.1. Restart Persistence & Cold-Boot Hydration
- **Code Path**: `_restore(String userId, int generation)` in [`inactivity_guard.dart`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/cowrie/lib/core/security/inactivity_guard.dart#L92-L123)
- **Mechanism**:
  - `_loading` initializes to `true` when `userId != null`.
  - While `_loading` is active, `InactivityGuard` wraps `widget.child` in `ExcludeFocus` and `ExcludeSemantics`, and overlays a non-dismissible `ModalBarrier(dismissible: false, color: Colors.black54)` with a `CircularProgressIndicator`.
  - The stored deadline is read via `storage.read(_key(userId))`.
  - If a deadline was previously stored, `_scheduleDeadline()` evaluates `final remaining = _deadline!.difference(DateTime.now());`. If `remaining <= Duration.zero`, it executes `_expire()` immediately.
  - If no deadline was previously stored (`saved == null`), it initializes `DateTime.now().add(_timeout)` and writes it immediately.
- **Security Assessment**:
  - **No UI Flash**: The user cannot interact with or view protected content while the storage read is resolving.
  - **Cold-Start Expiration**: If the device was suspended or terminated and reopened past the 15-minute mark, access is immediately blocked.
  - **New Session Initialization**: Meets the specification that a genuinely new authenticated session initializes 15 minutes and is not misclassified as corrupted state.

---

### 3.2. Timestamp Validation & Anomaly Handling
- **Code Path**:
  ```dart
  final deadline = saved == null
      ? DateTime.now().add(_timeout)
      : DateTime.fromMillisecondsSinceEpoch(saved!);
  ```
- **Vulnerability Analysis (High Severity)**:
  1. **Far-Future Timestamps**:
     - If `saved` contains an integer far in the future (e.g. `DateTime.now() + 30 days` or `9223372036854775807`):
     - `DateTime.fromMillisecondsSinceEpoch(saved!)` accepts the value without bounds checking.
     - `remaining` is computed as 30 days.
     - `_timeoutTimer = Timer(remaining, _expire)` schedules an expiration 30 days later.
     - *Impact*: The inactivity guard is completely disabled, allowing an attacker with temporary local access or an unauthorized script to persist an unlocked session indefinitely.
     - *Contract Requirement*: [`SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md) Section 4.3 mandates: *"If stored values are null, negative, corrupted, or in the far future (>24h), enforce a fail-closed policy (treat as expired or display error barrier) rather than extending the session."*
  2. **Corrupted Non-Numeric Web Storage**:
     - In [`inactivity_storage_web.dart`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/cowrie/lib/core/security/inactivity_storage_web.dart#L3-L4):
       ```dart
       Future<int?> readDeadline(String key) async =>
           int.tryParse(window.sessionStorage.getItem(key) ?? '');
       ```
     - If `sessionStorage` has a non-integer corrupted string (e.g. `"corrupted_data"` or injection attempt), `int.tryParse` returns `null`.
     - In `_restore()`, `saved == null` is treated as a fresh session, granting a new 15-minute deadline.
     - Conflating "missing key (new session)" with "existing corrupted key" violates fail-closed security.
- **Recommended Remediation for Builder**:
  In `inactivity_guard.dart`:
  ```dart
  if (saved != null) {
    final now = DateTime.now();
    final parsed = DateTime.fromMillisecondsSinceEpoch(saved!);
    // Reject negative timestamps, pre-epoch dates, or deadlines > 24 hours in the future
    if (saved! < 0 || parsed.isAfter(now.add(const Duration(hours: 24)))) {
      _expire();
      return;
    }
  }
  ```

---

### 3.3. Storage Failures & Hardware Exception Handling
- **Code Path**:
  - [`inactivity_storage_native.dart`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/cowrie/lib/core/security/inactivity_storage_native.dart#L5-L15):
    Throws `StateError('Could not save inactivity deadline')` or `StateError('Could not remove inactivity deadline')` if `SharedPreferences` returns `false`.
  - [`inactivity_guard.dart`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/cowrie/lib/core/security/inactivity_guard.dart#L114-L121) and [lines 150-157](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/cowrie/lib/core/security/inactivity_guard.dart#L150-L157):
    `catch (_)` sets `_storageFailed = true` and `_loading = false`.
- **Barrier Enforcement**:
  - When `_storageFailed == true`:
    - Screen is covered with `ModalBarrier(dismissible: false, color: Colors.black54)`.
    - `AlertDialog` displays:
      - Title: `"Security check unavailable"`
      - Content: `"Could not save your session timer. Please sign out and try again."`
      - Action: Button `"Sign out"` invoking `_expire()`.
    - User input (`onPointerDown`, `onPointerHover`, `onPointerSignal`, keyboard keydown) is ignored due to `if (_storageFailed) return;`.
- **Security Assessment**:
  - Meets fail-closed criteria. Storage read/write failure prevents unauthorized access to protected data instead of granting an open session.
  - Verified by Builder's test: `storage failure blocks access instead of resetting the timer`.

---

### 3.4. Cross-User Isolation, Key Scoping & Account Purging
- **Code Path**:
  ```dart
  String _key(String userId) => 'inactivity_deadline_$userId';
  ```
- **Lifecycle Logic**:
  - `_startSession(String? userId)`:
    ```dart
    final previous = _userId;
    ...
    if (previous != null && previous != userId) {
      _queue(() => storage.remove(_key(previous))).catchError((Object _) {});
    }
    ```
- **Analysis**:
  - **Account Switching**: When User A signs out, `previous` is User A, and `storage.remove(_key('userA'))` is queued. When User B subsequently signs in, User B reads `_key('userB')`.
  - **Shared Device Protection**: User B never inherits User A's deadline, even if both users log in in rapid succession on the same device or browser profile.
  - **Test Verification**: Covered by `a different user does not inherit another user deadline` and `sign-out clears the deadline before the same user signs in again`.

---

### 3.5. Late Queued Operations & Concurrency Control
- **Code Path**:
  - Queue: `_storageQueue = _storageQueue.then((_) => operation());`
  - Generation: `final generation = ++_generation;`
- **Race Condition Analysis**:
  - If User A triggers a write (`storage.write(_key('userA'), ...)`), and before the async I/O resolves, User A signs out and User B signs in:
    1. `_startSession('userB')` increments `_generation` to `2`.
    2. User A's pending callback has captured `generation = 1`.
    3. When User A's future completes: `if (!mounted || generation != _generation) return;`.
    4. Because `1 != 2`, the state update is discarded.
    5. The write for User A completes in the queue, followed by the purge `storage.remove(_key('userA'))`, followed by User B's operations.
- **Security Assessment**:
  - Robust monotonic guard against async race conditions. Stale writes from previous sessions cannot clobber active sessions.

---

### 3.6. Clock Manipulation (Time-Travel Attacks)
- **Forward Clock Jump**:
  - When the system clock is advanced forward $\ge 15$ minutes:
    - `_deadline.difference(DateTime.now())` produces a negative duration ($\le 0$).
    - `_scheduleDeadline()` detects `remaining <= Duration.zero` and immediately calls `_expire()`.
    - Lifecycle listener `didChangeAppLifecycleState(AppLifecycleState.resumed)` performs the same check upon returning to the app.
    - *Result*: **Fails closed**.
- **Backward Clock Jump (Medium Risk)**:
  - When the system clock is set backwards (e.g. rolled back by 1 hour):
    - `_deadline.difference(DateTime.now())` produces a duration $> 15$ minutes (e.g., 1 hour 10 minutes).
    - `_scheduleDeadline()` schedules `_timeoutTimer` for that expanded duration.
    - *Risk*: A user can artificially extend their session window by rolling back the system clock before the 15-minute deadline expires.
- **Recommended Remediation for Builder**:
  In `_scheduleDeadline()`:
  ```dart
  if (remaining > _timeout) {
    // Clock moved backward or timestamp implausible; clamp to maximum timeout
    remaining = _timeout;
  }
  ```

---

### 3.7. Sign-Out Failure & Offline Resilience
- **Code Path**: `_expire()` in [`inactivity_guard.dart`](file:///C:/Users/Windows%2011/orca/workspaces/scholaris/cowrie/lib/core/security/inactivity_guard.dart#L193-L214)
- **Error Handling**:
  - When `ref.read(inactivitySignOutProvider)()` throws an exception (e.g., network disconnect, timeout, socket error):
    - `catch (_)` sets `_signOutFailed = true`.
    - `_expired` remains `true`.
    - `_signingOut` returns to `false`.
    - Dialog displays:
      - Title: `"Your session has expired"`
      - Content: `"We could not sign you out. Please try again."`
      - Action: Button `"Try again"` calling `_expire()`.
    - The underlying screen remains completely blocked by `ModalBarrier(dismissible: false)`.
- **Security Assessment**:
  - Offline network failure during sign-out fails closed. An attacker cannot induce an offline state to dismiss the expiration dialog and gain access to cached profile data.

---

### 3.8. Storage Keys & Values Exposure Analysis
- **Key Format**: `'inactivity_deadline_$userId'`
  - *Data Classification*: `userId` is an internal account UUID v4.
  - *Privacy Consideration*: In shared-device operating systems where preferences/local storage are accessible across users or profiles, raw UUIDs in storage keys constitute pseudonymous technical identifiers under RA 10173.
  - *Mitigation in Place*: The key is explicitly deleted from storage upon sign-out (`storage.remove(_key(previous))`).
- **Value Format**: Integer millisecond epoch timestamp (`deadline.millisecondsSinceEpoch`).
  - *Credential Verification*:
    - Plaintext passwords: **NONE (0 stored)**
    - JWT Access Tokens: **NONE (0 stored)**
    - Refresh Tokens: **NONE (0 stored)**
    - Session Cookies/Secrets: **NONE (0 stored)**
    - Personally Identifiable Information (PII): **NONE (0 stored)**
  - *Storage Engine*: Native uses `SharedPreferences` (app sandbox private storage); Web uses `sessionStorage` (tab-scoped memory, cleared on tab close).

---

### 3.9. Architectural Boundary: Client Locking vs. Server Token Revocation
- **Important Technical Distinction**:
  - `InactivityGuard` invokes `Supabase.instance.client.auth.signOut(scope: SignOutScope.local)`.
  - **`SignOutScope.local`** clears local authentication tokens stored in the device's secure storage/keychain.
  - It does **NOT** issue a network request to revoke or blacklist the JWT on the Supabase backend authentication server.
  - Therefore, `InactivityGuard` provides **client-side physical device access control** (mitigating shoulder surfing, unattended device abuse, and lab computer walk-away risks).
  - It does **NOT** represent server-side cryptographically enforced token revocation. If an adversary has already exfiltrated the raw JWT from the network layer, that JWT remains valid against backend RLS until its standard 1-hour expiration.

---

### 3.10. Privacy & Legal Compliance Boundaries (RA 10173)
- **Statutory Limitation**:
  - This security audit establishes only the technical operation of client-side timeouts, storage keys, and error-handling barriers.
  - It does **NOT** constitute legal certification or statutory compliance under Republic Act No. 10173 (Philippine Data Privacy Act of 2012) or National Privacy Commission (NPC) circulars.
  - Formal compliance requires comprehensive organizational, physical, and technical measures across the full data lifecycle.

---

## 4. Verification Evidence & Test Run Logs

### 4.1. Unit Test Suite Execution
- **Command**: `flutter test test/session_inactivity_test.dart` (executed in `C:\Users\Windows 11\orca\workspaces\scholaris\cowrie`)
- **Exit Code**: `0`
- **Output Log**:
  ```text
  00:00 +0: loading test/session_inactivity_test.dart
  00:00 +0: restored session past its inactivity deadline signs out
  00:01 +1: a different user does not inherit another user deadline
  00:01 +2: storage failure blocks access instead of resetting the timer
  00:01 +3: sign-out clears the deadline before the same user signs in again
  00:01 +4: inactivity warning fits a 360.0x800.0 viewport
  00:01 +5: inactivity warning fits a 440.0x956.0 viewport
  00:01 +6: inactivity warning fits a 1280.0x800.0 viewport
  00:01 +7: ordinary user activity postpones the warning
  00:01 +8: warns a signed-in user before 15 minutes of inactivity
  00:01 +9: stay signed in resets the warning and expiration
  00:01 +10: failed automatic sign-out keeps the screen blocked and offers retry
  00:01 +11: All tests passed!
  ```

### 4.2. Static Analyzer Verification
- **Command**: `flutter analyze lib/core/security/ test/session_inactivity_test.dart` (executed in `C:\Users\Windows 11\orca\workspaces\scholaris\cowrie`)
- **Exit Code**: `0`
- **Output Log**:
  ```text
  Analyzing 2 items...
  No issues found! (ran in 3.5s)
  ```

---

## 5. Required Remediations for Builder (`cowrie`)

Prior to final commit delivery:

1. **Add Far-Future & Corrupted Timestamp Clamping**:
   In `lib/core/security/inactivity_guard.dart` within `_restore`:
   ```dart
   if (saved != null) {
     final now = DateTime.now();
     final parsed = DateTime.fromMillisecondsSinceEpoch(saved!);
     if (saved! < 0 || parsed.isAfter(now.add(const Duration(hours: 24)))) {
       _expire();
       return;
     }
   }
   ```
2. **Defend Against Backward Clock Skew**:
   In `lib/core/security/inactivity_guard.dart` within `_scheduleDeadline`:
   ```dart
   var remaining = _deadline!.difference(DateTime.now());
   if (remaining > _timeout) {
     remaining = _timeout;
   }
   ```
3. **Add Web Non-Numeric Storage Guard**:
   In `lib/core/security/inactivity_storage_web.dart`:
   Ensure that a non-null string that fails parsing returns an explicit sentinel (or throws `FormatException`) rather than silently returning `null` so it does not falsely trigger a fresh 15-minute session.
