# Final checking readiness review

Reviewed 28 October 2026 against the supplied Application Development final-checking PDF and IAS1 requirements document. Final checking is scheduled for 4–6 November 2026, with the student's assigned evaluator. Confirm the exact appointment and evaluator from the official list.

**Status: not yet verified ready.** This is a local source review and a targeted test, not a live security assessment, a device rehearsal, or proof of deployment. The source tree has substantial existing uncommitted work; it may differ from the installed IPA and the live backend.

## Update for the 29 October test

- **Live inspection and authorized fix, 28 October:** project `yqwbarzxpduzmtrxnrbm` is marked production; the owner says its accounts are demos. The original live signup trigger accepted client-supplied `admin` metadata and the original owner-insert profile policy checked only user ID. The owner explicitly authorized applying the fix without a full backup. The previous definitions were saved in `2026-10-28-signup-rules-before-change.sql`; they are not a data backup and restoring them reintroduces the flaw.
- A transaction applying the behavior of `0034_restrict_signup_roles.sql` succeeded in the Supabase SQL editor, with baseline and post-change checks. The migration source SHA-256 is `18C5F815C71F1B50B242AB8E3F5C2FFE9CDE6583F8186AEED57CFFF8E1CBE944`. This was a manual SQL editor execution and is not evidence that Supabase migration history was updated; do not blindly reapply it. An independent catalog check confirmed the restricted function and sole INSERT policy. A live database transaction created temporary student, provider and admin-request users, verified their roles, verified an authenticated owner could not insert an admin profile but could insert a student profile, and rolled all temporary records back. Profile count remained 161 and admin profile count remained 8; the dashboard and final query showed 167 auth users. These counts are not a content-level comparison.
- This verifies the live database trigger and policy, not the full Supabase Auth signup API, email confirmation, or a phone/browser signup flow. Existing admin profiles remain unchanged and require owner review; their count does not establish misuse.
- Supabase's backup page says the Free plan does not include project backups. CAPTCHA is disabled. Supabase session inactivity is set to never and its session controls are shown as Pro-only. New-user email confirmation and secure email change are enabled; the server setting to require the current password when updating is disabled. These are configuration observations, not end-to-end tests.
- Local source now includes a 15-minute inactivity warning and sign-out, password-complexity validation in account settings, and removal of an unsupported "2FA Active" label. The inactivity timer is client-side and has not been verified after a full app restart, in a real browser, or on an iPhone.
- The full offline Flutter suite passed 1,098 tests with 9 skipped on the follow-up run. Seven focused inactivity tests, including three widget viewport sizes, also passed. Widget tests do not replace a real-browser or device check. Earlier failures were traced to four outdated navigation expectations and an overflow in a development preview; the tests were updated for the approved navigation and the preview overflow fixed.
- The local release web build succeeded and opened to the onboarding screen in the in-app browser. This does not verify login, authenticated portal workflows, the inactivity warning, or remote deployment.
- Signup role restriction is **applied and database-tested live** as described above. Continue to verify the end-to-end signup and role flows using the app. CAPTCHA, server-enforced lockout, account status restrictions, and the remaining IAS checklist are separate work.
- An existing Flutter IPA does not contain these unbuilt source changes. A new authorized iOS build and installation are required before testing them on the phone.
- CAPTCHA, backend-enforced lockout, verified email changes, complete security auditing, and backup/restore evidence remain open. These require work beyond the local changes above.
- **Later local work:** CAPTCHA challenge plumbing now covers sign-in, signup, recovery and relevant account actions, but CAPTCHA remains disabled on the live service and no real provider keys or HTTPS host exist yet. Enabling it prematurely can lock out older clients. A local change-email flow and two database migrations were prepared and locally tested; they are not deployed or proven against live email templates. The administrator signup path no longer reports simulated success when signup fails. See `2026-10-28-web-deployment-preparation.md` for deployment blockers and activation order.

## Real-device rehearsal on 29 October

1. Identify the exact installed build and intended backend. Prepare separate student, organization admin, reviewer, and platform admin accounts without putting credentials in this document. Confirm email inbox access and connectivity.
2. Have the organization publish an available scholarship. On the phone, sign in, locate it, submit the required packet, and record its application identifier.
3. As a separate reviewer, endorse that same application. As organization admin, approve or reject it. Confirm the student sees the matching status, notification, and decision. Check capacity and the persisted record.
4. Demonstrate verification and password recovery with controlled accounts. Test bad-password lockout and honestly explain its current local enforcement. Test cross-tab logout with the same account, direct URLs, and browser back navigation.
5. If a new build containing the timeout is installed, leave the account inactive for 14 minutes, check the warning, then wait one more minute for sign-out. Repeat once using Stay signed in. Record any errors and retry behavior.
6. Review the admin logs for each demonstrated action and compare them against IAS A–H. Record missing entries. Verify backup schedule and restore capability using an authorized isolated environment; do not restore over the live project for the demonstration.
7. Record each result as pass, fail, or untested with device/build, role, time, and steps. Do not include passwords, codes, personal documents, or tokens in the notes.

