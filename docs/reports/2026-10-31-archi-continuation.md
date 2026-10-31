# Archi continuation — user paused Codex to preserve weekly allowance

Continue SOLO in this existing worktree. Do not recreate or discard it:
C:/Users/Windows 11/.codex/worktrees/auth-tour-polish/scholaris
Branch: codex/auth-tour-polish. Base: 1804904 (Build 17).
Auth implementation committed locally as 92bc876. NOT PUSHED.
Tour refinements, mascot identity correction and final auth review fix are UNCOMMITTED. Preserve them and all untracked regression tests. Preserve unrelated C:/scholaris landing/reports/assets/IPA archives.

Read AGENTS.md and the two approved plans:
- docs/superpowers/plans/2026-10-31-auth-lifecycle-polish.md
- docs/superpowers/plans/2026-10-31-ari-scroll-cutout-polish.md
- docs/reports/2026-10-31-auth-tour-pre-defense-audit.md

Implemented A: user+scholarship essay/recommender keys; stale async write guards; tab reset on identity changes; shared profile readiness/router microtask coalescing; authenticated Login busy/error/retry; atomic dashboard counts with unknown placeholders; light CAPTCHA WebView/bootstrap cover, nonce-bound ready protocol, first terminal result, SDK timeout distinct from human challenge time.
Final review additionally added loginCaptchaProvider test seam and an auth-session epoch: an old CAPTCHA result cannot exchange credentials after a session change. New regression RED then GREEN; 10 auth/isolation tests passed.

Implemented B: real ScrollPosition drag/fling; Home scroll-notification bridge and local detail/review observation; notes/scrim/hand fade in 150ms during browsing, restore after 350ms settled; net user progress threshold min(400, remaining feed) with explicit continue; no auto-opening; separate full-card highlight and View Details action rectangles; smooth alignment before highlighting; oversized-card action positioning, compact scrollable note, actual button required; Back/Skip cancellation; male Ariel / female Ari helpers used in tour/chat and documented in AGENTS.

Checks:
- Full suite before latest CAPTCHA epoch fix: 1222 passed, 6 skipped, 4 failed. All 4 are admin_users_tab_test audit-event assertions, reproduced separately in unchanged C:/scholaris (admin-baseline.log). Do not claim all green or fix unrelated admin scope silently.
- Latest focused auth/isolation: 10 passed (final-auth-review.log).
- Responsive tour/details/fling tests: 13 passed (b-responsive-final.log), including 320x568 at 200% text and 568x320 landscape.
- CAPTCHA layout and iOS build-config node scripts passed.
- FINAL full suite launched with latest changes; inspect .superpowers/sdd/auth-tour-polish/full-final-approved.log and .exit before rerunning. Session 84322 was still running at user pause.
- FINAL analysis launched; inspect analysis-release.log. Session 22369 was still running at pause. Earlier analysis had only minor flow-control/style findings plus two PRE-EXISTING http dependency infos in verify_email_screen_test.dart; most new findings were subsequently fixed. Confirm actual final output.
- git diff --check previously passed; repeat after final edits.

Browser access recovered. Fresh 390x844 app captures are in .superpowers/sdd/auth-tour-polish/captures (both actual male/female Home, heroes, header pill, open plus menu, female Ari intro, saved note, Discover cue/settled/full-card, real detail and milestone). Gender was checked visually, not URL-only. Browser walkthrough verified clear viewport during scrolling, explicit continue, whole-card top visible before details, real detail Back to top gate. Latest tiny responsive/auth fixes came after the preview's initial compilation: restart/reload before further claims.
Preview is running FROM THIS WORKTREE on 127.0.0.1:5047, Flutter session 16897; do not start a duplicate. The user has the female tour open. No new IPA/version bump/deployment performed.

Remaining: finish final solo review/check outputs, ensure no negative/offscreen spotlight geometry issue, keep unrelated files unstaged, commit authorized changes and push codex/auth-tour-polish (no force push). Save final handoff and test evidence/captures as appropriate; scratch .superpowers is untracked and must not be staged wholesale. The copied ignored lib/app/supabase_config.dart is local config: NEVER stage or print it.

Then build the new production IPA using existing GitHub Actions workflow on the exact committed source and next unused build number (verify; last known release was 17). CAPTCHA MUST be enabled with existing production site key and challenge URL. The hosted web/captcha_challenge.html v2 update has NOT been deployed: deploy/verify the actual HTTPS challenge version and forced-light settings before shipping. Preserve nonce/origin checks and server enforcement. Verify actual compiler log defines, run node tools/test_ios_captcha_build_config.mjs and CAPTCHA tests. Build lib/main.dart, never regression preview. Report source/release commits, version/build, workflow, IPA path, SHA-256 and CAPTCHA build-log evidence. Physical iPhone first-paint/CAPTCHA/login verification is PENDING; do not claim it was tested. Do not redesign the app.
