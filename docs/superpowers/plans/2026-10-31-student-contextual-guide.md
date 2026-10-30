# Student Contextual Guide Implementation Plan

> Execute inline using executing-plans and test-driven-development. User approved the design and explicitly requested implementation in the existing workspace; do not create another checkout or commit.

**Goal:** Anchor concise walkthrough bubbles to real controls, then demonstrate an application without writes; compact Discover.

**Architecture:** Home owns stable stat/dock anchors and a dashboard scroll controller. StudentTourLayer retains opt-in, replay and account lifecycle. StudentApplicationGuide measures targets, blocks underlying actions, and owns temporary discovery/detail/review/receipt/Tracker screens with finite motion.

**Tech Stack:** Flutter, Riverpod, existing fonts/theme, SharedPreferences. No new dependencies.

**Spec:** docs/superpowers/specs/2026-10-31-student-contextual-guide-design.md (approved by user's implementation request).

## Global Constraints

- Preserve all pre-existing changes. No commit, push, version bump or IPA build.
- No application, storage or bookmark writes from guide actions. Skip/Finish/account change destroy samples.
- 390×844 visual checks; 320 px and 200% text tests; reduced motion, keyboard and screen-reader support.
- Keep deadline filters and default result ordering; remove standalone sort popup only.

## Review Focus

- Missing/loading anchors leave usable explanations and exit controls.
- Home stat anchors may begin offscreen; scroll before positioning the bubble.
- Back/replay/account changes must cancel animations and reset sample state.
- Large text must keep target action and Skip reachable.
- Guide must not route demo taps to live service callbacks.

### Task 1: Compact Discover

Files: discover_screen.dart; discovery_search_widget_test.dart.
- [x] Add test asserting no standalone sort control while deadline filter remains usable; run RED.
- [x] Replace feed header with text; use one 16 px gap after filter area and 12 px after heading.
- [x] Run Discover tests GREEN.

### Task 2: Contextual guide

Files: student_application_guide.dart, student_app_tour.dart, home_screen.dart, student_dashboard_screen.dart; student_application_guide_test.dart, student_tour_test.dart.
Interfaces: optional dashboard stat GlobalKeys and ScrollController; guide receives home/dock keys and ValueChanged<int> onSelectTab; existing dismissal callbacks retained.
- [x] Replace guide tests with contextual progression/actions, Back/Skip/replay, account teardown, missing anchors and 320 px/200% text; run RED.
- [x] Wire stable Home stat anchors and scroll reset, then implement measured highlight, pointer/bubble, finite pulse/swipe cue, temporary screens and safe transitions.
- [x] Run affected guide/dashboard/nav tests and targeted analysis GREEN.

### Task 3: Visual verification and review

- [x] Reuse existing 5047 preview, refresh compiled app as needed, capture current guide stages and compact Discover at 390×844; inspect both genders.
- [x] Run appropriate regression suite, analysis and whitespace check; independent read-only code review and correct substantive findings.
- [x] Record results/limitations in the device-feedback report; leave source uncommitted.

Execution progress and any deviations are recorded below; this working tree already contains the prior uncommitted implementation.

Execution result: implemented inline in the authorized existing workspace, without commits. Independent review's three substantive findings fixed and regression-tested. 151 focused tests passed; final guide/tour run 10/10 and targeted analysis clean. Full suite: 1214 passed, nine skipped, four untouched admin audit-log failures. Fresh 390×844 captures and detailed limitations are recorded in docs/reports/student-device-feedback-2026-10-31/implementation.md. No unresolved review findings.
