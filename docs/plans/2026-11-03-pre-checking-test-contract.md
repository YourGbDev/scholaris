# November 3 pre-checking contract for Arki

## Objective and source gate

Prepare the November 4 checking and the student's independent rehearsal. Coordinate four Orca worktrees against ONE exact committed source. Do not build the next IPA before integrating fixes and completing the evidence review.

The current implementation checkout is `codex/auth-tour-polish`, based on `b4b6e0d`, at `C:/Users/Windows 11/.codex/worktrees/auth-tour-polish/scholaris`. It contains uncommitted quiet-student polish, bookmark fixes, working profile editing and chat introduction/new artwork. Record the actual final source SHA after the user-authorized integration; do not treat b4b6e0d or an old IPA as containing these changes. Inspect `git status`, branch and SHA first. Preserve unrelated work and archives. Never cherry-pick whole historical readiness branches without comparing source.

Read AGENTS.md in each worktree. Keep bundled Geist, compact typography, shared content-card tokens, neutral student canvas and friendly Home mascot. Home/tour: male Ariel, female Ari. Chat uses the other companion: male/unset student Ari; female student Ariel. AI conversation remains Coming soon; QR and upload launch existing tools, not automated eligibility or AI document edits.

## Four independent worktree responsibilities

| Worktree | Ownership | Required checks |
| --- | --- | --- |
| 1: Student UX and navigation | Bookmark, saved, discovery, profile/edit, chat entry, tours; tests in these domains | Save/unsave without disappearing sections or scroll jumps; slow/rejected/concurrent saves; counts across Home/Discover/Saved/detail; profile edit persists and cancel discards; initial setup still works; chat introduction on every opening/skip/replay/user separation/opposite companions; all shortcuts; keyboard/back; 320/390/440px, 200% text |
| 2: Scholarship lifecycle and provider | Provider posting/review, applications, capacity, decisions, documents; related tests | Eligibility and grade scales; real requirements/documents; submit/pending/review/decision/letter; duplicate submission, withdrawn/closed/full slots; reviewer vs org-admin; tenant isolation; upload denied/failed/retry. Exercise real browser flows against designated disposable demo accounts if available. |
| 3: Auth, admin and security | Login/session/CAPTCHA/account settings/admin/RLS tests | Native CAPTCHA protocol and actual enabled build config; invalid/replayed/expired CAPTCHA; password/email verification; progressive lockout/admin unlock; inactivity; role guards, recovery; same-user logout and different-user isolation; admin audit/verification/safety; privacy and storage access boundaries |
| 4: Independent QA and release evidence | Read-only integration review, reports and release checklist; no competing product edits | Run the integrated full suite/analyzer/static security checks; browser journeys and screenshot review with actual Geist; assess logs and skipped tests; reconcile findings/severity/source; own final GO/NO-GO. Build only after the integrated source passes the gate and build is authorized. |

Arki coordinates file ownership before parallel edits. Each worker reports root cause, failing reproduction, smallest fix, passing commands, changed files and residual risks. Do not waive a failure as baseline without identifying the exact source and evidence. Send cross-domain changes to the owner. Integrate reviewed fixes into one release branch, then rerun integrated checks.

## Verification procedure

- [ ] Record exact branch, SHA, dirty state, Flutter version and environment. Freeze intended source for each worker.
- [ ] Run `flutter test --no-pub --reporter expanded`, save full log/exit status. List every skipped test with reason. Existing opt-in live integration tests are skipped by default: do not count them as live passes.
- [ ] Run `flutter analyze --no-pub`; separate existing informational notices from new warnings/errors. Run relevant typography/UI tests and `git diff --check`.
- [ ] Run `node tools/test_ios_captcha_build_config.mjs`, `node tools/test_captcha_challenge_layout.mjs` and `node tools/test_tab_scoped_auth.mjs`. Run remaining security/database harnesses only after reading their setup and confirming they target an isolated test environment.
- [ ] Build/run the production web entry point for real integration journeys. Regression preview builds prove presentation only and use fake repositories; never label these live end-to-end tests.
- [ ] Use dedicated demo accounts/records to rehearse provider registration -> admin verification -> scholarship posting -> student application -> provider review -> student decision/letter -> safety/support oversight. Check backend persisted records and correct role isolation after each transition. If accounts/environment are unavailable, mark BLOCKED/PENDING with exact prerequisite, not passed.
- [ ] Do not reset production data, restore backups, weaken RLS/CAPTCHA, or send mail to real users as a shortcut. Do not print passwords, auth tokens, keys or sensitive documents in reports.
- [ ] Capture browser errors, failed requests, screenshots and steps for each defect. Test rapid taps, slow responses, errors/retries, route back/cancel and sign-out/user change. Use actual bundled fonts when evaluating typography.
- [ ] Run final integrated tests after fixes. No new crashes, data loss, broken primary transactions, authorization bypasses or blocking navigation defects before release. Record open lesser issues and their demo impact; no blanket readiness percentage or grade prediction.

## IPA gate (after tests and authorization)

Use `.github/workflows/build_ios.yml`, the exact intended committed source and production `lib/main.dart`. Select the next unused build number; preserve old archives. Every IPA must enable CAPTCHA, including demos/sideloads. Verify actual compiler logs contain `SCHOLARIS_CAPTCHA_ENABLED=true`, the existing configured site key and `https://scholaris-captcha.pages.dev/captcha_challenge`. Do not expose the key in reports. A successful archive alone is not evidence.

Handoff: source/release SHA, version/build, workflow URL/run, IPA location, SHA-256, CAPTCHA log evidence, tests with counts/skips, open issues, and physical-device login status. On a physical iPhone complete CAPTCHA/login and check bookmark motion, profile save/cancel, chat art/repeated introduction and QR camera/upload permissions. If no device is available, explicitly leave these pending for the student's rehearsal.

## Report format

Use one evidence matrix: requirement, exact source, local automated result, real browser/backend result, physical-device result, artifact/log, open blocker. Older checklists are historical references and may contain obsolete CAPTCHA or branch claims; verify against current source. Instructor names/formal rubric must come from the current official rubric, not inferred from repository reports. Preserve a short rehearsal checklist for the student after sleep.
