# Student welcome, onboarding and login revamp

User approved implementation of the discussed five-screen introduction and compact Tarsi-inspired visual principles; explicitly requested NEW mascot poses. Preserve Scholaris identity and all authentication/security behavior.

## Design and files

- Parent: lib/features/onboarding/presentation/onboarding_screen.dart, lib/features/intro/presentation/intro_screen.dart, onboarding/intro tests, pubspec asset registration, local-only entry preview and report.
- Delegate login file/tests independently. No role/student-inside/landing restyles during this task.
- Five-screen first-launch introduction: Welcome, Discover, Match, Track, Companion. Existing entry gate points to /onboarding, so welcome must be included in that flow, not only a separate unused /intro route. Preserve first-launch flags and direct login/recovery access. Avoid changing auth redirect policy.
- White/neutral canvas, compact Geist700 headlines24, prose14 regular, controls13/600 with44+targets. One illustration/message per screen; meaningful Back/Next/Skip progression, returning-user login access. Page content scrolls at narrow/short/large text; no shrinking/cropping text. Shared26px treatment only for actual full content cards.
- New transparent mascot poses derived from canonical refs: paired welcome, Ari discovering documents, Ariel matching profile, Ariel tracking checklist, Ari conversational phone pose. Preserve appearance and leave originals. Generating via imagegen skill; copy final assets into assets/mascots/onboarding. No new generated UI/lettering.
- Companion slide frames AI/merged QR/document actions as planned, with concise Coming soon disclosure while current functionality remains unchanged. No false eligibility or AI behavior implementation.
- Login: small welcoming illustration, clear email/password form, forget/reset andrememberme, single sign-in CTA, signup/provider secondary links. Remove inert decorative controls and unavailable third-party sign-in panels. No auth/CAPTCHA/controller changes.

## Checks

Update existing composition tests for five-screen flow; preserve skip/finish/persistence/direct login tests and cover short phone/200% text. Preserve login validation, CAPTCHA, lockout, session/recovery and remember-me tests. Analyze changed sources, build isolated entry preview, inspect real screenshots320/390/desktop/large text/keyboard. Independent review. No commit/push/IPA. Prior six baseline failures documented; don't change unrelated tests/business logic.
