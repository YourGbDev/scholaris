# Scholaris mandatory project rules

These rules apply to every contributor and agent, including Codex and Archi. Read them before changing UI or producing an IPA.

## Typography: bundled Geist Sans on every platform

Every app-owned text surface (including landing, student, provider, super admin, forms, dialogs, tours and previews) uses locally bundled Geist. No native/system font switch or GoogleFonts override. Preserve the landing icon font separately.

- Register the real Geist 400/500/600/700/800 faces. Do not synthesize Black900; shared helpers cap unsupported weights at800. Use `geist(...)`, `appGreeting(...)`, `appHeading(...)`, `appCardTitle(...)`, `appSupporting(...)` and shared themes; historical helper names do not authorize another family.
- User-approved November 2, 2026: Home, Discover and the shared student scholarship card use a calmer hierarchy. This supersedes the earlier Tarsi-inspired extra-bold student roles; do not restore weight800 everywhere.
- User-approved November 3 open hero supersedes the older soft-green campus card: greeting and live match summary sit directly on white beside the canonical transparent portrait. Keep the compact hierarchy and application-status card below, with a small Explore matches text action and 44px target. Home/tour resolve assets/mascots/greetings/ariel.png or ari.png from stored gender. Ariel is about 7% taller; preserve original proportions. Shared welcome/login uses welcome_pair.png with matching faces, close overlapping shoulders and one straight bottom crop; stature reference is Ariel 5 foot 11 versus Ari 5 foot 3. Preserve pose-specific onboarding illustrations with the same emerald palette; no scenery or gradient around the hero. Home wrist/head animation runs for 2.8 seconds then rests for 3 seconds; reduced motion, inactive tabs and background lifecycle remain still. Keep Ari's adjacent hair and both shoulders outside the wrist animation.
- Student greetings:20px700, tracking-.4, height1.2, brandgreen. Student page headings:20px700, tracking-.3, height1.25. Section headings:17px700, tracking-.15, height1.25. Scholarship titles:15px700, tracking-.15, height1.3. Body/provider names:13–14px400, height1.45, `kTextSecondary`. Supporting metadata:12–13px500, height1.4, `kTextSupporting`. Actions:13px600. Dashboard summary labels:13px500.
- Student amounts:18px700, tracking-.3, height1.2, brandgreen. Financial suffixes use a separate muted Geist500 TextSpan. Status pills:12px600; neutral eligibility chips:12px500. Overlines:11px600, positive tracking.6. Navigation labels retain their existing500/600/700 roles.
- Compact Home/card overrides approved from the screenshot preview: Home brand18px700, application-status title13px700, prose/actions13px, shared scholarship provider13px400 and financial suffix12px500. Preserve the normal text scaler and minimum touch targets.
- Home-specific hierarchy: recommendation heading17px700, summary counts16px700. Keep See all on the trailing side of the heading at standard phone sizes; wrap the heading rather than shrinking it. At enlarged text sizes, stack the action below and align it to the trailing edge. Keep the 44px touch target. Group overview surfaces with12px gaps and separate recommendations with28px.
- User-approved final polish applies the same hierarchy to student, provider, super admin and landing surfaces: titles700, prose400, supporting metadata500 and actions600. Shared helpers honor explicit weights; do not automatically promote titles to800. Body and metadata use natural tracking0; titles use restrained negative tracking (about-.15 at16px and-.3 at20px). Keep positive tracking.6 for overlines. Use neutral surfaces for ordinary information; preserve meaningful status colors.
- Desktop provider/super-admin page titles use24px700 and narrow layouts20px700; sections17, cards15, prose13–14, metadata12–13. Keep meaningful metrics24–28 and already-small labels readable. Landing marketing hero52px desktop/30–34px phone, sections32/24; its artwork labels and recorded screenshot text retain their own scale. Never apply a global textScaler reduction.
- User-approved entry revamp: /onboarding contains Welcome followed by Discover, Match, Track and Companion; shared welcome content also supports /intro. New transparent poses live in assets/mascots/onboarding. Keep compact24px700 entry headlines,14px regular prose and13px600 actions, scrollable content and44+targets. Student login stays form-led and preserves CAPTCHA/session/lockout/recovery. AI replies remain planned; onboarding labels AI Coming soon. The chat first-use guide and QR/upload/Discover shortcuts are implemented with honest tool explanations and disabled AI sending.
- Preserve readable wrapping, accessibility scaling and meaningful status colors. Do not replace text with images or shrink it to hide overflow. Native system UI and essential missing-glyph fallback are exceptions; other font exceptions require explicit user instruction.
- Run relevant typography/UI tests and inspect actual rendered results before handoff. Do not claim native device verification without a device.

## Consistent content-card surfaces

- Full-size content cards use the shared scholarship-card treatment: `kRadiusCard` (26 px), `kCardBorderCrisp` (0.75 px neutral-gray border, strengthened November 3 for visibility on white), and `kCardElevationCrisp` (soft ambient shadow). Reuse `kSoftCardDecoration` rather than introducing another neutral card style.
- Keep outer Material/InkWell/clip corners aligned with the card decoration. Preserve meaningful status borders and colors. Buttons, fields, pills, icon containers and nested rows keep their purpose-specific shapes; they are not full-size cards.
- Use the shared card tokens in role-specific themes as well. Verify narrow layouts and enlarged text when changing padding.
- White search fields and light controls must retain visible neutral edges. Keep purpose-specific shapes and semantic status colors. Header notification/settings shortcuts use the shared glass material with a visible rim on white and a solid high-contrast fallback; do not replace them with a borderless white capsule.
- Provider entry pages and workspace canvases use white, including loading/access-error surfaces. Student authentication/recovery pages retain their white canvas and outlined fields. Landing keeps its existing warm off-white section canvas; do not flatten its composition as a side effect of app surface changes.

## Quiet student surfaces

- User-approved November 3: student page canvases use `kStudentCanvas` (white); ordinary inset rows use neutral `kStudentSurfaceSubtle` and `kStudentDivider`. Keep the open white mascot hero and meaningful status colors. Guide scrims are neutral black, with white speech bubbles.
- Match details describe actual matched criteria without simulated percentages or selection predictions. Profile completeness describes saved profile fields, not scholarship eligibility or invented grant counts. Requirements use quiet rows with genuine readiness labels; preserve neutral eligibility chips.

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

## Mascot identity

- Ariel is the male mascot; Ari is the female mascot. Resolve both name and artwork from the student's stored gender using the shared mascot helpers. Tour/Home keep this matching identity. User-approved November 3 exception: Chat introduces the OTHER companion (male/unset student → Ari, female student → Ariel), with the matching new chest-up chat artwork. Chat must not change the Home/tour identity.

## Chat guide presentation

- User-approved November 3: show all three chat introduction screens whenever Chat is opened, including returning users with an old completion preference. Skip and Start chat dismiss the guide for that visit only; Help can replay it. Preserve all six bust poses and the opposite-companion pairing. Do not restore first-use-only behavior without user approval.
