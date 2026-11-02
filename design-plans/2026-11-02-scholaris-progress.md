# Implementation ledger — Scholaris own identity

Plan: `C:/scholaris/design-plans/2026-11-02-scholaris-own-identity.md`
Base: `61476a50a3d6bceb36a3a8b6db5bd35baeaad516`, existing isolated `codex/auth-tour-polish` checkout; clean before work.
User accepted the plan on November 2, including calmer weights and a useful Home priority instead of a persistent illustrated hero.

- Baseline: 61 tests passed across hierarchy, dashboard, hero and scholarship-card tests.
- Tasks: (1) calmer student roles, rounded cards, wrapping header; (2) contextual Home priority and matching regression checks; (3) rendering, integration tests and independent review.
- Ruling: retain the compatibility helpers' promotion for unreviewed operator screens; migrate touched student surfaces to explicit Geist roles instead. This avoids silently changing provider/admin typography. Cost: legacy student screens outside this plan still require a later deliberate pass.
- Ruling: run and inspect the typography-first rendering, then continue the approved Home simplification without another approval pause. The user authorized the full plan. Cost: the final Home layout is the next user review point.
- Shared interface: changed student role helpers feed scholarship cards and guided-tour copy; verify both. Shared radius reaches operator cards as required by the project rule; operator typography remains unchanged.

No commit, push or IPA is part of this implementation handoff.

## Implementation completed

- Student role helpers now use distinct 400/500/600/700 weights; Geist files and family registration are unchanged. Scoped student call sites bypass the automatic legacy weight promotion.
- Full-size shared cards use the required 26 px radius, existing crisp border and ambient elevation.
- Home replaces its repeated illustrated discovery hero with the existing application-status banner or a compact live match introduction. The illustration assets, welcome/tour identity and onboarding remain available.
- Home and Discover wordmarks are 20 px and reflow with their header actions at enlarged text sizes. Recommendation headings wrap; See all keeps a 44 px target and moves below when required.
- Scholarship-card titles/providers/amounts have separate roles. Requirements wrap. Large text stacks Details and Apply rather than scaling labels down; readiness, bookmark, status and destinations are preserved.
- Summary tiles become full-width stacked cards at enlarged text sizes, avoiding split words on narrow phones. Existing summary meanings/destinations remain unchanged.
- Reconciled AGENTS.md to the accepted November 2 student hierarchy; operator compatibility roles explicitly remain outside this pass.

## Verification

- Baseline: 61 tests passed.
- Observed failing/passing checks for typography, returning-student hero replacement, large-text card actions and narrow-screen summary reflow. Corrected a lazy-list test fixture to scroll its target into view before asserting geometry.
- Final targeted suite: **163 passed**, covering bundled font metadata and offline loading, role hierarchy, Home statuses/navigation, Discover/filter/search, Saved, card readiness/actions/bookmarks, navigation accessibility, tours/scroll cutouts, mascot identity, provider and admin Home.
- `flutter analyze --no-pub` on the four changed production Dart files: **No issues found**.
- Local fictional student web preview: **build succeeded**. This is a visual fixture, not a production release or proof of physical-device rendering/login.
- `git diff --check`: passed. Impeccable mechanical detector on changed UI targets: empty findings array (Dart coverage is limited; screenshots and widget tests are the visual evidence).
- Latest test/build/analyze logs: `build/identity-final-tests.log`, `build/identity-web-build.log`, `build/identity-analyze.log`.
- Rendered checks span Home/Discover at 320/390/440 px, 1x/1.4x/2x text, and populated/empty/loading/account-error states. Final capture directory: `build/identity-verified`, zero recorded browser errors. Saved was verified by actually tapping its Home tile and captured in `build/identity-saved-verified`, also zero recorded browser errors. Its empty state retains the existing illustration and suggestions; a populated Saved state is covered by widget tests. Representative screenshots are retained under `design-plans/2026-11-02-scholaris-evidence/`.

## Independent review and corrections

- Reviewer found operator title inheritance would change despite preserving the operator helpers. Fixed the base theme to retain its previous display/headline/title/appbar styles, and added a regression check. Calmer explicit student roles remain in Home, Discover, shared scholarship cards and guide copy.
- Reviewer found missing profile was checked ahead of match failure. Fixed the introduction to distinguish actual profile loading from completed/failed profile state, and give failure precedence.
- Reviewer found no other introduced navigation, eligibility, bookmark or tour-target regressions. Physical device, backend/auth and tests were outside that read-only source review.
- No deferred introduced code findings remain. Existing empty-state wording, legacy styles outside the selected surfaces and pre-existing applicant-advice claims were not redesigned in this scope.

## Handoff

Changes are uncommitted on `codex/auth-tour-polish`, based on `61476a5`, in `C:/Users/Windows 11/.codex/worktrees/auth-tour-polish/scholaris`. Existing `C:/scholaris` unrelated work and old IPA archives were preserved. Version/build remains 1.0.0+25; no new IPA was produced. Physical iPhone verification is pending.

## Accepted follow-up: keep the friendly welcome hero

The user clarified that the mascot and hero card are important to Scholaris's friendly impression. This supersedes the earlier decision to remove the recurring welcome card.

