# Auth Lifecycle Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Work solo; the user explicitly declined five agents. Steps use checkbox syntax for tracking.

**Goal:** Reset student session UI correctly, remove inconsistent auth/readiness frames, and present the enabled CAPTCHA cleanly in light mode.

**Architecture:** Keep Supabase as the auth authority and GoRouter as the navigation owner. Derive routing from one current-user profile snapshot, isolate local UI/drafts at session boundaries, and treat dashboard loading independently from authorization. The CAPTCHA presentation protocol distinguishes initialization from verified token delivery without weakening existing guards.

**Tech Stack:** Existing Flutter, Riverpod, GoRouter, Supabase, webview_flutter and hosted challenge HTML. No new packages.

**Spec:** `docs/reports/2026-10-31-auth-tour-pre-defense-audit.md`, Workstream A and recommended decisions.

## Global constraints

- Audit/plan only until explicit approval. One isolated solo worktree shared with the Ari plan; no five-agent contracts.
- Geist Sans for app-owned text; existing shared soft-card tokens for content cards.
- CAPTCHA must remain enabled in every IPA; keep configured site key, HTTPS challenge URL, nonce/origin/path guards and server-side enforcement. Never log credentials or CAPTCHA tokens.
- Preserve student/provider/admin authorization, unconfirmed-email verification, password recovery, onboarding/setup resumption and legitimate deep links. No invented success navigation in Login.
- Preserve unrelated landing/readiness work and archives. No IPA/version bump/deployment in this plan's code phase; a release is a separate authorized step.

## Review focus

- Same account re-login and A → sign-out → B while delayed profile/count/mutation requests complete.
- Token refresh and user-updated events must not reset ordinary in-session navigation.
- Slow/erroring profile or summary data must not expose another user's state, default a role prematurely or deadlock login.
- CAPTCHA cancellation, slow SDK, challenge expiry, duplicate/late messages and app background/resume.
- Protected deep links and recovery must not be clobbered by a blanket Home redirect or stale tab microtask.

### Task A1: Pin the actual transition sequence and isolate local session UI

**Files:** `lib/features/auth/controllers/auth_controller.dart`, `lib/features/home/presentation/home_screen.dart`, `lib/features/applications/providers/application_draft_provider.dart`; investigate delayed mutations in `lib/features/bookmarks/providers/bookmarks_provider.dart` and `lib/features/applications/providers/applications_provider.dart`. Tests: `test/auth_boundary_test.dart`, new `test/auth_navigation_lifecycle_test.dart`, and application draft regression cases.

**Interfaces:** `currentUserIdProvider` remains the shared user identity. Keep `homeTabIndexProvider` and `selectTab(int)` callers compatible. Its build must depend on identity and reset to zero silently on a true boundary. Keep `applicationDraftProvider(scholarshipId)` callers compatible by observing session identity within its build, unless tests demonstrate a stronger session key is necessary.

- [ ] Add failing tests for Profile → sign-out → same-user login, A → B, and unchanged tab during token renewal. Capture rendered destinations and current tab, not just provider initialization.
- [ ] Add failing tests for A's essay/recommenders → logout → B opens the same scholarship; delayed bookmark/application completion after a switch must not publish old state into B's UI. Persistent user-keyed profile drafts/avatars must remain isolated without deleting unrelated preferences.
- [ ] Record a sanitized event timeline in a controllable router harness: boundary phase, profile/role readiness and actual route observer events. Distinguish route changes from visual transition overlap. Do not claim the native ping-pong reproduced unless the test/device trace demonstrates it.
- [ ] Implement identity-bound tab/draft reset and guard stale async state assignments using the captured identity/session generation. Do not cancel or pretend to roll back server writes already accepted; prevent their results from contaminating a new session.
- [ ] Run the new cases and `flutter test --no-pub test/auth_boundary_test.dart test/auth_navigation_lifecycle_test.dart`. Review changes before the next task; keep a focused commit when publication is authorized.

### Task A2: Consolidate routing readiness and Home's initial summary

**Files:** `lib/app/router.dart`, `lib/features/auth/presentation/login_screen.dart`, `lib/features/profile/providers/profile_setup_provider.dart` if needed, `lib/features/dashboard/presentation/student_dashboard_screen.dart`, `lib/features/scholarships/providers/dashboard_provider.dart`. Tests: auth navigation lifecycle/regression, onboarding/admin/provider router tests, dashboard provider/widget tests.

