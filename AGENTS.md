# Scholaris mandatory project rules

These rules apply to every contributor and agent, including Codex and Archi. Read them before changing UI or producing an IPA.

## Typography: bundled Geist Sans everywhere

- Every app-owned screen and text surface must use the bundled **Geist Sans** family, registered as `Geist` in `pubspec.yaml`.
- Use the shared `geist(...)` helper and the existing Geist-based application themes. Legacy helpers in `lib/shared/theme/app_theme.dart` delegate to Geist; their names do not authorize another font.
- This includes student, provider and admin screens, onboarding/tours, chat, dialogs, sheets, forms, validation messages, buttons, labels, receipts and preview apps. Do not introduce a different font through `GoogleFonts`, local `ThemeData`, `TextStyle`, or a component override.
- Keep appropriate Geist weights, line height, accessible text scaling and wrapping. Do not replace text with an image or shrink it to hide an overflow.
- Platform-owned keyboards/system UI and essential missing-glyph fallback are outside this app-owned typography requirement. Otherwise, a font exception requires the user's explicit instruction.
- Before handoff, inspect changed themes/styles, run the relevant UI/typography tests, and verify the actual rendered result when device/browser access is available. Do not claim a video alone proves the font family.

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

- Stage and commit only the authorized task's files. Preserve unrelated landing work, readiness/coordination reports, generated assets and IPA/ZIP archives.
- Build from the intended committed source using the production entry point, not a regression-preview entry point. Assign the next unused build number when a new IPA is authorized; keep old archives in place.