- Restored one compact soft-green welcome card combining the personal greeting, portrait and live match introduction. It uses the existing soft-card border/elevation/radius and calmer Geist roles. Application status remains directly below it. There is no second promotional headline or duplicated match introduction.
- Ari and Ariel use the student's stored gender and existing welcome artwork through `getMascotGreetingAssetPath`, shared with the tour introduction. No new artwork or animation. No incorrect default portrait is painted while the profile is unavailable.
- Standard portrait occupies 92x132 logical pixels; narrow/enlarged-text layout stacks an 80x96 portrait and naturally wrapping copy. Both male/female identities were visually inspected at 390 px; 320 px at 1x/2x and 440 px at 1.4x were also rendered.
- Updated the existing regression expectations for the restored card. Full targeted suite rerun: **163 passed**. Analyze on the three changed Dart files: **No issues found**. Web visual fixture rebuilt successfully; five final browser captures recorded **zero errors**.
- Logs: `build/mascot-welcome-final-tests.log`, `build/mascot-welcome-analyze.log`, `build/mascot-welcome-build.log`. Captures: `build/mascot-welcome-captures`; representative male/female screenshots retained in the evidence folder.
- AGENTS.md now explicitly preserves the friendly welcome card so future density refinements do not remove it again. No IPA built; iPhone verification remains pending.

## Follow-up polish: slightly more mascot exposure

- Expanded the normal portrait frame from 92x132 to 104x156 and the stacked frame from 80x96 to 96x116, using the existing art at a slightly larger scale. The standard card is approximately 28 px taller.
- Refined card padding to 12/20/16/16 and grounded the portrait beside the copy with bottom alignment. Preserved text sizes/weights, status navigation, shared card treatment and artwork identity.
- Verification: 58 relevant Home/mascot/tour/typography tests passed; analysis on the changed dashboard found no issues; local web fixture build passed. Five final captures cover both identities at 390 px, 320 px at 1x/2x, and 440 px at 1.4x with zero recorded browser errors.
- Logs/captures: `build/mascot-polish-*`. Durable phone captures: `design-plans/2026-11-02-scholaris-evidence/home-female-polished-390.png` and `home-male-polished-390.png`. No IPA or physical-device verification performed.

## Follow-up art direction: give the hero more character

The user found the plain portrait card too sparse. Reworked its composition using the existing campus-and-graduate artwork, keeping the approved calmer Geist hierarchy and live data.

- Artwork now fills the card's left edge and meets the bottom corners, instead of floating inside a padded portrait rectangle. The campus, foliage and flag restore the product-specific setting. The pale background transitions from greenery to the quieter reading surface.
- Explore matches is a filled green button with the existing destination and readable 44 px minimum target. No additional promotional claims, badges or decorative animation.
- The portrait width adapts between 108/148 px. Greeting measurement and the actual text scaler determine when copy needs a stacked layout; narrow regular text retains the side-by-side illustration. Stacked artwork is centered to avoid an empty corner. Copy and button labels wrap naturally.
- Home uses `getMascotCampusAssetPath`; the tour retains its welcome pose. Both share the existing stored-gender identity convention. Profile loading never paints the wrong default artwork.
- Final verification: 58 relevant tests passed; analysis found no issues; local visual-fixture build passed. Five final renders cover both identities at 390 px, 320 px at 1x/2x, and 440 px at 1.4x, with zero recorded browser errors.
- Evidence: `build/hero-character-final-captures/`, `build/hero-character-final-tests.log`, `build/hero-character-analyze.log`, `build/hero-character-build.log`; durable captures `design-plans/2026-11-02-scholaris-evidence/home-campus-female-390.png` and `home-campus-male-390.png`. No IPA built; physical-device verification remains pending.

## Follow-up hierarchy, spacing and trailing See all

- Replaced the shrink-wrapping recommendations header with a full-width Row: heading expands, See all stays on the trailing edge. At 320 px the heading may wrap beside the action; at enlarged text sizes the action moves below while remaining right aligned. Labels never scale down and the 44px touch target remains.
- Added two geometry regressions at320/390 px; observed both fail before implementation and pass afterward. Existing enlarged-text reflow regression also passes.
- Refined Home hierarchy: greeting24px700, recommendation heading18px700, summary numbers18px600, card titles16px600, supporting prose14px400. The latter two keep their approved shared roles.
- Added8px separation between hero art and text on roomier phones. Adjusted logo/date spacing16px and date/hero12px; overview cards use12px gaps; recommendations are separated by24px. Shared 26px cards and their border/shadow remain intact.
- Verification: **60 relevant tests passed**, dashboard analysis clean, visual-fixture build passed. Five final captures at320/390/440 px and1x/1.4x/2x recorded zero browser errors. Durable evidence: `design-plans/2026-11-02-scholaris-evidence/home-hierarchy-390.png` and `home-hierarchy-320.png`. Logs/captures: `build/home-spacing-*`. No IPA built or physical iPhone verification performed.

## Approved compact homepage typography — November 2, 2026

User approved the disposable compact screenshot, with stronger recommendations hierarchy. Implemented greeting20/700, brand18/700, shared scholarship titles15/700, amount18/700, provider13/400, financial suffix12/500, supporting Home text/actions13, summary counts16/700. Recommendations heading17/700 (above the preview's16) and section separation28px (from24). Existing wrapping, minimum touch targets, trailing See all, mascot identity and live data preserved. AGENTS updated to document this approved scale.

Verified updated existing typography assertions failed before implementation and passed afterward. Combined relevant Home/Discover/mascot/card/Geist suites:93 passed. Analysis on three changed source files: no issues. Web fixture build passed. Chrome captures at390 regular,320 regular,320 at200% text and Discover390 recorded zero browser/runtime overflow errors. Actual phone390 and320 enlarged-text captures visually inspected. Durable evidence: home-compact-implemented-390.png and home-compact-implemented-320-text-200.png in the evidence directory. No physical-device verification, commit or IPA; the full suite was not repeated for this small follow-up (prior six baseline failures remain documented separately).
