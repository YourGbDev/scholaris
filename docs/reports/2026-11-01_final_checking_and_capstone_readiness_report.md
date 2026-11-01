# Scholaris — System Readiness, Academic Defense & Capstone Handoff Report (Reconciled V2)

**Document ID:** `SCHOLARIS-REP-2026-11-01-V2-RECONCILED`  
**Date:** November 1, 2026  
**Author / Candidate:** Gilbert Bulado Jr. (Student ID #71)  
**Academic Section:** BSIT-3103  
**Institution:** College of Information and Communications Technology  
**Project Title:** Scholaris — Intelligent Scholarship Matching & Grant Administration Platform  
**Target Roles:** Gilbert Bulado Jr. (Presenter), Codex (UI/UX Lead & Deployment Operator), Academic Panels  

---

## 1. Executive Summary & Audit Reconciliation

This engineering report establishes the reconciled verification and implementation record for the **Scholaris** platform following the independent audit conducted on November 1, 2026 (`docs/reviews/2026-11-01-independent-readiness-audit.md`).

This report supersedes `SCHOLARIS-REP-2026-11-01-V1`. In accordance with project governance and academic standards:
1. **Zero Synthetic State & Honest Operations:** All simulated backup operations, fabricated checksums, and mock 1.2-second restore routines have been completely excised from the codebase. The Admin Console Database Backup & Recovery interface now honestly reflects genuine backup tooling (`tools/run_scholaris_backup.ps1`), verified encrypted archive artifacts (`ScholarisBackup/archives/*.scb`), and verified isolated disaster recovery evidence (PostgreSQL 18.4 cluster, October 29, 2026).
2. **Authoritative Cross-Client Account Unlock:** Local-only unlock state has been replaced by authoritative backend state management via migration `0040_admin_unlock_account.sql`, resetting `public.login_attempts` and logging immutable events to `public.audit_logs`. Unlocking an account from an admin console now clears the lockout on separate student client devices.
3. **Preservation of Release Source & CAPTCHA Integrity:** Work was executed in an isolated worktree (`whelk-audit`) branched from the authoritative release source commit `1804904c45594803989e5d7ec83e5b3ec09d25dd` (`codex/student-tour-ipa-handoff`, pubspec `1.0.0+17`). Newer CAPTCHA integrations, reauthentication workflows, current-password verification on email changes, bundled Geist typography, and student tour integrations were strictly preserved.
4. **Evidence Matrix Replaces Blanket Claims:** Unsupported blanket readiness percentages (e.g. "100% ready") and speculative grade predictions ("1.0 Grade Target") have been replaced with a rigorous **Evidence Matrix** distinguishing between implemented, locally tested, live verified, device verified, and pending states.
5. **Technical Boundary Disclosure:** Hosting and platform constraints under the Supabase Free tier (lack of native PITR, absence of web dashboard backup triggers, and lack of custom GoTrue password hooks) are disclosed honestly.

---

## 2. Source Identity & Workspace Reconciliation Record

| Property | Value | Notes |
| :--- | :--- | :--- |
| **Active Worktree** | `whelk-audit` (`C:\Users\Windows 11\orca\workspaces\scholaris\whelk-audit`) | Isolated git worktree dedicated to readiness reconciliation |
| **Active Branch** | `ai/architect-readiness-reconcile` | Dedicated feature branch branched from `codex/student-tour-ipa-handoff` |
| **Base Commit** | `1804904c45594803989e5d7ec83e5b3ec09d25dd` | Current release HEAD; pubspec version `1.0.0+17` |
| **Older Reference** | `whelk` (`ee15361387ca296c5742bb24d51b8453d50be795`) | Older Archi checkout; used strictly as read-only reference; not merged wholesale |
| **Common Ancestor** | `bc700a4f9bec95e2b32be44faa60240f8614438f` | Branch point between historical streams |
| **SIA Deliverables** | 5 Vector PDF Diagrams on Desktop/Downloads | Confirmed submitted; untouched during this engineering sprint |
| **Production Target** | Supabase Project `yqwbarzxpduzmtrxnrbm` | Zero live destructive operations or unapproved mutations executed |

---

## 3. Comprehensive Evidence Matrix

| Component / Requirement | Implementation Status | Local Test Evidence | Live DB / Staging Evidence | Device Status | Technical Boundaries & Disclosures |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Indicator A: Account Lockout & Admin Unlock** | **Implemented** | `test/admin_users_tab_test.dart` (9/9 PASS, exit 0)<br>`test/ias_security_test.dart` (27/27 PASS, exit 0) | Migration `0040_admin_unlock_account.sql` prepared for SQL Editor application | Pending live admin console sync | Cross-client lockout clears via `login_attempts` reset; Supabase Free tier does not support server-side GoTrue password hook |
| **Indicator B: OTP Verification & Email Change** | **Implemented** | `test/verify_email_screen_test.dart` (11/11 PASS, exit 0)<br>`test/account_settings_screen_test.dart` (24/24 PASS, exit 0) | Staging auth schema supports 2-token email change | Tested on headless browser harness | 3-attempt OTP limit is widget-enforced (client-only); server rate limiting handled by Supabase Auth service |
| **Indicator C: Password Validation & NIST Complexity** | **Implemented** | `test/ias_security_test.dart` (Tests 1–5 PASS, exit 0) | Client regex validation across all registration & reset screens | Functional across all viewports | Enforces length >= 8, uppercase, lowercase, digit, and special symbol |
| **Indicator D: Progressive Account Lockout** | **Implemented** | `test/ias_security_test.dart` (Tests 6–10 PASS, exit 0) | Backed by `public.login_attempts` calculation window | Functional in local tests | Lockout backoff: 3rd fail (1 min), 4th fail (5 min), 5th fail (15 min); standard timings preserved |
| **Indicator E: Role-Based Access Control (RBAC)** | **Implemented** | `test/ias_security_test.dart` (RBAC suite PASS, exit 0) | RLS policies on `profiles`, `scholarships`, `applications` | Deep-link redirects fail closed | Provider role partitioned into Reviewers (score only) and Org Admins (approve/reject) |
| **Indicator F: 15-Minute Session Inactivity** | **Implemented** | `test/session_inactivity_test.dart` (29/29 PASS, exit 0) | Fail-closed storage (`TabScopedLocalStorage` / `SharedPreferences`) | Tested on web & simulator | Pre-expiry warning is a 1-minute modal countdown before expiration, not a persistent ticking counter |
| **Indicator G: RA 10173 Privacy & Column Minimization** | **Implemented** | View query asserts in security test suite | `public.provider_applicant_profiles` security barrier view | Verified in provider table views | Technical minimization strips phone, email, gender, birth date; does not constitute formal legal compliance |
| **Indicator H: Database Backup & Recovery** | **Implemented** | `test/admin_backup_screen_test.dart` (3/3 PASS, exit 0) | Genuine Oct 29 PostgreSQL 18.4 restore (15 tables, 161 profiles, 167 users, 0 errors) | Admin Console Tab 9 operational | Supabase Free tier lacks native PITR/console backup; host PowerShell pipeline (`tools/run_scholaris_backup.ps1`) used |
| **AppDev: Student Discovery & GWA Matching** | **Implemented** | Filter & GPA threshold widget suites | Live scholarships table queries | Functional on mobile viewports | GPA qualification dynamic against `scholarships.min_gpa` |
| **AppDev: 3-Role Transaction Cycle** | **Implemented** | Application lifecycle integration suites | Multi-role RLS transitions (`under_review` -> `approved`) | Functional in browser console | Pending formal live panel dry run with live mailboxes |
| **AppDev: Atomic Capacity Enforcement** | **Implemented** | Transaction concurrency suites | Row-level locking (`FOR UPDATE`) in `0026_organization_controls_slots_schools.sql` | Enforced at DB level | Dynamic count of approved/awarded applications against `scholarships.slots` (not literal column decrement) |
| **AppDev: Decision Letter Generation** | **Implemented** | Decision letter PDF unit tests | Generates verifiable reference numbers | Functional on desktop & mobile | PDF generation executes client-side with clean layout |
| **AppDev: Viewport Hardening** | **Implemented** | Verified at 360×800, 440×956, 1280×800 | Zero `RenderFlex` overflows across all primary flows | Verified in headless tests | Bundled Geist Sans typography and 26px squircle card tokens enforced |
| **SIA: 5 Vector Architectural Diagrams** | **Submitted** | Vector PDF compilation verified | Standalone high-res documents submitted to faculty | Confirmed on file | Diagrams cover Security, Transaction, Component, Cloud Infrastructure, and Auth Architecture |

---

## 4. Detailed Implementation & Architectural Fixes

### 4.1. Backup, Recovery & Disaster Recovery Honest Interface (Indicator H)
* **Problem in V1:** The earlier backup screen contained fabricated snapshot lists, hardcoded fake checksums, and a simulated 1.2-second restore routine that claimed "28 tables verified" without touching any database.
* **Reconciled Implementation (`lib/admin/screens/admin_backup_screen.dart`):**
  * Excised all mock timers, fake progress bars, and simulated success routines.
  * Honestly discloses the Supabase Free plan hosting boundary: native PITR and web dashboard backup triggers are unavailable on the Free tier.
  * Documents the genuine host-side backup pipeline executed via Windows Task Scheduler running `tools/run_scholaris_backup.ps1` (which invokes `tools/scholaris_backup.py` with AES-256-GCM encryption and Google Drive cloud mirroring).
  * Presents genuine verified encrypted backup archives from repository storage:
    * `scholaris-20261031T180002310505Z.scb` (651.7 KB, SHA-256: `5870a48b36...`)
    * `scholaris-20261029T152716281889Z.scb` (635.1 KB, Pre-migration 0039 baseline)
    * `scholaris-20261029T140248455668Z.scb` (632.2 KB, Verified recovery archive)
  * Implemented **Production Recovery Guard**: Disallows live restores over the production database cluster (`yqwbarzxpduzmtrxnrbm`) and provides the verified isolated staging restoration procedure targeting local PostgreSQL 18.4 (`127.0.0.1:55479`), referencing the verified October 29 milestone (15 public tables, 161 profiles, 167 auth users restored with 0 errors).
  * Applied visual tokens from `admin_theme.dart`: bundled Geist typography and `kSoftCardDecoration` (26px squircle radius).
  * **Test Verification:** `test/admin_backup_screen_test.dart` passes all 3 tests cleanly (exit 0).

### 4.2. Authoritative Cross-Client Account Unlock (Indicator A)
* **Problem in V1:** Account unlock only cleared local in-memory and `SharedPreferences` state on the administrator's browser, failing to clear the student's lockout on their mobile device or persist an authoritative database record.
* **Reconciled Implementation:**
  * **Migration `0040_admin_unlock_account.sql`:**
    * Created `public.admin_unlock_account(p_email text)` RPC with `SECURITY DEFINER` and strict `public.is_admin()` verification.
    * Inserts an authoritative success record into `public.login_attempts` with `now()`, resetting the calculation window of `public.get_login_lockout_status(p_email)` to zero failed attempts for all clients.
    * Inserts an immutable audit record in `public.audit_logs` capturing administrator UUID, email, target email, timestamp, and action `ADMIN_USER_UNLOCKED`.
  * **Service Hardening (`lib/core/security/login_lockout_service.dart`):**
    * Added `checkLockoutRemote(email)` to query remote lockout state from `public.login_attempts` and synchronize local state.
    * Added `unlockAccount(email, adminEmail: ...)` invoking the authoritative RPC and clearing local lockout timers.
  * **Client Entrypoints Updated (`login_screen.dart`, `admin_login_screen.dart`, `provider_login_screen.dart`):**
    * Prior to authentication, each screen queries `checkLockoutRemote(email)`. If an admin has unlocked the account, the client immediately discovers the reset state, cancels local lockout timers, and permits login.
  * **Admin Console Interface (`admin_users_tab.dart`, `admin_users_provider.dart`):**
    * Accounts with 3+ failed logins render an amber `Locked (3+ Failed Logins)` status pill.
    * Added "Unlock Account" popup action with confirmation dialog that executes authoritative unlock and updates audit logging.
  * **Technical Boundary Disclosure:** Documented that while database-backed lockout status is synchronized across all Scholaris clients, Supabase Free tier hosting does not support custom server-side GoTrue password-verification hooks (which require Enterprise/custom auth daemon configurations).
  * **Test Verification:** `test/admin_users_tab_test.dart` passes all 9 tests cleanly (exit 0), including explicit cross-client unlock assertions.

### 4.3. Preserved CAPTCHA, Reauthentication & Email Change Integrity (Indicator B)
* **Problem in V1:** Older checkout files lacked CAPTCHA integration and omitted current-password reauthentication on email updates.
* **Reconciled Implementation:**
  * Sourced directly from current release HEAD `1804904`.
  * Mandatory CAPTCHA acquisition (`acquireCaptcha(context)`) preserved across student, admin, and provider login screens, as well as password reset and registration.
  * Email change flow in `account_settings_screen.dart` strictly requires:
    1. Input of the user's current password.
    2. Server reauthentication via `signInWithPassword(email, currentPassword)`.
    3. Input and validation of the new email address.
    4. Two-token confirmation workflow (confirmation code sent to old email, confirmation code sent to new email).
  * **Test Verification:** `test/account_settings_screen_test.dart` passes all 24 tests cleanly (exit 0).

### 4.4. OTP Verification Attempt Limiting & Cooldown (Indicator B)
* **Problem in V1:** Passing tests only verified static rendering and back navigation, without testing failed attempts, cooldown expiration, or attempt counter resets.
* **Reconciled Implementation (`lib/features/auth/presentation/verify_email_screen.dart`):**
  * Added `_failedAttempts` state tracking: after 3 invalid code submissions, the verification button is disabled with an explicit error message prompting the user to request a new code.
  * Added 60-second visual resend cooldown (`Resend code in 59s...`) preventing SMTP flooding.
  * Resending a verification code resets `_failedAttempts = 0`, re-enabling the verification button for fresh attempts.
  * Added `clearSnackBars()` calls before displaying alerts to avoid message stacking.
  * **Disclosed Boundary:** Attempt limiting on this screen is enforced client-side at the widget level; server-side rate-limiting is handled by Supabase Auth's built-in SMTP rate limits.
  * **Test Verification:** `test/verify_email_screen_test.dart` expanded with comprehensive tests for 3 failed attempts, lockout disable, and resend reset, passing all 11 tests cleanly (exit 0).

### 4.5. Inactivity Guard Warning Clarification (Indicator F)
* **Problem in V1:** Claimed a "ticking countdown banner" was present throughout the session.
* **Reconciled Architecture:** The 15-minute inactivity guard operates silently in the background via `InactivityGuard` listening to pointer and keyboard events. When 60 seconds remain before expiration, a modal warning dialog appears with a 1-minute countdown offering the user an active "Stay Logged In" extension button or automatic logout upon expiration.
* **Test Verification:** `test/session_inactivity_test.dart` passes all 29 tests cleanly (exit 0).

### 4.6. Atomic Capacity Enforcement Clarification (AppDev Track)
* **Problem in V1:** Claimed a literal column decrement (`slots - 1`) was executed in the database.
* **Reconciled Architecture:** Migration `0026_organization_controls_slots_schools.sql` enforces atomic capacity via pessimistic row-level locking (`SELECT ... FOR UPDATE` on `scholarships`) and dynamically computing whether the count of active `approved` and `awarded` applications has reached `scholarships.slots`. Uncapped scholarships (`slots IS NULL`) are handled correctly without synthetic caps.
* **Test Verification:** Verified via concurrency and transaction lifecycle suites.

### 4.7. Reconciled Database Migration Sequence
The database migration roadmap has been completely reconciled from `0001` through `0040`:
* `0001` to `0022`: Core initial schema, scholarship discovery, applications, provider policies, and storage security.
* `0023` to `0027`: Transaction cycle persistence, organization review cycle, preserved award transitions, organization slot controls, and individual provider lifecycle.
* `0028` to `0033`: Student onboarding recovery, support ledgers, review requests, and safety reports.
* `0034` to `0036`: Role restriction on signup, profile status guards, and confirmed auth email synchronization.
* `0037` to `0039`: Admin profile audit, audit log mutation privilege restrictions, and trusted audit events.
* `0040_admin_unlock_account.sql` *(Newly Prepared)*: Authoritative admin account unlock RPC and immutable audit event logging.

---

## 5. Verification Commands Run & Exact Results

All verification commands were executed directly inside the isolated worktree `C:\Users\Windows 11\orca\workspaces\scholaris\whelk-audit`:

### 5.1. Automated Test Suites (All 103 Tests PASS)
```powershell
flutter test test/session_inactivity_test.dart test/ias_security_test.dart test/account_settings_screen_test.dart test/admin_users_tab_test.dart test/verify_email_screen_test.dart test/admin_backup_screen_test.dart
```
* **Exit Code:** `0`
* **Result Summary:**
  * `test/session_inactivity_test.dart`: 29 passed (inactivity deadlines, storage corruption handling, fail-closed logout).
  * `test/ias_security_test.dart`: 27 passed (NIST password complexity, progressive lockout, RBAC navigation).
  * `test/account_settings_screen_test.dart`: 24 passed (current-password reauthentication, 2-token email change, session preservation).
  * `test/admin_users_tab_test.dart`: 9 passed (locked account badge rendering, authoritative unlock, audit logging).
  * `test/verify_email_screen_test.dart`: 11 passed (6-digit formatting, 3-attempt disable, 60s cooldown, resend counter reset).
  * `test/admin_backup_screen_test.dart`: 3 passed (honest schedule display, CLI instruction disclosure, Production Recovery Guard).
  * **Total Passing Tests:** **103 / 103 tests passed** with zero failures.

### 5.2. Scoped Static Analysis (0 Issues)
```powershell
flutter analyze lib/admin/screens/admin_backup_screen.dart lib/core/security/login_lockout_service.dart lib/features/admin/presentation/admin_login_screen.dart lib/features/admin/presentation/admin_users_provider.dart lib/features/admin/presentation/admin_users_tab.dart lib/features/auth/presentation/login_screen.dart lib/features/auth/presentation/verify_email_screen.dart lib/features/provider/presentation/provider_login_screen.dart test/admin_backup_screen_test.dart test/admin_users_tab_test.dart test/verify_email_screen_test.dart
```
* **Exit Code:** `0`
* **Output:** `Analyzing 11 items... No issues found! (ran in 3.6s)`

### 5.3. Full Library Static Analysis (0 Issues)
```powershell
flutter analyze --no-pub lib
```
* **Exit Code:** `0`
* **Output:** `No issues found!`

---

## 6. Changed Files & Specific Contributions

| File Path | Nature of Change | Architectural Purpose |
| :--- | :--- | :--- |
| `supabase/migrations/0040_admin_unlock_account.sql` | **New File** | Authoritative active-admin-only RPC to reset failed login attempts and log immutable audit event |
| `lib/admin/screens/admin_backup_screen.dart` | **New File** | Honest backup & disaster recovery console screen utilizing bundled Geist and 26px squircle tokens |
| `test/admin_backup_screen_test.dart` | **New File** | Widget tests verifying honest schedule display, CLI instructions, and Production Recovery Guard |
| `lib/core/security/login_lockout_service.dart` | **Modified** | Added `checkLockoutRemote`, `isAccountLockedRemote`, and authoritative `unlockAccount` calling RPC |
| `lib/features/admin/presentation/admin_users_tab.dart` | **Modified** | Added "Locked (3+ Failed Logins)" badge and "Unlock Account" confirmation action |
| `lib/features/admin/presentation/admin_users_provider.dart` | **Modified** | Added audit logging invocation across user create, edit, deactivate, and delete actions |
| `lib/features/auth/presentation/verify_email_screen.dart` | **Modified** | Added 3-attempt failure tracking, button disable, 60s cooldown, and resend counter reset |
| `test/verify_email_screen_test.dart` | **Modified** | Added test coverage for 3 consecutive failed attempts and resend attempt counter reset |
| `test/admin_users_tab_test.dart` | **Modified** | Added test coverage for locked badge rendering and authoritative unlock audit event |
| `lib/features/auth/presentation/login_screen.dart` | **Modified** | Checks remote lockout status prior to sign-in; added mounted check |
| `lib/features/admin/presentation/admin_login_screen.dart` | **Modified** | Checks remote lockout status prior to sign-in; added mounted check |
| `lib/features/provider/presentation/provider_login_screen.dart` | **Modified** | Checks remote lockout status prior to sign-in; added mounted check |

---

## 7. Remaining Live & Device Verification Protocol

The following items represent operational, live-environment, and physical-device verifications that must be completed prior to the academic defense:

1. **Production Migration Deployment (Designated Operator Codex):**
   * Apply `supabase/migrations/0040_admin_unlock_account.sql` to the live Supabase project `yqwbarzxpduzmtrxnrbm` via the Supabase Dashboard SQL Editor.
   * Run post-check query to verify execution permissions: `SELECT has_function_privilege('authenticated', 'public.admin_unlock_account(text)', 'execute');`.
2. **Cross-Device Lockout & Unlock Rehearsal:**
   * Step 1: On student client (mobile app or browser tab 1), enter 3 incorrect passwords for a test account to trigger progressive lockout.
   * Step 2: Observe lockout banner (`Account locked due to consecutive failed attempts`).
   * Step 3: On administrator client (browser tab 2), navigate to Admin Console > Users Tab, locate test account, and confirm amber `Locked (3+ Failed Logins)` status badge.
   * Step 4: Click "Unlock Account" in menu and confirm dialog.
   * Step 5: On student client, attempt login with valid credentials; verify immediate successful authentication without waiting for timer expiration.
3. **End-to-End SMTP Mail Delivery & Confirmation:**
   * Verify actual email delivery of 6-digit signup OTP verification codes and password recovery codes to live test mailboxes (`@gmail.com` / `@yahoo.com`).
   * Verify two-token email-change confirmation delivery to both old and new email addresses.
4. **Physical Device Verification (iPhone 16 Pro Max):**
   * Verify rendered typography (bundled Geist Sans), responsive padding, and touch target accessibility (minimum 44×44 pt).
   * Verify Turnstile CAPTCHA mobile webview interaction during registration and login.
   * Verify 15-minute inactivity warning dialog behavior across iOS app backgrounding and foreground resumption.
5. **Full Three-Role Lifecycle Dry Run:**
   * Student submits application with uploaded PDF document.
   * Reviewer logs in, accesses column-minimized profile, and submits evaluation rubric (`under_review`).
   * Organization Admin reviews endorsement and issues final approval.
   * Verify atomic capacity enforcement against grant slots.
   * Verify real-time generation of decision letter with reference code.
   * Verify disbursement record generation.

---

## 8. Conclusion

By completely removing simulated operations, implementing authoritative cross-client lockout management, preserving release-branch CAPTCHA and authentication integrity, enforcing strict visual tokens, and establishing a verified 103-test passing suite with zero analyzer issues, the Scholaris platform is rigorously reconciled and defensively prepared for faculty evaluation.
