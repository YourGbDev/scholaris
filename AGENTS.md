# Scholaris mandatory project rules

These rules apply to every contributor and agent, including Codex and Archi. Read them before changing UI or producing an IPA.

## Typography: bundled Geist Sans on every platform

User-approved November 1, 2026: the pasted Geist crisp-contrast brief supersedes SF Pro Rounded, Nunito and Open Runde. Every app-owned text surface (including landing, student, provider, super admin, forms, dialogs, tours and previews) uses locally bundled Geist. No native/system font switch or GoogleFonts override. Preserve the landing icon font separately.

- Register the real Geist 400/500/600/700/800 faces. Do not synthesize Black900; shared helpers cap unsupported weights at800. Use `geist(...)`, `appGreeting(...)`, `appHeading(...)`, `appCardTitle(...)`, `appSupporting(...)` and shared themes; historical helper names do not authorize another family.
- Greetings:800, tracking-.8, height1.15, dark0F172A. Section headers:800, tracking-.6, height1.2. Card/action titles:16–17px,800, tracking-.35, height1.25, dark111827. Latest approved scholarship-title exception:800 across cards, Tracker, saved suggestions, details, provider/admin lists and related dialogs/receipts. Preserve each surface’s existing size, tracking, leading and color; shared title/action roles now resolve to800 for strong titles, while small medium labels remain unchanged. Dashboard Saved/In Progress/Up to date labels use700.
- Latest user-approved phone-reference correction: supporting captions/provider names/requirements/frequency suffixes use Geist600 for more weight. Keep13–14px, tracking-.1, height1.4 and the existing slate64748B unchanged. Shared compatibility supporting helpers (including Tracker, profile, provider and admin) default to600 and honor explicitly requested weights without a500 cap. Theme body defaults500; explicitly regular prose stays400. This supersedes the pasted brief’s earlier subtitle400/500 cap; preserve current sizes, tracking, leading and colors.
- Amounts:700/800, tracking-.4, brandgreen. Financial suffixes use an explicitly separate Geist600 muted TextSpan.
- Status pills:12px600, tracking-.15. Latest phone-reference eligibility chips:11.5–12px700, tracking-.1, slate374151. Overlines only:11px600, positive tracking.6. Secondary/nav labels500; selected nav600/700.
- Preserve readable wrapping, accessibility scaling and meaningful status colors. Do not replace text with images or shrink it to hide overflow. Native system UI and essential missing-glyph fallback are exceptions; other font exceptions require explicit user instruction.
- Run relevant typography/UI tests and inspect actual rendered results before handoff. Do not claim native device verification without a device.

## Consistent content-card surfaces

- Full-size content cards use the shared scholarship-card treatment: `kRadiusCard` (26 px), `kCardBorderCrisp` (faint 0.5 px border), and `kCardElevationCrisp` (soft ambient shadow). Reuse `kSoftCardDecoration` rather than introducing another neutral card style.
- Keep outer Material/InkWell/clip corners aligned with the card decoration. Preserve meaningful status borders and colors. Buttons, fields, pills, icon containers and nested rows keep their purpose-specific shapes; they are not full-size cards.
- Use the shared card tokens in role-specific themes as well. Verify narrow layouts and enlarged text when changing padding.

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
