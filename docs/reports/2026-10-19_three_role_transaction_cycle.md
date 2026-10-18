# Three-role scholarship transaction cycle — 19 October 2026

## Outcome

The three-role cycle was rehearsed through the actual local Flutter web UI with separate authenticated users:

`org admin publishes → student uploads/submits → reviewer evaluates/endorses → org admin decides → student opens the saved notification and final result`.

The final clean rehearsal used rejection. Approval and its student result/notification were also exercised in the preceding rehearsal. No admin session was shared with the reviewer. The same-origin tabs retained their independent identities after the auth-broadcast correction.

## Workspace integrity

- Worked directly in `C:\scholaris`, branch `fix/touch-targets-oct02`, HEAD `552c47a46a9f83be3f4ceea8ad597eebab2ee31f`.
- Inspected and preserved the pre-existing reviewer/admin button work in `applicant_review_drawer.dart`; added trusted authorization and transaction handling around it.
- No reset, staging, commit, branch change, or overwrite of unrelated work. Existing IPA/ZIP files, images, screenshots, and `latest_ipa/` were preserved.
- Code generation changed only the application model outputs. Original line endings were restored in four other generated files after confirming their content was unchanged.
- Credentials were read from existing local configuration/fixtures, never printed or added to new tracked files.

## Implemented

### Trusted organization authority

`organization_memberships` is an operator-provisioned table. The existing scholarship owner (`scholarships.created_by`) serves as the organization principal, avoiding an unrelated organization-onboarding redesign. A user has one membership with an explicit `org_admin`, `reviewer`, or `finance` role and active flag. Organization authorization also requires an active provider profile.

Authenticated clients can read their own membership but cannot insert or update memberships. No port, email prefix, display name, or hardcoded demo-user UUID grants application authority. Email addresses are used only by the separate trusted provisioning script to locate the explicitly requested accounts.

Reviewers can read submitted applications and evaluate/endorse only within their assigned organization. Drafts and withdrawn applications remain hidden. Final approval/rejection requires an organization admin and an existing endorsement from a different authenticated reviewer.

### Atomic review workflow

`review_application` locks the application, checks the expected status and organization role, and commits all required writes in one PostgreSQL transaction:

- Endorsement: four rubric scores, server-calculated composite, deliberation notes, reviewer UUID, server timestamp, identifiable `endorsed` evaluation, `under_review` status, and history.
- Final decision: admin UUID, server timestamp, approved/rejected status, history, and exactly one recipient notification.

Failures in evaluation, history, or notification persistence abort the transaction. Direct client inserts into evaluations, history, and notifications are revoked. Application ownership and workflow actor fields cannot be forged through direct PATCHes. Student notes are preserved rather than replaced by rubric JSON.

Mutation requests require a returned row; RLS-denied zero-row writes throw. Empty/mismatched RPC results also fail. The drawer no longer swallows required persistence failures or reports success before confirmation.

Migration 0025 preserves the pre-existing platform-admin `approved → awarded` operation only, avoiding a regression outside the requested demo. It does not grant platform-admin approval/rejection authority. Finance hardcoded application-access exceptions remain removed.

### UI, sessions, and documents

- UI authority comes from membership, with loading/error states failing closed. Reviewer publication/final-decision controls are absent; organization admins retain publishing and final decisions.
- Alternative provider action surfaces route through the same review workflow.
- Student notifications read persisted recipient rows, support checked mark-as-read updates, and refresh application state when opened.
- Document upload now requires both actual private storage upload and metadata persistence. Failures cannot return fabricated local document models. Fetch/delete errors propagate.
- Students can upload through the existing upload sheet from submission review. Reviewers see actual attachments and can open a five-minute signed URL after storage authorization.
- Document providers are keyed to the auth-session boundary. The bucket remains private. Applicant profile access remains column-minimized, excluding birth date, contact details, disability, ethnicity, and gender.
- Submission review/receipt now shows real attachment state, application ID, and saved submission time instead of fabricated verification, signature time, receipt ID, or SHA-256 claims. Application notes are accurately labeled as shared with authorized reviewers.
- Supabase/gotrue 2.27.2 broadcasts auth changes even with custom sessionStorage and exposes no broadcast-disable option. `web/tab_scoped_auth.js` scopes only Supabase auth channels to the current document before Flutter initializes. Other channel names are unchanged. Actual three-account same-origin UI testing verified isolation.
- Corrected post-commit use of disposed widget references. Corrected the drawer's reverse animation direction and route bounds so closing it releases the modal barrier and restores console interaction.

## Database application status

