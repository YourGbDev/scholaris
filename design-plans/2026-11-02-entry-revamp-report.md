# Student entry revamp — November 2, 2026

Implemented in the auth-tour-polish worktree using the approved compact Geist direction and local Tarsi screenshots as reference. User explicitly requested new mascot poses. Existing homepage, role and landing work remains preserved and uncommitted.

## Delivered

- Five-screen introduction: Welcome, Discover, Match, Track and Companion. Welcome is inside /onboarding because that is where the existing signed-out startup route leads. /intro reuses the same welcome content, and its Get Started action opens the feature portion through a clamped step query.
- White canvas,24px700 headings,14px prose,13px600 actions, restrained tracking, clear four-step progress, consistent Back/Next/Skip and immediate Log in access from Welcome. Short/large-text content scrolls without shrinking typography; page state is preserved when progress/footer become visible. Reduced-motion controls jump directly between pages.
- Five newly generated transparent Ari/Ariel poses, identity-referenced and saved under assets/mascots/onboarding. Original art and Home campus illustration unchanged. See 2026-11-02-entry-mascot-assets.md.
- Student login is now a restrained440px form: small paired mascot, Welcome back, email/password with labels/autofill, password toggle, recovery, remember-me,48px Sign in, signup and secondary provider link. Removed decorative stage/badges/inert Help and unsupported social/institution sign-in panels. No hidden zero-size compatibility text. Form entrance is200ms and honors reduced motion. Remember-me label has44px minimum tap area.
- Existing CAPTCHA, lockout, epoch/session boundary, recovery and remember-me/provider-launch behavior retained. No new AI, QR or document processing implemented; companion slide explicitly labels future AI/integrated tools Coming soon.

## Verification

- 30 onboarding/intro/router tests pass, including five-screen navigation, Back/swipe/skip/login/completion flags and320x568 at200% text. Updated existing visual assertions to truthful composition; behavior assertions retained.
- 95 focused login/auth/CAPTCHA/mobile-protocol/recovery/security/Geist tests passed; final61 focused entry/login/ceremony/verify-email tests passed after review fixes.
- Full integrated suite: **1,247 passed, six skipped, six failed**. The failures are the previously verified baseline admin audit-write(3) and scholarship/matching-order(3) expectations. After a final headline-copy refinement, the30 onboarding/intro/router tests passed again. Logs: build/entry-revamp-full-tests-final.log and build/entry-onboarding-final-tests.log.
- Changed-source/test analysis: no issues; CAPTCHA build configuration script passed. No IPA was built and no live/device sign-in is claimed.
- Web entry fixture build passed. Actual Chrome screenshots cover all five screens, login390/desktop,320x568 at200% text, and login with simulated240px keyboard inset; final capture logs contain no runtime/overflow errors. Keyboard-inset capture is scrolled to show form accessibility, not an actual native keyboard test.
- Five PNGs verified transparent with0alpha outer corners; no post-generation raster manipulation. Actual Geist remains supplied through the shared bundled theme.
- Independent static review found no introduced Critical/Important defect; the minor remember-me target finding was corrected. Git whitespace check passed.

## Existing routing and remaining limits

Completion/skip/login persist flags before navigation. The pre-existing redirect policy still sends signed-out splash launches to onboarding regardless of its completion flag; direct login links and signed-in/recovery destinations remain accessible. This pass did not change that policy and does not claim a once-only startup gate was fixed.

Browser previews use no Supabase session/backend and test data only. No physical iPhone/Safari/native CAPTCHA login verification; no commit, push or IPA. New images add approximately7.2MB of PNG assets before platform packaging. Current chat/QR/document behavior is unchanged; the companion workflow discussed with the user remains a later implementation.

## Follow-up: larger login mascots

User requested more mascot exposure. Login illustration is now128px tall/190px wide on standard screens,88px on short screens (from104/160 and76 respectively). Typography/auth behavior unchanged.13 login tests pass including narrow200% text/keyboard; preview build passed; browser captures show no runtime/overflow errors. Updated login390 evidence saved. Local interactive preview serves at127.0.0.1:5072; no production deployment or IPA.
