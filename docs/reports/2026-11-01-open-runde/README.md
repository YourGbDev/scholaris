# Open Runde implementation and verification

November 1, 2026, Asia/Manila. User explicitly approved replacing Geist with Open Runde after reviewing Home/Discover concepts. Onboarding flow work is separate.

## Delivered source

Branch: `codex/open-runde-typography`, based on `1804904c45594803989e5d7ec83e5b3ec09d25dd`.
Managed worktree: `C:/Users/Windows 11/.codex/worktrees/open-runde-typography/scholaris`.
No changes were transferred into the dirty `C:/scholaris` checkout or Archi's worktrees.

- Bundled unmodified Open Runde OTF files in weights 400/500/600/700 plus SIL OFL license, pinned to upstream revision `3e7ed7f3cdfa5523766db7e430066472615fc935` from https://github.com/lauridskern/open-runde.
- All app-owned explicit font overrides select `kAppFontFamily = 'OpenRunde'`. Existing `geist`, `outfit`, `openSans`, `poppins` and `inter` helper names remain compatible and select the same family. Role adapters and overlays/previews follow it too.
- Default theme body is medium, heading/label adapters use natural tracking and relaxed leading. Explicit caller settings remain supported. Student cards have bold naturally wrapping titles, semibold supporting gray, clearer group spacing and untruncated requirements. Home hero uses less cramped heading/subtitle spacing and removes its redundant eyebrow.
- Updated AGENTS.md to record the owner's approved font standard. Existing Geist assets remain preserved as legacy assets, not the selected app family.

## Verification

- Initial three-suite baseline: 36 tests passed.
- Observed the new family tests fail with actual Geist versus expected OpenRunde before implementation.
- Final targeted run: **117 tests passed** across shared font/theme, card, dashboard/hero, discovery, overflow, IAS/admin viewports, application/detail tours, quick actions, CAPTCHA gate and mobile protocol.
- Real-font fixtures now load all four weights. Two intermediate enlarged-dashboard tests failed using the Ahem placeholder; the same assertions passed after loading the actual shipped font, without weakening the assertions.
- Independent code review found remaining optical-tracking defaults and missing Medium in old test loaders. Both corrected. Added a regression that first failed on `0.216` tracking and then passed with natural tracking and preserved explicit overrides.
- `flutter analyze --no-pub lib` and final analysis of lib plus the eight changed/supporting test targets: **no issues found**.
- `flutter build web --no-pub --target lib/dev/student_regression_preview/main.dart`: **succeeded**. This is an explicitly local fictional-data preview, not a production deployment or production-entry-point release build.
- Compiled font manifest includes OpenRunde; all four font files and OFL asset are present in the web bundle.
- `node tools/test_ios_captcha_build_config.mjs`: passed; no workflow/auth settings were modified.
- Actual browser inspection of rendered Home and Discover at 440x956, plus a 360px-wide fixture at 200% text with scrollable wrapped content; screenshot files `home-440.png` and `discover-440.png`. The screenshots show actual Flutter rendering, not generated concept art. Fictional fixture data differs from the owner's live screenshots. Browser screenshots alone are not the font-family proof: source, manifest and bundled-font tests provide that evidence.

## Limits

No IPA, release-number bump, push, merge, deployment, production data/configuration change or physical-device login was performed. iPhone-specific rendering and login remain pending a separately authorized CAPTCHA-enabled build. This change does not claim that Open Runde is the exact font used by every native Tarsi version; it is the identified publicly bundled family chosen by the owner.

The existing onboarding now inherits the new font; its content and flow were not redesigned. The richer name-first onboarding remains the next design discussion.
