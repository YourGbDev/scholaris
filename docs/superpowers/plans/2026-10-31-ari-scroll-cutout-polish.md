# Ari Scroll and Cutout Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Work solo; no additional agents or five-worktree split. Steps use checkbox syntax for tracking.

**Goal:** Let students browse real tour content at full brightness, complete Discover without reading the full catalog, and see the full scholarship context before opening its details.

**Architecture:** Keep the existing real-screen guide, frozen scholarship and isolated demo hooks. Forward scroll activity from actual tab ancestors and local detail/review pages, distinguish user motion from programmatic alignment, and keep highlight geometry separate from the permitted action geometry.

**Tech Stack:** Existing Flutter/Riverpod controllers, ScrollNotifications, animation/gesture APIs and current production card/detail/review widgets. No new packages.

**Spec:** `docs/reports/2026-10-31-auth-tour-pre-defense-audit.md`, Workstream B and recommended decisions. This replaces the earlier full-Discover-feed rule; detail/review retain their meaningful review milestones.

## Global constraints

- Wait for explicit approval before execution. Use the same single isolated worktree as the auth lifecycle plan, sequentially editing shared Home files.
- Preserve Geist, soft-card tokens, correct gender/name, initial Skip/Continue and exterior tap-anywhere hints. Preserve profile-card guidance that worked well.
- No fabricated app screens, uploads, draft writes, real application submission or fake Tracker entries. Keep real page actions inaccessible except the current permitted guide action.
- User scrolling must never trigger an immediate scholarship opening or a surprise step change. Skip/Back remain available during browsing and alignment.
- No version bump, IPA build or external deployment in this code phase. Preserve unrelated workspace changes.

## Review focus

- A fling, wheel input or keyboard scroll versus a programmatic ensureVisible/animateTo/resize.
- Skip/Back/account change during a 350 ms debounce or in-flight alignment animation.
- Cards taller than the usable viewport at 320 px/200% text and short landscape height.
- Empty/short catalogs, no matches but a browse card, and delayed/changed listing results.
- Hidden scrim/note/cue must not leave invisible hit targets, semantics traps or access to real application actions.

### Task B1: Observe real scrolling and clear the browsing viewport

**Files:** `lib/features/home/presentation/home_screen.dart`, `widgets/student_app_tour.dart`, `widgets/student_application_guide.dart`; only touch `student_swipe_cue.dart` if cue presentation requires it. Tests: `test/student_application_guide_test.dart`, `test/student_tour_test.dart`, new focused scroll lifecycle tests if existing fixtures become unwieldy.

**Interfaces:** Keep existing scroll controllers and the dock's notification handler. Add a Home-owned `ValueNotifier<ScrollNotification?>` channel (or equivalently small callback bridge) forwarded through `StudentTourLayer` to the guide. Home's existing active-tab ancestor forwards only relevant vertical notifications without swallowing the dock's notifications. Detail/review notifications are observed in their own guide-owned subtree; do not expect sibling notification bubbling.

- [ ] Add failing interaction tests for drag start/update/end/fling and wheel input: scrim/note/cue fade out in 150 ms and restore only after 350 ms of settled scrolling. Reduced motion changes immediately. Test hidden hit targets and Skip/Back accessibility.
- [ ] Replace raw drag-delta jumpTo scrolling with forwarding to Flutter's real scroll position drag lifecycle where needed, preserving friction/fling and actual ScrollNotifications. Wheel/keyboard input needs an explicit user source; guard programmatic alignment separately. Keep underlying live page actions blocked.
- [ ] Add a small presentation state (idle, user browsing, programmatic positioning) with an owned debounce timer. Fade only presentation layers, not the real page or required scroll input. IgnorePointer/ExcludeSemantics hidden presentation layers; do not enable real page callbacks when opacity reaches zero.
- [ ] Cancel timers, drag handles and stale animation callbacks on step changes, Back, Skip, account teardown and disposal using the existing ticket/generation pattern. Ignore inactive-tab and nested-note scrolling. Never let the guide's text scrolling count as content progress.
- [ ] Run guide/tour and dock notification tests. Confirm real Home/Discover/Profile notifications reach the channel and that local detail/review notifications are not double-counted.

### Task B2: Comfortable Discover progression and full-card context

**Files:** `widgets/student_application_guide.dart`, `widgets/student_app_tour.dart`, `home_screen.dart`, `lib/features/scholarships/screens/discover_screen.dart`, `lib/shared/widgets/scholarship_card.dart`. Tests: `test/student_real_scroll_gate_test.dart`, guide and Discover/card widget tests.

**Interfaces:** Keep `ScholarshipCard.viewDetailsKey` as the action target. Add a separate `GlobalKey? cardGuideKey` to its whole-card wrapper, pass a separate `cardGuideKey` from Discover for the same first match/browse listing, and forward the pair through Home/TourLayer. Guide stores independent highlight and action rectangles; the full-card cutout does not authorize taps across the card.

- [ ] Replace the old end-of-feed test with a failing comfortable-distance test. Threshold is net user-driven progress `min(400 px, remaining extent at step entry)`; it unlocks only after genuine user input and settling. A short/non-scrollable feed has an explicit continue path. Time alone, programmatic movement, repeated up/down jiggles or resize do not satisfy it.
- [ ] Keep detail Back to top and review completion tied to their actual content/milestones. Do not weaken them to 400 px simply because Discover uses that threshold. Change explanatory copy to match the new Discover behavior.
- [ ] After threshold and idle debounce, restore a compact continue prompt. Require a tap to enter the next lesson; do not auto-advance or auto-open. User can keep browsing instead.
- [ ] Add the separate card target for first match and zero-match first browse cases. On entering Open one scholarship, programmatically align the real selected card within safe viewport bounds. Exclude this motion from progress/debounce logic and cancel safely if the user drags, presses Back/Skip or changes accounts.
- [ ] Measure full-card and button rectangles after layout. Spotlight the visible card using `kRadiusCard`, pulse/point specifically to View Details, and enable only its action rectangle (keyboard/semantics included). Freeze the matching scholarship before opening detail/review. No available listing gets an honest retry/skip state, never invented content.
- [ ] For an oversized card, keep its meaningful title/button in view where possible and use a clipped card cutout with a compact note outside the action area. Keep body text readable and retain the user's scroll position instead of repeatedly snapping them back.
- [ ] Run real Discover, scholarship-card, guide and narrow/enlarged-text regressions. Test interruptions, late data, zero matches and one frozen detail instance through simulated submission.

### Task B3: Verification and solo handoff

- [ ] Run auth lifecycle tests from the companion plan plus tour, real detail/review, Home/Discover, dock, profile, cards and Settings replay/Skip suites. Run targeted analysis and whitespace checks.
- [ ] Inspect 390×844, 320×568 at 200% text, short landscape, reduced motion and keyboard navigation. If browser access remains disabled, report it; do not substitute older captures for current evidence.
- [ ] On iPhone record slow browsing, fling/settle, comfortable Discover completion, full-card context, one real detail, demo review, Skip mid-scroll and replay. Ensure no upload/draft/application counts change due to practice.
- [ ] Update the handoff with actual test results and remaining native limitations. Leave new build/version/deployment to the separately approved release step, with CAPTCHA enabled.
