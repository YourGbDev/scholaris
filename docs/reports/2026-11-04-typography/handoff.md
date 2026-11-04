# Scholaris typography refinement — implementation handoff

Implemented on `codex/typography-refinement`, based on source `1804904`.
Changes are uncommitted and have not been pushed. No IPA was built.

## Result and design preservation

All app font families and default weights now come from
`lib/shared/theme/app_typography.dart`. The migration covers student,
authentication, onboarding, provider, admin, shared components, overlays,
forms, receipts, tours, chat, safety flows, and standalone previews.

The semantic review assigned 2,068 existing style calls by purpose. A final
inheritance audit migrated another 53 purpose-specific styles and eight
direct theme references. Shared value helpers distinguish actual metrics
from ordinary names, identifiers and status text through explicit roles.

Existing font sizes, line heights, tracking, colors, padding, dimensions,
icons, images and layout rules were retained. Existing optical tracking
and leading were made explicit at migrated callsites where legacy helpers
previously supplied them; no new spacing formulas were introduced.

The matched captures show quieter supporting descriptions, labels and tags,
with section/card headings at 600 and important scholarship values at 700.
Onboarding headlines retain 700 while subtitles remain 400. Navigation
labels use 500. This is a typography migration, not a screen redesign.

## Final platform resolution

1. `kIsWeb` is checked first: return locally bundled `Inter` on every
   browser/operating system, including an iOS browser.
2. Native iOS: return `CupertinoSystemText` below 20 logical pixels and
   `CupertinoSystemDisplay` at 20 or above, using the effective explicit/base
   style size. These are the installed Flutter SDK's supported SF Pro Text
   and SF Pro Display proxies. Inter is a fallback; essential missing-glyph
   and emoji fallback continues through the platform.
3. Android and other platforms: return locally bundled `Inter`, followed by
   Flutter's platform fallback for unsupported glyphs.

The installed SDK is Flutter 3.47.1. Its
`packages/flutter/lib/src/painting/text_style.dart` documents the proxies
and 20-point boundary. This is source verification, not a native iOS
rendering claim. No SF Pro binaries were downloaded or bundled.

