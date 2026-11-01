# Geist Sans and crisp hierarchy

The user's pasted specification supersedes native SF Pro Rounded/Nunito. Use locally bundled Geist400/500/600/700/800 everywhere, including landing for a consistent identity; remove the native font switch. Preserve card surfaces, content and unrelated work.

- [x] Verify all five embedded font weights; add the existing landing ExtraBold800 asset to Flutter.
- [x] Add role tests first and confirm failure against the rounded implementation.
- [x] Replace platform/font logic with Geist; implement greeting800 / section700 / card700 versus supporting400–500, exact negative tracking and leading.
- [x] Update cards, hero, action/status/stat cards, metadata tiers, dates, nav, role themes and existing guide/onboarding styles. Financial suffix must use a lighter muted TextSpan.
- [x] Update landing font selection/hierarchy without replacing layout or factual copy.
- [x] Test layout/scaling/roles, analyze, build local previews, inspect actual renders and save evidence. No deployment or IPA.

Result: 135 selected tests passed, final31 card/role checks passed, analysis clean, 3 preview builds passed, and actual browser captures saved in docs/reports/2026-11-01-geist-crisp/. Native device checks and releases were not performed.
