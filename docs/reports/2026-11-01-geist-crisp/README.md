# Geist Sans: compact hierarchy and crisp contrast

Implemented the user's pasted Geist specification, superseding the previous SF Pro Rounded/Nunito direction. All app-owned Flutter text and live landing-page text select locally bundled Geist on every platform. The iOS native typography channel and startup switch were removed.

## Typeface delivery

- Real static weights400/500/600/700/800 are registered; existing landing ExtraBold800 was copied to the Flutter font assets. All five OS/2 embedded weight values and SHA-256 hashes were verified; see font-verification.json.
- Student/provider/admin compiled FontManifests register **only Geist** as the text family, with all five weights. Native/system font references and rounded-family switches were absent from active source and landing selection.
- Previous font assets/reports were preserved as unrelated history but are not selected or registered for shipping app text. Icon fonts and essential missing-glyph fallback remain independent.

## Hierarchy

- Greeting800, tracking-.8, height1.15, dark0F172A. Section headings700, tracking-.6, height1.2.
- Scholarship/action titles17px (16px for compact actions),700, tracking-.35, height1.25,111827.
- Supporting copy/provider/requirements14px400, tracking-.1, height1.4,64748B. Legacy body adapters cap explicit supporting weights at500. Admin subtitles use13–14px regular slate rather than the older12px style.
- Award amounts800, tracking-.4, brandgreen. Frequency suffix is an explicitly lighter13px400 slate TextSpan; slash/unit are kept together when wrapping.
- High-priority pills12px600 with tracking-.15. Secondary attributes11.5px500 with tracking-.1 and slate374151. Existing status colors are preserved.
- Dates11px600 with positive tracking.6. Secondary stat/nav labels500 slate; active nav600. Card surfaces, navigation and content remain unchanged.
- One admin metric-row caption now wraps inside Flexible, resolving a2.1px overflow exposed by the readable13px subtitle. Font size/scaling was not reduced to hide it.

## Verification

- **135 selected tests passed:** typography, card roles and layout, dashboard/hero, Discover, narrow/enlarged text, onboarding/guide, admin workspace/responsive views, provider UI and IAS viewport checks.
- **31 final card/role tests passed** after the last financial-suffix wrap refinement. These overlap the135-test suite; they are not an additional unique count.
- **Analysis:** no issues across lib and relevant changed test/helper targets.
- Student, provider and admin local preview web builds succeeded. All active font families/weights in their compiled manifests were checked.
- Actual browser renders inspected: Home/Discover440px, student360px at200% text, provider/admin desktop, landing desktop. Landing computed font evidence: Geist h1 weight800/tracking-.8px; paragraph400/tracking-.1px; font-load check for800 succeeded.
- Independent review caught section-tracking/admin-subtitle overrides; both were corrected and the final focused review found no remaining actionable issue.
- Mechanical advisories were reviewed: Geist selection and compact heading leading follow the explicit user brief; the static scanner does not resolve the landing page's Tailwind runtime sizes. Existing h2/h4 content structure was preserved. Actual computed landing weights/tracking and rendered hierarchy were checked separately.

## Rendered evidence

- [Discover](discover-440.png)
- [Home](home-440.png)
- [Enlarged text](discover-360-text-200.png)
- [Card wrapping](card-text-200.png)
- [Provider](provider-1280.png)
- [Super admin](admin-1280.png)
- [Landing](landing-1280.png)

All application captures use the existing fictional-data preview entry points, not production data/authentication. Changes remain local to the typography worktree. No deployment, merge, IPA/APK build or CAPTCHA configuration change was performed. Physical-device verification remains pending; browser renders do not prove a native device test.


## Latest phone-reference correction

The user subsequently requested fuller supporting text, explicitly retaining the current gray, size and tracking. `appSupporting` now uses real Geist Semibold600 for provider names, requirements, frequency suffixes, hero counts and guide/supporting captions. Color remains64748B, size13–14px, tracking-.1 and height1.4. Titles, chips and ordinary prose retain their existing styles; global normal body text remains Regular400. Home application-status supporting copy now uses the same semantic helper.

