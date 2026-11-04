# Scholaris mandatory project rules

These rules apply to every contributor and agent, including Codex and Archi. Read them before changing UI or producing an IPA.

## Typography: platform-adaptive semantic roles

- `lib/shared/theme/app_typography.dart` is the single authority for font families and role weights. Use `AppTypography.style(AppTextRole.<role>, ...)`; do not define font families or weights independently in components or restore legacy font helpers.
- Check `kIsWeb` first. Every web browser/OS uses locally bundled **Inter**, including Safari on iOS. Android and other native platforms also use bundled Inter. Native iOS uses **SF Pro** through Flutter's supported `CupertinoSystemText`/`CupertinoSystemDisplay` system-font proxies, not downloaded or bundled copies of SF Pro.
- Exact default weights: **700** `display`, `screenTitle`, `metric`; **600** `sectionTitle`, `cardTitle`, `button`; **500** `bodyEmphasis`, `label`, `navigation`, `badge`; **400** `subtitle`, `body`, `caption`, `input`, `placeholder`. Primary/secondary actions share `button`; chips share `badge`. No default 800/900 weights.
- Apply these roles to every student, provider and admin surface, onboarding/tours, chat, dialogs, sheets, forms, validation messages, navigation, receipts, and previews. Use `applyScholarisTypography` when a standalone preview needs its own base theme.
- Choose roles by actual purpose, not by old weights, text size, or whether a string happens to contain digits. Shared helpers with mixed purposes accept an explicit semantic role. Supporting text stays quieter than headings; important amounts and metrics use `metric`.
- Preserve existing font sizes, heights, tracking, colors, spacing, component dimensions and geometry. Correct only verified rendering issues, documenting the problem and correction. Do not shrink text, replace text with images, clamp system text scaling, or redesign screens to conceal overflow.
- Preserve Flutter text scaling and system Bold Text. System-requested bolding and essential missing-glyph/emoji fallback are accessibility exceptions; other semantic exceptions require documented justification. Platform-owned keyboards/system UI are outside the app-owned typography requirement.
- Bundle genuine Inter 400/500/600/700 assets with their license; do not download fonts at runtime. Keep the font source and hashes documented.
- Before handoff, run `node tools/check_typography.mjs`, `node --test tools/check_typography.test.mjs`, the semantic typography tests, and relevant UI tests. Compare matched before/after captures, including narrow layouts and enlarged text. Native iOS and Android rendering need genuine platform captures; a simulated target-platform override or video alone does not prove the actual font family. Label unavailable platform checks pending.

## Consistent content-card surfaces

- Full-size content cards use the shared scholarship-card treatment: `kRadiusCard` (26 px), `kCardBorderCrisp` (0.75 px neutral-gray border, strengthened November 3 for visibility on white), and `kCardElevationCrisp` (soft ambient shadow). Reuse `kSoftCardDecoration` rather than introducing another neutral card style.
- Keep outer Material/InkWell/clip corners aligned with the card decoration. Preserve meaningful status borders and colors. Buttons, fields, pills, icon containers and nested rows keep their purpose-specific shapes; they are not full-size cards.
- Use the shared card tokens in role-specific themes as well. Verify narrow layouts and enlarged text when changing padding.
- White search fields and light controls must retain visible neutral edges. Keep purpose-specific shapes and semantic status colors. Header notification/settings shortcuts use the shared glass material with a visible rim on white and a solid high-contrast fallback; do not replace them with a borderless white capsule.
- Provider entry pages and workspace canvases use white, including loading/access-error surfaces. Student authentication/recovery pages retain their white canvas and outlined fields. Landing keeps its existing warm off-white section canvas; do not flatten its composition as a side effect of app surface changes.

## Quiet student surfaces

- User-approved November 3: student page canvases use `kStudentCanvas` (white); ordinary inset rows use neutral `kStudentSurfaceSubtle` and `kStudentDivider`. Keep the open white mascot hero and meaningful status colors. Guide scrims are neutral black, with white speech bubbles.
- Match details describe actual matched criteria without simulated percentages or selection predictions. Profile completeness describes saved profile fields, not scholarship eligibility or invented grant counts. Requirements use quiet rows with genuine readiness labels; preserve neutral eligibility chips.

## Neutral operational workspaces

- User-approved November 3: individual provider, organization and admin workspaces use white canvases, neutral supporting surfaces, and charcoal-selected filters through the shared workspace theme. Keep the platform-adaptive semantic typography and visible crisp card/control edges. Do not restore seeded Material pastel chips, decorative green/blue/cream panels, or category-colored metric tiles.
- Preserve green primary actions/navigation and meaningful success, warning, error, decision, safety and chart-series indicators. Informational guidance and ordinary metadata stay neutral; color does not substitute for a status label.

## Every IPA must enable CAPTCHA

- **CAPTCHA is mandatory for every Scholaris IPA, including development, demo and sideload builds. Never build or hand off an IPA with CAPTCHA disabled.** Authentication must remain usable with the backend's CAPTCHA requirements.
- Prefer the existing `.github/workflows/build_ios.yml`. For manual runs explicitly set `captcha_enabled=true` and select the intended release branch/commit.
- A direct Flutter iOS build must provide all three existing production settings:
  - `--dart-define=SCHOLARIS_CAPTCHA_ENABLED=true`
  - `--dart-define=SCHOLARIS_CAPTCHA_SITE_KEY=<existing configured site key>`
  - `--dart-define=SCHOLARIS_CAPTCHA_PAGE_URL=https://scholaris-captcha.pages.dev/captcha_challenge`
- Preserve the native CAPTCHA WebView, current configured site key, challenge page and Supabase authentication configuration. Do not invent replacement keys or expose secrets in reports.
- Verify the actual compiler/build log includes the enabled flag and the expected key/page settings. Run `node tools/test_ios_captcha_build_config.mjs` and the CAPTCHA gate/mobile protocol tests when available. A default setting or a successful archive operation is not sufficient proof of the actual build configuration.
- Complete CAPTCHA and log in using the built IPA on a physical device when available. If device access is unavailable, explicitly label that verification pending; never claim login was tested. If CAPTCHA/login fails, diagnose and fix the configuration. Do not bypass the problem by disabling client CAPTCHA or server enforcement.
- Handoff must identify the exact source/release commit, version/build number, workflow run, IPA location and SHA-256, CAPTCHA build-log evidence, and device login verification status.

## Preserve unrelated work

- Before releasing a UI-only change, verify the latest intended product UI baseline and matched screens. A font migration must preserve newer product changes rather than inherit an outdated release checkout.

- Stage and commit only the authorized task's files. Preserve unrelated landing work, readiness/coordination reports, generated assets and IPA/ZIP archives.
- Build from the intended committed source using the production entry point, not a regression-preview entry point. Assign the next unused build number when a new IPA is authorized; keep old archives in place.

## Mascot identity

- Ariel is the male mascot; Ari is the female mascot. Resolve both name and artwork from the student's stored gender using the shared mascot helpers. Tour/Home keep this matching identity. User-approved November 3 exception: Chat introduces the OTHER companion (male/unset student → Ari, female student → Ariel), with the matching new chest-up chat artwork. Chat must not change the Home/tour identity.

## Chat guide presentation

- User-approved November 3: show all three chat introduction screens whenever Chat is opened, including returning users with an old completion preference. Skip and Start chat dismiss the guide for that visit only; Help can replay it. Preserve all six bust poses and the opposite-companion pairing. Do not restore first-use-only behavior without user approval.