## Application Development

| Requirement | Current evidence and remaining work |
| --- | --- |
| Previous third-increment remarks | The owner says the third-increment check was already good. No outstanding specific corrections were reported. |
| Full cycle, backend, database and roles | The project implements a student application and organization/reviewer/admin workflow. Complete a fresh live rehearsal: provider publishes, student applies on the actual phone, reviewer endorses, organization admin decides, and the student sees the result. Verify accounts, uploaded files, database records, and notifications. |
| UI and mobile demonstration | Rehearse the intended current build on the phone and desktop, with the actual backend and network. Source changes do not prove the installed IPA contains them. |
| Project title and technology | The owner confirms Flutter is approved. Confirm the presentation matches the approved project title. |
| Security | IAS A–H below include outstanding items. Prepare demonstrations of actual controls; do not present planned functionality as working. |
| Real-time samples | Prepare appropriate live demo data and accounts. Obtain consent for any actual personal documents, or agree with the evaluator on safe sample data. Do not publish credentials. |

## IAS1 A–H

| Section | Status | Evidence and next step |
| --- | --- | --- |
| A — core system and access | Partial / unverified | Separate role surfaces, account search, and management code exist. Local admin signup no longer creates simulated users on failure; live creation still needs testing. A local status guard is not deployed and does not establish complete session enforcement. Verify each create, edit, activate/deactivate, lock/unlock and role assignment against the live system. |
| B — OTP and account | Partial / gaps | Signup and recovery OTP screens and a resend cooldown exist. A student change-email flow and confirmed-email profile sync were prepared locally; the migration and email template changes are not deployed or end-to-end tested, and other roles need review. Verify server expiry, attempt limits, one-time use and resend behavior with controlled accounts. |
| C — passwords | Partial / unverified | Client complexity rules and a current-password check exist. Server-side enforcement and live hashing configuration require verification. Password change attempts to revoke other sessions, but the code can continue when revocation fails; test other sessions and access-token expiry after both change and reset. |
| D — login attempts | Gap | Login checks local app state, then calls Supabase password authentication directly; `checkLockoutRemote` exists but the inspected login path does not call it. Local preferences can be bypassed by another client or device; this does not establish server-enforced lockout. CAPTCHA after repeated lockouts was not found. Implement and test trusted server-side enforcement and CAPTCHA, or obtain a specific instructor-approved exception. Current durations are 5/15/60 minutes, while 1/5/15 is stated as recommended rather than mandatory. |
| E — sessions | Partial | Same-account cross-tab logout code passed the production-script local harness (69 checks); different accounts remained isolated in that harness. A 15-minute inactivity warning and local sign-out were added in source and widget-tested. Test real browser tabs, app restart, and the intended iPhone build; this is not a backend-enforced timeout. |
| F — log trail | Partial / unverified | Audit-log schema, admin view, and event calls exist. Verify each required event, result, timestamp, module, available IP, restricted read access, and absence of secrets using actual events. Some logging is best-effort and can fail silently, so completeness is not established. |
| G — validation | Partial / unverified | Client validation and database constraints exist for some paths. Verify each listed validation at the server boundary, particularly roles, account status, sessions, OTPs, and password policy. Confirm safe errors and sensitive-action confirmations. |
| H — backup and recovery | Unverified | A runbook mentions snapshots and restore commands; this does not demonstrate a scheduled backup, secure storage, or a successful restore. Verify actual provider plan and schedule, backup coverage and access, and restore a known backup to an isolated authorized environment. Establish how an administrator can initiate recovery; do not run destructive restore commands against the live project as a demonstration. |

## Verification performed in this review

- `node tools/test_tab_scoped_auth.mjs`: 69/69 checks passed against `web/tab_scoped_auth.js` in the local harness. This is not a live multi-tab browser rehearsal.
- Inspected relevant current source, migration 0011, and existing project notes. Remote database configuration and later policy changes were not independently inspected.
- Initial Flutter commands stalled because the SDK needed access outside the workspace. On the follow-up pass, Flutter 3.47.1 ran with that access; the focused IAS security suite passed 26 tests, the account/inactivity checks passed, and the targeted analyzer reported no issues. Phone and live-backend tests remain pending.

## Practical order before presentation

1. Confirm the approved title, evaluator and exact schedule.
2. Address the security gaps: trusted lockout and CAPTCHA, change-email verification, inactivity expiry, administrator account lifecycle, and dependable audit coverage. Check deployed configuration and OTP behavior, and test revocation.
3. Verify scheduled backups and rehearse restoration safely in an isolated environment.
4. Reconcile the intended app source, installed IPA, and live database migrations. Build/install only through the authorized release process.
5. Rehearse the complete student/provider/reviewer/admin cycle with real backend data, then perform the security demonstration and record results for A–H.

The older `demo_checklist.md` contains historical claims and embedded demo credentials; do not distribute it as a current readiness certificate. Treat any exposed credentials as potentially compromised and assess whether they need rotation with the account owner.