This supersedes the earlier supporting400/500 cap in the pasted brief and above historical description. The latest role tests pin600 plus unchanged color/spacing and also verify that ordinary theme body copy stays400. All110 relevant typography/student/layout/guide tests passed; analysis was clean and the preview build succeeded. The actual updated browser capture is [Semibold supporting text](discover-supporting-600.png).


## Final cross-screen weight restoration

User requested the fuller pre-SF-Pro Geist appearance across all screens while preserving current tracking and gray colors. Eligibility attributes now use Bold700. Shared legacy supporting copy defaults to Semibold600 and no longer caps explicitly requested600/700 at500. Provider/admin body adapters use600 by default and honor explicit weights. Theme body defaults500; explicitly regular400 copy remains regular. Landing paragraphs use600. Current sizes, letter spacing, leading and colors remain unchanged.

Tracker at360px/200% text exposed an existing amount row splitting currency digits. At enlarged text on narrow layouts, the active badge now moves below the amount, preserving its full size and tracking.

Validation:126 selected typography, Tracker, profile, card, discovery, dashboard, provider and admin tests passed;32 Tracker tests passed again after the responsive amount adjustment. Targeted analysis of6 changed Dart files passed. Student/provider/admin web preview builds succeeded. Full project analysis reports10 informational findings in unrelated navbar/signup/verification test files; it is not globally clean. No physical-device verification or release package was performed.

Actual renders: `discover-chips-700.png`, `tracker-fuller-support.png`, `tracker-fuller-360-text-200.png`, `provider-fuller-support.png`, `admin-fuller-support.png`. Landing browser computed style confirmed Geist600 with-.1px tracking.


## November2: title hierarchy across surfaces

User approved Tarsi-inspired weight hierarchy while retaining Geist and current tracking/colors/sizes. Shared page/section/card/action heading roles now use800; descriptions retain600, theme prose500, small muted labels retain their existing role. Dashboard Saved/In Progress/Up to date labels now use700 at13px with-.1 tracking. Compatibility title helpers promote bold titles and14px+ semibold title/action roles to800; smaller medium labels remain unchanged. Landing headings use800.

Standalone scholarship titles were updated across Tracker, saved suggestions, details, decision letters/receipts, provider individual/org views, reviewer and assignment dialogs, QR dialogs, admin lists/oversight and safety report views. Narrative sentences mentioning scholarships remain supporting prose. No typography family switch was introduced.

Validation:117 affected-surface tests passed for the standalone-title pass, followed by139 selected hierarchy/layout/navigation tests passing after the broader title-role update. Targeted analysis passed. Student/provider/admin web preview builds succeeded. Actual Home and Tracker renders inspected; final captures:home-final-hierarchy.png and tracker-final-hierarchy.png. This verifies local previews, not every production route or native physical-device rendering. No commit, release build or deployment performed.


## Precommit verification — November2

Fresh full-suite result:1209 passed,6 skipped,7 failed. The seven remaining failures reproduce on an isolated unchanged HEAD9360c6c archive: admin user-created/edited/deactivated/deleted audit assertions, auth-boundary matching isolation, matches-provider eligibility and scholarship-repository active fixtures. No full-suite-green claim is made.

The audit also found obsolete rounded-theme metrics and a nav-label tint-animation regression in this typography change. Updated the approved-metrics expectations and restored interpolation toward the current slate inactive color;25 motion/accessibility/theme tests now pass. Targeted analysis of those4 files reports no issues. CAPTCHA build-config script and7 CAPTCHA gate/mobile protocol tests pass.

Independent read-only review found no blocking source/font issues and verified embedded400–800 weights. Its minor landing finding was fixed by capping the legacyfont-black utility at800, avoiding unsupported900 synthesis. Existing unrelated untracked font experiments and old reports remain outside this commit. See ARCHI_IPA_HANDOFF.md: integrate into latest build19 release source before producing the new CAPTCHA-enabled IPA; candidatebuild20 must be checked for availability.
