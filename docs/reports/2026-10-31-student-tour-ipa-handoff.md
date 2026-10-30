# Student tour IPA handoff

Source branch: `codex/student-tour-ipa-handoff`, based on Build 15 commit `e657672`.

This handoff contains the compact Home/Discover refinements, grouped header actions, chat quick action, mandatory Geist overrides, gender-specific greeting, new male waving asset, and the real-screen student application tour. The authoritative latest behavior is described in the final section of `docs/reports/student-device-feedback-2026-10-31/implementation.md`. Earlier example-page descriptions in that report are superseded.

The later approved card-consistency refinement is also on this branch. Fetch its latest commit rather than pinning the earlier `d18be89` tour-only handoff: primary student cards now share 26 px corners, a faint 0.5 px outline and the scholarship card's soft shadow. Tracker also uses 20 px padding, with a wrapping progress footer for narrow layouts. Shared Material/admin/provider card tokens follow the same shape/elevation values. New validation: 156 affected tests passed and all 15 changed Dart files passed analysis. No version bump or IPA build was performed for this refinement; CAPTCHA requirements remain mandatory.

## Build instructions

- Fetch and build the exact published handoff commit. Do not rebuild old Build 15 or use a preview entry point. The production target is `lib/main.dart`.
- Build 16 was assigned in release commit `9d52abd` before the card-consistency follow-up. For a new IPA containing the card changes, assign the next unused iOS build number (17 if still available) in a separate release commit. Keep the marketing version unless another release requires changing it.
- Preserve the existing native CAPTCHA and Supabase configuration. Use `.github/workflows/build_ios.yml` with `captcha_enabled=true`. This handoff branch does not match the workflow's push triggers, so dispatch the workflow explicitly on the final release commit and avoid duplicate runs.
- Verify the compile log includes `SCHOLARIS_CAPTCHA_ENABLED=true`, the existing `SCHOLARIS_CAPTCHA_SITE_KEY`, and `SCHOLARIS_CAPTCHA_PAGE_URL=https://scholaris-captcha.pages.dev/captcha_challenge`. Do not disable CAPTCHA or change server authentication requirements to work around a build/login issue.
- Produce the sideloadable `Scholaris-iOS-App` artifact using the existing workflow. Download into a new build-specific directory without overwriting old IPA archives. Report the source and release commits, workflow URL, version/build, IPA location, size and SHA-256.
- Inspect the archive for bundled Geist fonts and `assets/images/mascot_male_welcome_wave.png`. Confirm native CAPTCHA WebView packaging. A successful build alone does not verify login; complete CAPTCHA and log in on a physical device if one is available, otherwise report that check pending.
- Preserve unrelated local landing work, readiness/coordination reports, generated assets, archives and backend data. No database changes are required for this handoff.

## Current verification and limits

- Fresh pre-commit run: 111 affected student UI/navigation/card/chat/guide tests passed. Seven CAPTCHA gate/mobile protocol tests passed. `node tools/test_ios_captcha_build_config.mjs` passed. All changed/new Dart files passed targeted analysis.
- The latest whole-suite result predates the final real-screen correction: 1,223 passed, nine skipped and four known admin audit-event assertions failed. Do not describe the full suite as green.
- Fresh browser visual verification is blocked by Work settings. No fresh device/IPA test is claimed in this handoff. Record the next physical-device tour for review.
- Application practice must never upload, save a draft or submit a real application. Its review layout is reused through isolated tour hooks; actual Tracker receives no fabricated application. Chat has no AI backend yet.

## Device recording checklist

Record CAPTCHA/login, Home, optional welcome with Skip/Continue, Saved/In Progress notes, a slow Discover browse all the way to the end, exactly one scholarship detail through its actual Back to top, demo review/submission/celebration, Tracker, Profile sections, quick actions, Chat and Settings replay/Skip. Include male and female profiles if available. Pause to read notes, try a short scroll before a full scroll, and capture any unexpected jump or blocked touch. Avoid exposing passwords, security tokens or private documents.
