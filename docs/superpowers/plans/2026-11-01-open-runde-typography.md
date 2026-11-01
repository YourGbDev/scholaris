# Open Runde typography implementation plan

> Execute inline using the executing-plans skill; obtain one final independent code review.

**Goal:** Implement the user-approved friendly, rounded typography across Scholaris, then evaluate onboarding separately.

**Approved design:** November 1 chat and Home/Discover concepts: bundled Open Runde 400/500/600/700; bold headings, substantial medium/semibold gray supporting text, natural tracking and relaxed line spacing. Preserve layouts, colors, shared content-card treatment, authentication and accessibility. Image concepts establish direction, not exact font rendering.

**Architecture:** Switch the shared font family and legacy typography helpers together; centralize the family name so app, role themes, overlays and preview entry points cannot drift. Tune only the existing Home/Discover/card text rhythm. Use the author's unmodified font files and OFL license. Preserve old assets and unrelated work.

**Scope constraints:** No onboarding flow changes, new features, backend changes, publishing, IPA build or version bump. The user's explicit font-switch instruction supersedes the previous Geist-only rule; update AGENTS.md accordingly.

## Tasks

- [x] Baseline: run existing font/card/hero tests in isolated worktree based on current release source 1804904.
- [x] Red: update the font-family/role tests to require OpenRunde and add a real bundled-font manifest/loading check; run and observe the expected mismatch before implementation.
- [x] Bundle author-sourced font weights and license; register OpenRunde; change shared helpers/themes and explicit overlay/preview overrides. Retain legacy helper names as compatibility aliases.
- [x] Tune heading/body theme weights, natural tracking and Home/Discover/card spacing without shrinking text or hiding overflow. Update existing real-font test fixtures.
- [x] Verify targeted typography, narrow/enlarged-text cards, dashboard, auth, role UI and tour tests; analyze app source; compile a local web preview and inspect actual rendered Home/Discover plus narrow/enlarged text.
- [x] Obtain independent final review; address material findings; document font provenance, checks, preview screenshots, source/branch, and pending device checks.

## Review focus

- Long scholarship names and provider labels must wrap with the real fonts.
- Narrow screens and enlarged text must not lose essential actions.
- All role themes, modal/overlay text and preview themes must select the same bundled family offline.
- Font changes must not touch auth/security behavior or misrepresent a preview as a release build.
- Legacy helper names must not imply a remaining Geist override.

## Execution ledger

Started in managed worktree `open-runde-typography/scholaris`, branch `codex/open-runde-typography`. Current root and Archi worktrees left intact. Actual results appended at handoff.

Final: 117 targeted tests passed; final source/changed-test analysis clean; local web preview build passed. Independent review findings corrected with a failing/passing tracking regression and all-weight font loaders. Actual 440px browser screenshots plus 360px/200% text captures saved under docs/reports/2026-11-01-open-runde. Full handoff details in that folder’s README.md.
