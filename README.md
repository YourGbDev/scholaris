<div align="center">

<img src="assets/images/mascot_couple_wave.png" alt="Scholaris student mascots welcoming you" width="260" />

# Scholaris

**Discover opportunities. Apply with confidence. Know where you stand.**

A scholarship platform for Filipino students and the people helping them take their next step.

![Status: In development](https://img.shields.io/badge/status-in_development-B49135)
![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-154734?logo=supabase&logoColor=white)

[Why Scholaris](#why-scholaris) · [Features](#features) · [Development status](#development-status) · [Getting started](#local-development) · [Roadmap](docs/plans/2026-10-21-scholaris-product-roadmap.md)

</div>

## Why Scholaris

Scholarship announcements can be scattered across pages and posts. Students may discover opportunities after deadlines, make repeated trips to submit requirements, and keep checking different channels for updates.

Scholaris brings discovery, digital applications, submission records, and application tracking into one workflow. Separate desktop web portals help scholarship providers organize programs, review applications, and record decisions.

## Features

| For students | What it helps with |
| --- | --- |
| Scholarship discovery | Explore opportunities and compare eligibility, requirements, and deadlines with profile-based matching |
| Digital applications | Prepare and submit supported application requirements online |
| Submission receipts | Keep a reference to a submitted application and its packet |
| Application tracker | Follow recorded progress, provider decisions, and available decision letters |
| Account verification and recovery | Verify email ownership and reset passwords through emailed one-time codes |
| Personalized experience | Student mascots and dashboard artwork with male and female variants |

| For providers and administrators | Workspace |
| --- | --- |
| Organizations | Manage scholarship programs, applicant review, capacity, and team assignments |
| Reviewers | Evaluate and endorse applications within their organization's scope |
| Individual providers | A developing workflow for people who want to offer scholarships directly; live lifecycle activation remains pending |
| Platform administrators | Separate platform management and administration tools |

**People make scholarship decisions.** Matching helps students discover opportunities; it does not guarantee eligibility, selection, enrollment verification, or funding.

## Development status

Scholaris is an actively developed AppDev/capstone project. It is **not a public production launch**. Demonstrations may contain fictional scholarship data and concept interfaces.

- **Current:** student mobile app, organization/reviewer web workflows, application tracking, and email-code verification/recovery. Signup and recovery have been exercised on the owner's iPhone; broader device testing continues.
- **Local preview:** the marketing site and animated provider concepts. These previews do not imply a deployed provider service or feature parity with the app.
- **Planned:** the Ask Scholaris AI guide, reusable document vault, assisted application drafting, and richer mascot interactions. These are roadmap items, not available features.

Current matching is rule-based. AI assistance is planned and should not be represented as an implemented AI decision system.

See the [product roadmap](docs/plans/2026-10-21-scholaris-product-roadmap.md) for direction and the [session handoff](docs/coordination/SESSION_STATE.md) for current verification and remaining work.

## Core transaction

1. An organization admin publishes a scholarship.
2. A student completes their profile and submits an application with the required documents.
3. A separate organization reviewer evaluates the application and endorses it for a decision.
4. The organization admin approves or rejects the endorsed application.
5. The student sees the final status, decision letter, and in-app notification.

Organization roles are enforced through trusted membership and backend authorization. Reviewers cannot make final decisions. Platform-admin awarding is a separate transition after approval.

## Platforms and current scope

| Surface | Intended use |
| --- | --- |
| Student app | iPhone/mobile; web previews for development and browser checks |
| Organization portal | Desktop web: scholarships, applicant review, capacity, activity, and reviewer assignments |
| Reviewer/staff portal | Desktop web: organization-scoped evaluation and endorsement |
| Individual-provider portal | Desktop web; inspect existing implementation before assuming feature parity with the organization portal |
| Platform/super-admin portal | Desktop web: platform administration |
| Landing page | Public-facing static website; local preview does not mean it is deployed |

The original three-role AppDev demo was completed successfully. Subsequent work includes organization controls, remaining-slot enforcement, school eligibility, and student account verification.

<details>
<summary>Backend deployment notes and AI scope</summary>

Migration `0026` was applied through the authenticated Supabase dashboard on **20 October 2026**, using source commit `aa97ecb41ade7610575db04f9e22204223fded72`. Read-only schema, backfill, privilege, and preservation checks passed. API acceptance results have been reported separately; a fresh end-to-end browser cycle for the integrated changes is still pending at this documentation checkpoint. This is not a production-readiness claim. Recheck current evidence before release, and do not blindly reapply a manually executed migration.

**Ask Scholaris**, the proposed AI scholarship guide, is planned and is not an implemented feature. Rule-based matching and profile-completeness indicators should not be presented as proof of an AI integration or verified enrollment.


</details>

## Stack and source layout

- Flutter and Dart; the Dart constraint is `^3.13.1` in `pubspec.yaml`.
- Riverpod for state management and GoRouter for navigation.
- Supabase Auth, PostgreSQL/RLS, and private Storage for backend services.
- Freezed and JSON Serializable for generated models.
- Node.js for the local landing server and database test harnesses.

| Path | Contents |
| --- | --- |
| `lib/app/` | App configuration, routing, shared setup |
| `lib/features/` | Student, provider, application, profile, and administration features |
| `assets/` | App illustrations, mascots, fonts/animations as declared in `pubspec.yaml` |
| `landing/` | Static landing page, styles, scripts, images, and local server |
| `supabase/migrations/` | Versioned SQL changes; inspect remote execution evidence before applying |
| `supabase/tests/` | Database regression checks |
| `test/` | Flutter unit, widget, and workflow tests |
| `tools/` | Test and verification harnesses; inspect prerequisites and mutation scope first |
| `docs/` | Plans, task cards, coordination, and verification reports |

## Local development

Use a Flutter installation compatible with `pubspec.yaml`, a supported browser for web development, and Node.js for the landing server. Native iOS compilation requires macOS and Xcode; the existing GitHub Actions workflow provides the project's cloud build path.

1. Inspect the current branch and working tree. Preserve existing changes.
2. Obtain authorized local Supabase client configuration from the project owner. `lib/app/supabase_config.dart` is intentionally ignored by Git; it defines `SupabaseConfig.url`, `SupabaseConfig.anonKey`, and `SupabaseConfig.resetPasswordRedirect`. Do not paste credentials into chat or commit the file. A fresh clone/worktree may not build until this local file is provisioned.
3. Install dependencies and run the app:

```sh
flutter pub get
flutter run -d chrome --web-port 5000
```

Only regenerate models when the changed sources require it, and inspect the resulting generated-file diff:

```sh
dart run build_runner build --delete-conflicting-outputs
```

For a connected supported mobile device, inspect `flutter devices` and use `flutter run -d <device-id>` on a suitable host. A Windows machine does not build native iOS locally.

### Landing preview

In a separate terminal:

```sh
node landing/serve.mjs
```

Open `http://localhost:8080`. The server serves static files and redirects configured application entry routes to the Flutter web server on port `5000`. `PORT`, `FLUTTER_PORT`, and `FLUTTER_HOST` can override the local server settings. This is a development server, not a hosting deployment configuration. Check existing listeners before starting or stopping a server used by another agent.

## Verification

Run checks appropriate to the change; these commands are examples, not claims that every suite has just passed:

```sh
flutter analyze lib/ test/features/
flutter test test/features/applications/transaction_cycle_test.dart
flutter test test/dashboard_widget_test.dart test/dashboard_provider_test.dart
flutter test test/application_decision_letter_test.dart
flutter build web --release
```

UI work also requires actual-browser checks at `360×800` and `440×956` for students and `1280×800` for desktop portals. Test loading, empty, error, keyboard, and reduced-motion behavior. Headless widget tests, API scripts, browser previews, and physical iPhone testing are separate evidence categories.

Database harnesses may require local dependencies and a disposable PostgreSQL instance. Genuine concurrency testing uses independent database connections; one PGlite instance is not multi-session evidence. Inspect each harness before running it: do not assume a test is local or read-only. Mutating remote tests require authorization and recorded disposable fixtures.

## Data and security rules

- Decisions persist evaluation/history, authenticated actor, timestamps, and final student notifications. Failed or zero-row operations must not display success. All messages stay inside the application; no browser alerts.
- Approved and awarded applications each occupy one slot. Endorsement and rejection occupy none; awarding an approved application does not consume an additional slot. Students can withdraw pending applications, not approved/awarded ones.
- School-restricted submissions require a matching declared `school_id`. Ambiguous/unmatched legacy school text is preserved without assuming a campus. Declaration is not enrollment verification.
- Private documents and applicant records stay scoped to authorized users and organizations. Never weaken RLS or use port/email/name heuristics as authorization.
- Inspect default grants as well as policies. Use NULL-safe authorization and server-bound actor identity; RPC-only writes must not be bypassable through direct table operations.
- Never publish passwords, service-role keys, tokens, applicant records, or private configuration. No shared demo passwords are documented here.

## Collaboration and skills

Read [GEMINI.md](GEMINI.md) for project operating rules. It documents the current ownership split: Codex leads UI/browser verification and approved Supabase execution; Architect coordinates specialist backend work and testing.

Skills are selected by task, not all loaded together. Read the actual `SKILL.md`, preserve user-approved scope/design, and report missing skills honestly. Superpowers supplies process skills; Ponytail encourages focused changes; Apple/Emil, Taste, and Impeccable cover relevant design tasks. Caveman remains optional and off by default. Skills do not grant release, remote database, delegation, or configuration permissions.

Installation and discovery depend on the AI environment and current worktree. Editing these documents does not install skills or enable startup hooks. See [OpenAI's skill documentation](https://developers.openai.com/codex/skills) for Codex's skill mechanism. Other agents must use their own supported discovery mechanism.

Plans and task cards are under `docs/plans/` and `docs/tasks/`; reports are under `docs/reports/`. Worktrees do not share uncommitted files. Do not copy a stale guide over an active worktree's local notes. Coordinate adoption of updated instructions with Architect.

## iOS builds and release boundaries

[The iOS workflow](.github/workflows/build_ios.yml) builds an unsigned app bundle, packages a sideloadable `Scholaris.ipa`, and uploads the `Scholaris-iOS-App` artifact. Signing/installation is a separate step, currently performed with Sideloadly.

The workflow runs on manual dispatch and pushes to `main`, `master`, and `fix/touch-targets-oct02`; an authorized push can therefore trigger a build automatically. Confirm scope before pushing. A successful artifact does not prove installation or on-device behavior. Student-facing Flutter changes need a new IPA; static landing-page changes alone do not.

Remote migrations, fixture cleanup, pushes, deployment, and builds must follow the user's current authorization. Keep downloaded IPA/ZIP files, private configuration, and scratch evidence out of focused commits. See the [three-role transaction-cycle report](docs/reports/2026-10-19_three_role_transaction_cycle.md) and the latest specialist evidence for verified scope and remaining gaps.

## Feedback and contributions

Feedback from students, scholarship providers, and developers is welcome. Describe the problem, the affected workflow, and steps to reproduce it. Use fictional or redacted examples; do not include student documents, passwords, verification codes, or private account information.

Before contributing code, discuss the proposed change with the maintainer so work can be coordinated with the current development scope.

## License

A project-level open-source license has not yet been selected. Public repository visibility alone does not grant permission to reuse or redistribute the project. Dependency and third-party asset licenses remain applicable.
