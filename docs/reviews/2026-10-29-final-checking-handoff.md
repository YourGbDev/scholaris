# Final checking handoff

## Latest update — October 29, 23:44 Manila

Owner chose Free (server-enforced lockout explicitly blocked) and CAPTCHA activation after Archi's compatible IPA. Supabase Auth audit database storage is enabled. Migration 0039 is committed live after independent review, fresh encrypted backup, eleven rollback cases and postchecks: client-fabricated audit writes are blocked; lifecycle/scholarship events are server-recorded; selected Auth events are sanitized; and active admins can toggle scholarship activation through a limited RPC. No real Auth API event has verified the mirror yet. Local app changes call the new RPC and prevent false audit success, but are not shipped. See IAS security backup status for hashes, evidence, and risks. No IPA/push performed.

## Latest live update — October 29, 22:49 Manila

Later update, 22:56: migration 0038_audit_log_mutation_privileges.sql is also applied and independently verified live after a fresh encrypted backup. It removes app-role audit UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER privileges while preserving existing inserts/reads and trusted maintenance. Actual denied mutation operations and preserved server-trigger logging passed in rollback-isolated live tests; 20 audit records remained. Client-event spoofing/authenticity and complete audit coverage remain open. Exact hash and evidence are in the IAS status document.

Migrations 0035_guard_profile_status.sql, 0036_sync_confirmed_auth_email.sql and 0037_admin_profile_audit.sql are now applied live to yqwbarzxpduzmtrxnrbm after verified backup/cloud copy, isolated partial restore, independent source review and a rolled-back live rehearsal. All eight combined live checks passed; a separate connection verified committed definitions/triggers/grants. Profiles/auth users/audit rows stayed 161/167/20. Direct execution did not establish migration-history bookkeeping. Exact source hashes and JSON evidence are in 2026-10-29-ias-security-backup-status.md.

Daily local encrypted backup plus Google Drive copy is verified; next task run is October 30 at 02:00 Manila while this Windows user is signed in and the computer is on. Drive must be running and signed in for cloud upload. Owner confirmed saving the recovery key in a phone note; note locking/reopening is not independently verified. Temporary plaintext restore-file cleanup remains blocked by automatic approval review.

CAPTCHA remains disabled pending coordinated compatible clients and activation. Server account lockout, complete audit integrity/coverage, live OTP/session checks, admin UI rehearsal and the new IPA/device run remain open. No new IPA/build/push was performed in this continuation. The historical preparation checklist below must be read with this update.

## Current local work

- The provider overview image is declared in `pubspec.yaml`. The image file is currently untracked and must be included in the build source.
- Provider screens no longer show the old 2024–2025 year in the edited views, and placeholder export actions say that export is unavailable.
- Password changes reject weak passwords and stop if the account changes during reauthentication.
- A native CAPTCHA view is implemented using WebView. It requires an HTTPS challenge page, a Turnstile site key, and `SCHOLARIS_CAPTCHA_ENABLED=true` at build time. It has not been tested on an iPhone.
- The iOS workflow has an optional `captcha_enabled` manual input, defaulting to false. Its public site key and challenge URL point to the Scholaris Turnstile widget and `https://scholaris-captcha.pages.dev/captcha_challenge`. The user added that hostname and the hosted widget showed success in a browser. No secret key belongs in this workflow.
- The CAPTCHA challenge page alone was uploaded to Cloudflare Pages. This does not deploy the landing page or provider portal.

## Required before claiming final readiness

1. Complete Cloudflare hostname setup and confirm the real CAPTCHA in both the localhost provider portal and the iPhone build. Coordinate enabling Supabase CAPTCHA with compatible client builds; older clients may fail authentication once enabled. The secret key must be entered privately in Supabase.
2. Implement and verify server-enforced progressive login lockout and CAPTCHA after repeated lockouts. The existing local lockout can be bypassed from another client.
3. Verify admin create, search, edit, activate/deactivate, lock/unlock, role assignment and enforcement against the live backend. Prepared migrations 0035 and 0036 are local until live execution is independently verified; do not assume migration history reflects manually applied SQL.
4. Verify OTP expiration, single use, attempt limits, resend cooldown, verified email changes, server password policy, and other-session revocation on change and reset.
5. Verify the audit trail records all required events, correct actors and results without secrets, and is admin-only and not editable.
6. Establish scheduled encrypted database backups and demonstrate restoration into a separate authorized environment. The earlier check found the Supabase Free plan did not include project backups.
7. Build and install the exact IPA to be presented. Rehearse the full live cycle: organization publishes, student applies with documents on the phone, reviewer endorses, organization decides, and student sees the saved result and notification. Test inactivity and cross-tab logout on actual clients.
8. Confirm all third-increment remarks, presentation logistics, and live sample data.

## Verification on October 29

- The stable offline Flutter suite passed 1,138 tests; 9 live tests were skipped. It ran before the final iOS workflow-only edit. The mobile CAPTCHA view has not been exercised by those desktop tests.
- Mobile CAPTCHA protocol and gate tests passed. Static analysis passed for the mobile CAPTCHA files.
- The real localhost and hosted Turnstile widgets showed success in a browser. This is not a Supabase validation or iPhone test.
- A release web build with the public site key succeeded after the native WebView dependency was added.