| Item | Actual status |
| --- | --- |
| Live policies/schema inspection | Performed in authenticated Supabase SQL Editor for `yqwbarzxpduzmtrxnrbm`; inspected active policies, schema columns, account roles, ownership, and triggers |
| `0024_organization_review_cycle.sql` | Applied successfully to that remote project after explicit user approval |
| `provision_demo_review_memberships.sql` | Applied successfully; only the named demo org admin and reviewer were provisioned |
| `0025_preserve_existing_award_transition.sql` | Applied successfully; existing post-approval platform-admin award transition preserved |
| Live regression fixtures | Rolled back; no rollback-test scholarships remained |
| Hosted frontend deployment | Not performed; this task built and tested the local web app |

These SQL files were applied manually through the SQL Editor. They were not applied through a Supabase CLI migration ledger. Existing migrations were not reset or replayed.

Final live checks confirmed: no client membership insert/update grants; no client evaluation/history/notification insert grants; zero remaining hardcoded finance bypasses in application/history policies; private document bucket; compatibility award policy present.

## Actual test results

| Verification | Result |
| --- | --- |
| Focused Flutter suite: repository, HTTP mutation failures, document failures, membership states, applicant privacy, desktop console, drawer lifecycle | **51 passed** |
| Actual PostgreSQL locally via PGlite, applying migrations and exercising RLS/functions | **20 passed** |
| Live SQL regression script using authenticated roles and rollback-only fixtures, rerun after 0025 | **10 passed** |
| Auth broadcast script | Passed: separate document scopes, consistent scope within one document, unrelated channels unchanged, unsupported browser handled |
| Scoped Flutter analysis across changed application/provider features, notification sheet, scholarship detail, and new tests | **No issues found** |
| `flutter build web --release` | **Succeeded**; output `build/web` |
| `git diff --check` | Passed |

Security tests cover authorized endorsement, denied reviewer approval/rejection, admin approval/rejection, cross-org read/write denial, draft/withdrawn privacy, minimized profiles, private document reads, immutable actors/ownership, forged notifications/memberships, stale/duplicate decisions, invalid scores, and zero-row direct updates. Failure injection proves history/notification failures roll back the final status and side effects. HTTP tests prove denied writes and failed uploads cannot return success. The lifecycle test dismisses a drawer while a server operation is pending, then verifies no disposed-reference error and that the underlying button receives taps.

Reproduce the local PostgreSQL checks:

```text
npm install --prefix scratch/cycle-testing @electric-sql/pglite --no-audit --no-fund
node tools/test_organization_review_cycle.mjs
node tools/test_tab_scoped_auth.mjs
```

Flutter test files:

```text
test/application_workflow_transport_test.dart
test/application_repository_test.dart
test/features/provider/provider_sub_role_test.dart
test/rls_applicant_credentials_scoping_test.dart
test/provider_console_desktop_test.dart
test/reviewer_drawer_lifecycle_test.dart
```

## UI rehearsal records

The supplied scholarship `bcb518b3-f789-45f9-997e-df6db19aab5c` already had rejected/withdrawn applications for the demo student. Those records and their statuses were preserved. Fresh scholarships were published through the UI for the rehearsals.

| Rehearsal | Scholarship ID | Application ID | Final result |
| --- | --- | --- | --- |
| Approval | `3ef6a909-05f5-41cf-9471-ebe8b0790632` | `6a364789-4fb6-4534-a76f-29929d4b5ed0` | approved |
| Clean final-build cycle | `650737a8-2869-46fc-ac8d-23e8f1f16880` | `9792c9ac-75ed-4d8a-a3cd-51b18c758b87` | rejected |

For **each** application the final database inspection found one endorsed evaluation, two history rows, one final student notification, and one uploaded private document. Endorser was reviewer `5caeaf69-fba0-441d-95b5-fb0e2762c23d`; decider was org admin `0574ae43-93ca-4961-a90a-efba58f373ef`. Server timestamps were present. The original supplied scholarship's existing rejected/withdrawn application records remained unchanged.

The uploaded PDF is explicitly marked as a demo document, not an official transcript. A private signed-link PDF open was verified through the reviewer UI without exposing the signed URL. The demo student used the app's existing **Proceed with Warning** option for its unverified photo; no photo verification was fabricated.

Actual viewport checks:

- **360×800:** student notifications and reviewer drawer.
- **440×956:** student notifications and final rejection result with attachment.
- **1280×800:** organization-admin final-result drawer, persisted evaluation, attachment, and endorsement metadata.

No new relevant runtime errors, RenderFlex overflow warnings, or JavaScript browser alerts were observed during the clean final rehearsal. Earlier disposed-reference and invisible-modal defects were reproduced and fixed. All confirmation/success/error messaging used Flutter's in-app UI.

