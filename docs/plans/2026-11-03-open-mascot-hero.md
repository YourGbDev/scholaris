# Open mascot hero and consistent entry artwork

> **For agentic workers:** Use executing-plans to implement and verify each task.

**Goal:** Ship the approved white hero, looping code-driven greetings and consistent mascot identity on student entry screens.

**Architecture:** One shared transparent portrait per character anchors the hero; a matching joined illustration serves welcome/login. Flutter owns a small localized mesh animation; the wrist and head move while shoulders and nearby hair remain fixed. Existing provider state, match navigation and authentication stay intact.

**Tech stack:** Flutter, bundled Geist, existing raster assets, CustomPainter and AnimationController; no new dependencies.

**Spec:** User-approved browser study at http://127.0.0.1:5086/ and this conversation, November 3. These explicit instructions supersede the older green-card/campus-art rule.

## Constraints
- White open hero, no scenery, border, shadow or solid CTA. Preserve real greeting/count and 44px Explore target.
- Ariel follows male/unset gender; Ari follows female gender. Keep the opposite companion rule in chat.
- Two gentle waves and a small tilt, then at least three seconds still. Reduced motion and inactive/background pages remain still.
- Ariel slightly taller than Ari without stretching his proportions. Match emerald and gold palette and consistent face proportions.
- Enlarge login pair responsively; preserve form access on narrow screens, keyboard display and enlarged text.
- No IPA, release bump, commit or push in this task.

## Tasks
- [x] Add shared high-quality portrait assets and an entry pair; align onboarding artwork to the canonical faces/palette.
- [x] Add motion tests covering pause, loop, inactive/reduced-motion behavior, gender and stationary shoulder/hair regions; run red, implement, run green.
- [x] Replace Home hero container with responsive white composition and text action; retain loading/failure behavior.
- [x] Use consistent welcome pair on entry/login, enlarge login artwork and preserve scrolling.
- [x] Update superseded project guidance, run focused checks, inspect browser at 390px and 320px/enlarged text, then run the full suite.

## Review focus
Long names/greetings; delayed or failed profile/matches; 320px and 200% text; tab/lifecycle/reduced-motion transitions; login keyboard and CAPTCHA unchanged.

## Execution notes
Existing isolated checkout codex/auth-tour-polish at release 262fd2f. Initial working tree clean. This is implementation of the approved preview, not a typography redesign.

Latest user correction: preserve close overlapping pair, existing smiles and straight shared crop; show the 5 foot 11 versus 5 foot 3 stature difference using one combined asset.

Validation: before the final joined-pair revision the full suite passed 1,278 tests (6 skipped), with scoped analysis and real-browser hero/entry checks. After the joined-pair revision: 29 focused mascot/intro/login tests passed, scoped analysis found no issues, entry web build succeeded, and git diff --check passed. Updated browser visual check is pending because local browser use is disabled in Work settings. No physical-device verification, commit, push or IPA build performed.

Smiling mascot follow-up: approved toothy-smile pair now shared by student welcome/onboarding/login and landing hero. Solo Home Ariel has the same smile; rig geometry is still 1299x1211 and animation code/timing unchanged. Landing celebration uses consistent identity, height references and joyful expressions. 86 affected widget tests passed; landing JS/server syntax and HTTP 200 asset delivery passed; app entry and Home preview web builds succeeded. Final browser/device visual verification remains pending because local browser use is disabled.

Release handoff verification November 3: full Flutter suite passed 1,278 tests with 6 skipped and no failures. CAPTCHA build-configuration check passed. User authorized preparing source for Archi's next IPA; version remains 1.0.0+28 for Archi to assign the next unused build number. Latest artwork browser/device visual check remains pending.