**Interfaces:** Preserve `authRedirectDecision` public arguments/callers unless extending with a clearly tested readiness state; preserve provider/admin/recovery priorities. `ProfileCompleteNotifier` derives setup completeness from `currentProfileProvider.future` rather than issuing a second independent fetch. Router refresh observes `authSessionProvider` instead of a second raw Supabase event stream. Login may observe shared readiness to keep its busy state, but never imperatively pushes Home on success.

- [ ] Write failing route-render tests with delayed/out-of-order profile, role and auth responses. Assert one authenticated landing, no Profile/Login intermediate frames, no duplicate successful route replacement, and no stale queued tab selection. Include same-account relogin and A → B.
- [ ] Write tests for summary inputs completing in every order. Saved/In Progress/Closing Soon must not display mixed live/fallback numbers. An unknown count renders a neutral placeholder; an actual complete zero snapshot renders zero.
- [ ] Implement shared profile/role readiness and central refresh. Keep Login busy after a successful token exchange until the router has resolved its destination; cancel/error must release busy state and provide a retry. Do not force Home for recovery, provider/admin or incomplete profiles.
- [ ] Replace mixed summary reads with one complete session-bound dashboard snapshot. Reject retained data from an old identity. Same-user refresh retention may remain if explicitly identity-safe; do not show false zeroes while loading. Prefetch summary if useful, but do not make unrelated catalog/bookmark failure block authorization indefinitely.
- [ ] Add explicit profile-loading error/retry behavior. A data error must not become an invented role, a false setup decision or a forced logout. Make a pending authenticated screen inert until authorization is known.
- [ ] Run auth/router/dashboard tests, then account-settings and student tab regressions. Inspect full auth path with reduced motion and normal transitions; changing fade durations alone is not an accepted race fix.

### Task A3: Native and hosted CAPTCHA presentation

**Files:** `lib/core/security/captcha_challenge.dart`, `captcha_view_native.dart`, `captcha_view_web.dart`, `captcha_mobile_protocol.dart`, `web/captcha_challenge.html`; extend `test/captcha_mobile_protocol_test.dart`, `test/captcha_gate_test.dart`, `tools/test_captcha_challenge_layout.mjs`; add a focused testable native presentation seam only if needed.

**Interfaces:** Preserve `acquireCaptcha(BuildContext) -> Future<CaptchaResult>` and existing token/error messages. Add a distinct nonce-bound initialization/ready message; it must never satisfy token authorization. A widget bootstrap signal is not human verification and is not by itself proof of native first paint.

- [ ] Add failing tests for forced light `turnstile.render` options/CSS, initialization messages, wrong nonce, token-before-ready, duplicate token, error/expiry, cancellation and late callbacks after disposal. Preserve invalid HTTPS/configuration and web origin/source protections.
- [ ] Set the native WebView's background before loading and give its initial host/placeholder the intended light appearance. Keep the WebView mounted beneath a nonblocking-to-load covering placeholder until initialization is reported. Preserve visible cancel/retry and accessible loading text; reduced motion uses a static placeholder.
- [ ] Set the HTML page/color scheme and Turnstile render option explicitly to light. Do not rely on an unread query parameter. Extend both native and web bridge consumers for initialization without exposing a token or weakening checks.
- [ ] Separate SDK/page loading timeout from time spent completing a visible human challenge. Accept only the first valid terminal outcome, immediately exchange successful tokens, and reacquire after cancellation/expiry/failure; never cache/reuse a token for retry. Reject callbacks from a previous request/session.
- [ ] Run `node tools/test_captcha_challenge_layout.mjs`, `node tools/test_ios_captcha_build_config.mjs`, and CAPTCHA tests. Check normal/compact widths, errors and cancellation with light/dark system appearance.
- [ ] Document that the actual hosted HTTPS challenge asset must be deployed and its served version checked before shipping an IPA. Do not deploy during the approval-only/code phase without release authorization. Device first-frame flash and successful CAPTCHA login remain pending until actually tested.

### Final verification / handoff

- [ ] Run targeted analysis and affected auth, account, dashboard, CAPTCHA, tour and role-routing suites. Run the full suite before a release and report any existing admin audit-log failures separately.
- [ ] On iPhone verify repeated login/logout, slow network, Cancel/retry and background/resume; record the route/visual sequence without private data.
- [ ] Summarize actual changes, checks and pending native/hosted verification. No completion claim based only on a successful CI build. Execute the companion Ari plan in the same solo worktree after auth ownership is stable.