## Evidence available locally

Under `C:\scholaris\scratch\` (ignored by Git):

- `cycle-live-policy-before.json`, `cycle-live-schema-before.json`: actual initial inspection.
- `cycle-live-migration-verification.json`, `cycle-final-grants.json`: remote membership/policy/grant verification.
- `cycle-final-database-evidence.json`: persisted actors, timestamps, evaluations, histories, notifications, and document metadata for both cycles.
- `cycle-live-tests-final.txt`, `cycle-final-tests.log`, `cycle-runtime-checks.json`: test results and runtime checks.
- `final-cycle-01-published.png`, `final-cycle-02-submitted.png`, `final-cycle-03-reviewer.png`, `final-cycle-04-endorsed.png`.
- `final-cycle-05-notifications-desktop.png`, `final-cycle-notifications-360.png`, `final-cycle-notifications-440.png`, `final-cycle-06-student-rejected-440.png`, `final-cycle-admin-1280.png`.
- `cycle-03-reviewer-private-pdf.png`: private PDF viewing evidence; no signed URL printed.

The local app is served at `http://localhost:5310`. Three independent demo-account browser tabs were retained for inspection. Catalog/staff queues were refreshed between steps; persistent notifications fetch when opened. This is not a claim of real-time push delivery.

Tested `build/web/main.dart.js` SHA-256:

`27E14469DC0311C3FC6E3D3D258FF2A17355DFFB90D99503182A0376E3F38CB3`

## Changed files

Application domain and persistence:

```text
lib/features/applications/models/application.dart
lib/features/applications/models/application.freezed.dart
lib/features/applications/models/application.g.dart
lib/features/applications/providers/applications_provider.dart
lib/features/applications/providers/application_document_provider.dart
lib/features/applications/repositories/application_repository.dart
lib/features/applications/repositories/application_document_repository.dart
```

Transaction UI and session handling:

```text
lib/features/applications/presentation/application_detail_screen.dart
lib/features/applications/presentation/submit_application_review_dialog.dart
lib/features/dashboard/presentation/widgets/student_notifications_sheet.dart
lib/features/provider/providers/provider_sub_role_provider.dart
lib/features/provider/presentation/widgets/applicant_review_drawer.dart
lib/features/provider/presentation/org/org_provider_shell.dart
lib/features/provider/presentation/org/org_incoming_applications_tab.dart
lib/features/provider/presentation/provider_application_detail_screen.dart
lib/features/provider/presentation/provider_incoming_applications.dart
lib/features/scholarships/presentation/scholarship_detail_screen.dart
web/index.html
web/tab_scoped_auth.js
```

Migrations, provisioning, and verification:

```text
supabase/migrations/0024_organization_review_cycle.sql
supabase/migrations/0025_preserve_existing_award_transition.sql
supabase/provision_demo_review_memberships.sql
supabase/tests/organization_review_cycle_live.sql
test/application_workflow_transport_test.dart
test/reviewer_drawer_lifecycle_test.dart
test/features/provider/provider_sub_role_test.dart
test/helpers/fake_application_data_source.dart
test/rls_applicant_credentials_scoping_test.dart
test/provider_console_desktop_test.dart
tools/test_organization_review_cycle.mjs
tools/test_tab_scoped_auth.mjs
docs/reports/2026-10-19_three_role_transaction_cycle.md
```

## Not verified / scope limits

- Full repository test suite, Android/iOS builds, and hosted frontend deployment were not performed. Existing IPA/ZIP artifacts were not rebuilt.
- Super-admin/provider onboarding, real identity/photo verification, external email/SMS, financial disbursements, and award-ceremony/package content were outside the rehearsal. The existing platform-admin award transition was checked in PostgreSQL locally, not through its UI.
- Only the requested demo memberships were provisioned. Other provider accounts require explicit trusted membership provisioning; they do not receive inferred organization authority.
- This was not a platform-wide UI/content audit. Other pre-existing marketing, academic-year, eligibility, or award-package copy may still need separate review.

## Skills applied to the focused interaction fix

Computer-use skill supported the actual UI rehearsal. Workspace `apple-design` guidance was inspected and applied to the drawer fix: §3 interruptibility, §7 consistent reversal, §14 reduced-motion behavior, and §16 wayfinding/never trapping the user. Existing spring parameters and reduced-motion rendering were retained; route bounds and reverse status were corrected. The referenced `emil-design-eng`, `emil-apple-design`, `review-animations`, and `animate` skill files were not present locally, so no review from those sources is claimed.
