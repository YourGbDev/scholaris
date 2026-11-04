# Typography refinement — approved plan and execution ledger

Source baseline: 1804904, branch codex/typography-refinement.

## Binding specification

Native iOS uses Flutter's supported native SF Pro implementation; web checks
kIsWeb first and uses bundled Inter everywhere; Android and other targets use
bundled Inter. Roles: 700 display/screenTitle/metric; 600
sectionTitle/cardTitle/button; 500 bodyEmphasis/label/navigation/badge; 400
subtitle/body/caption/input/placeholder. No redesign or unverified geometry,
tracking, height, size, color, asset, or business-logic changes.

## Tasks

- [x] Baseline captures and platform inventory.
- [x] Central typography foundation, local Inter assets, platform/role tests.
- [x] Shared components and student/authentication/profile/application screens.
- [x] Provider/admin and previews; remove legacy font helpers.
- [x] Source guards, updated project rules, available visual/regression verification.
- [x] Independent final review and handoff. Native checks explicitly pending.

## Rulings and evidence

- Work in place on a new task branch: the original checkout contains unrelated
  landing/report edits and many archives. Preserve all of them. No worktree was
  created, and no merge, push, commit or release is part of this request.
- Installed SDK painting/text_style.dart documents CupertinoSystemText and
  CupertinoSystemDisplay as native SF Pro Text/Display proxies, using the
  20-point boundary. This is source evidence, not native rendering proof.
- flutter devices: Windows, Chrome and Edge only. iOS and Android native
  rendering verification pending; no IPA is authorized.
- Before changing app source, captured eight genuine-widget raster fixtures at
  320/390 logical pixels: onboarding, login, scholarship card, logout dialog.
  Baseline capture test: 8 passed. These Windows tester captures do not prove
  native font rendering. Baseline offline student web build succeeded.

## Verification log

Logs and temporary migration tooling live in ignored scratch/typography.
Matched evidence is saved under before/ and after/ alongside this ledger.

- Semantic review: 841 student/shared, 888 provider, 339 admin calls reviewed
  independently; 2,068 original style calls migrated with existing geometry.
- Final inheritance audit: 53 additional semantic styles, eight theme usages;
  emoji/color-only spans and existing nonvisual markers retain inheritance.
- Three independent review findings fixed with failing-then-passing tests:
  NavigationBar state colors, dialog text color, implicit ElevatedButton roles.
- Final visual/semantic audit pinned dashboard/chat greetings to display 700;
  13 hero/chat tests passed after the correction. No layout/geometry correction.
- Final focused typography/theme/hero/chat tests: 34 passed, 2 legacy captures
  skipped. Node source/font guard: passed, with three guard/asset tests passing.
- Final full suite: 1,253 passed, nine skipped, seven failures. All seven
  reproduced against original app source 1804904 in separate verification copy.
- Application/new-test analysis clean. Production and preview web builds pass.
- 23 matched screenshot pairs; final Chrome capture reports zero browser errors.
- Dedicated Chrome unit-test runner stalled during loading and was canceled;
  this run is not counted as passed.
- Android emulator booted. Isolated native preview build failed before
  compilation because Gradle could not establish a loopback connection;
  IPv4-only retry failed identically. No APK was installed. Emulator stopped.
- Native iOS, native Android and actual Safari/iOS rendering remain pending.
- No publishing, release, commit, push, merge, or deletion of old assets/archives.