Inter 4.1 Regular, Medium, SemiBold and Bold came from the official
[rsms/inter release](https://github.com/rsms/inter/releases/tag/v4.1).
The original SIL license is included. [Font source and SHA-256 hashes](font-provenance.json)
are recorded; tests inspect the font family metadata and OS/2 weight table.
Original Geist files remain on disk. Their unused Flutter registration was
removed, and the separate landing site's fonts and files were preserved.

## Semantic API

Use `AppTypography.style(AppTextRole.<role>, base: existingStyle, ...)`.
Size, height, tracking, color and other existing presentation properties can
be retained. Family and weight are not component-level arguments.

| Weight | Roles |
|---|---|
| 700 | display, screenTitle, metric |
| 600 | sectionTitle, cardTitle, button |
| 500 | bodyEmphasis, label, navigation, badge |
| 400 | subtitle, body, caption, input, placeholder |

Primary and secondary actions share `button`; chips share `badge`.
`applyScholarisTypography` applies the hierarchy to a base theme while
preserving existing button configuration and navigation state colors.
Material text slots, action themes, form decorations, navigation, chips and
dialogs are covered, including implicit controls in standalone previews.

## Verification

| Check | Result |
|---|---|
| Central platform/role/style preservation tests | Passed |
| Semantic component themes, state colors, real card hierarchy, 200% text and Bold Text tests | Passed |
| Student phase suite | 78 passed |
| Provider/admin phase suite | 41 passed |
| Matched visual capture test | 16 passed on original source; 16 passed after migration |
| Final focused typography/theme/hero/chat suite | 34 passed, 2 legacy screenshot cases skipped |
| Final complete Flutter suite | 1,253 passed, 9 skipped, 7 failed; all seven failures reproduced against original source |
| `flutter analyze --no-pub lib test/shared/theme test/typography_visual_capture_test.dart test/screenshots/generate_stitch_screenshots_test.dart` | No issues |
| `node tools/check_typography.mjs` | Passed |
| `node --test tools/check_typography.test.mjs` | 3 passed |
| Production `lib/main.dart` web build | Passed |
| Offline student preview web build | Passed |
| Final Chrome captures | Seven captures; zero browser exceptions/error-console events; all four local Inter font files returned HTTP 200 |
| Dedicated Chrome Flutter test runner | Stalled while loading; canceled. No pass claimed for that run |

The seven original-source failures are four audit-log assertions in
`admin_users_tab_test.dart`, and scholarship ordering assertions in
`auth_boundary_test.dart`, `matches_provider_test.dart` and
`scholarship_repository_test.dart`. They were reproduced with all modified
app source files restored from `1804904` in a separate local verification
copy. Business logic and those tests were not changed to make them pass.

The unrestricted repository-wide analysis also traverses pre-existing
scratch/archived scripts and reports unrelated diagnostics. The final
application/new-test analysis above is clean.

## Before/after evidence

Open the [matched comparison gallery](comparison.html). It contains **23
pairs**: seven genuine Chrome web captures and sixteen Flutter tester
captures of genuine widgets with actual font/icon assets.

- Chrome: home, discover/cards, tracker, profile, scholarship details,
  320-pixel home and 320-pixel home at 200% text.
- Windows tester at 320 and 390 pixels: onboarding, authentication,
  authentication errors, organization provider, individual provider,
  admin, scholarship card, and logout dialog.
- Content includes a long scholarship name, accented names, peso values,
  supporting descriptions, form errors, navigation and status chips.

Baseline screenshots were taken before modifying app source. Additional
provider/admin/error captures and icon-complete widget baselines were
regenerated from the original source in the separate verification copy.
Dates and relative deadlines are fixture-derived; matched runs used the
same day, content, viewport, appearance and text scale. The capture files
are not native iOS or Android evidence.

## Review findings and exceptions

Independent final review found three migration issues: navigation state
colors, dialog content color and implicit ElevatedButton weight in raw
preview themes. All were corrected, and regression tests were observed
failing before the fixes and passing afterward.

No layout/geometry changes were made. The final semantic audit also corrected the dashboard and chat personalized greetings to the display role (700), with dedicated failing-then-passing tests. At 320 pixels and 200% text, the dashboard's long Tagalog greeting splits within a word in both baseline and migrated captures; Inter changes the break positions and can add a line. This existing narrow-layout limitation is documented rather than hidden by reducing the font size or disabling scaling. The following inheritance
cases remain deliberate:

- Emoji-only styles retain their existing geometry and semantic parent;
  platform glyph fallback remains available.
- The color-only onboarding headline span inherits its parent's display
  role, so its family, weight and effective size remain linked.
- Two pre-existing transparent, zero-size compatibility text markers in
  login/dashboard retain their original behavior. They are not visible
  typography and were not introduced or used to conceal overflow.
- Flutter's system Bold Text response remains an accessibility exception
  to the default role weights; text scaling is not disabled or clamped by
  this migration.

The review did not claim actual iOS/Android rendering, physical-device
accessibility behavior or exhaustive screenshot coverage of every state.
Those limits remain explicit below.

## Platform verification status

| Platform | Status |
|---|---|
| Chrome web | Actual matched captures reviewed; local Inter and all four weights configured and metadata tested |
| Web in Safari/iOS or other browsers | Resolver behavior tested; actual browser rendering pending |
| Native iOS | SDK proxy support verified in source; genuine native capture and physical-device accessibility verification pending |
| Native Android | Emulator booted, but isolated preview APK build failed before compilation: Gradle `Unable to establish loopback connection`. IPv4-only retry failed identically. Native rendering remains pending |
| Other native platforms | Inter resolver branch tested; actual native captures pending |

Android build attempts used a separate verification copy with a distinct
application ID. No preview package was installed and existing app data was
not replaced. No production native build settings were changed.

## Files and reproducibility

[Changed-file inventory](changed-files.md) lists each modified/new file and
its purpose. [Semantic review summary](semantic-review.json) records the
role distribution, final inheritance audit and capture list. Relevant
commands and logs are retained in the local ignored
`scratch/typography/` directory. The source guard and capture tooling are
part of this change.

Unrelated landing changes, readiness/coordination reports, generated assets
and all existing IPA/ZIP archives were preserved. No publishing, release,
commit, push, or merge was performed.
