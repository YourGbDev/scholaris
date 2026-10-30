# Build 15 device feedback: local follow-up

Implemented on top of `e657672`; changes remain uncommitted. No push, version bump, IPA build, or replacement of Build 15.

## Changes

- Reduced normal Home hero height through smaller spacing/type: 22px heading, 13px summary, 24/20px vertical content padding and 18px cap clearance. Both portraits retain their shared layout, female .94 scale and button clearance.
- Replaced Home and Discover header avatars with Settings buttons opening the existing AccountSettingsScreen; Profile remains in the dock.
- Grouped deadline and Applied metadata so Applied no longer wraps independently; retained wrapping for narrow/large-text layouts and the full bookmark touch target.
- Removed Discover's redundant targeted-opportunities subtitle and Active profile criteria bar. Search, filter chips/removable selections, Matched for you and sorting remain.
- Collapsed selected navbar icon and its transition retain the same selected green outline. Glass styling is unchanged.
- Replaced the navigation spotlight tour with a six-step, optional demonstration: View Details, criteria, Start Application, Application Packet/upload location, final review/submit, and temporary sample Tracker. Only Next/Back/Skip/Finish are interactive; sample upload/submit controls are labelled illustrations. No dummy documents, forms, or confirmations are required.
- Completing or skipping unmounts all sample content; no application/upload APIs are available to the demo. Per-account dismissal/completion and Settings replay remain. Existing v1 opt-outs are respected.

## Verification

- 180 focused tests passed in the final run, including actual Geist badge-layout geometry, Settings navigation, collapsed color, guide progression/back/replay/reset, account changes, narrow/200% text, scholarship counts/search/filtering, navbar, application Tracker and account settings.
- Analysis across 12 affected implementation/test files: no issues. Diff whitespace check clean.
- Independent read-only review found the guide initially used an imprecise upload location; corrected it against production code to `Start Application` → `Review & Submit` → `Application Packet` → `Upload supporting document`.
- Fresh 390x844 browser inspection verified compact male Home, Settings icon, Discover removal/badges and green collapsed navigation. Saved images: `home-390x844.jpg`, `collapsed-nav-green.jpg`.
- Browser access was subsequently disabled in Work settings. Final guide screenshots and a fresh female preview were therefore not captured. Both gender paths and guide semantics/layout are covered by automated checks; physical iPhone verification of these new changes remains pending.

Unrelated landing and existing readiness-review modifications are preserved.

## Follow-up: compact actions and grouped header

- Shared `StudentHeaderActions` groups Notifications and Settings in a rounded white pill on Home and Discover. Both use green 24px icons and minimum 44px touch targets. Profile remains in the dock. The previous unconditional notification dot is removed rather than implying unread notifications without checking state.
- Quick actions use a 240px maximum width at normal text size (288px for enlarged text), two concise action labels, simple green icons, and no repeated descriptions. QR and upload routing, close/outside dismissal, and enlarged-text scrolling remain.
- Stat tiles retain readable text/count sizes with vertical padding reduced from 16px to 12px. The application banner uses 12px vertical padding and the submitted subtitle “Track your application.” Other application-state messages remain.
- 57 affected checks passed after these changes; targeted analysis of six files and diff checks are clean. Normal menu geometry test loads the actual Geist fonts. Browser access remained disabled, so no current screenshots of the grouped header/compact menu are claimed.

## Follow-up: contextual guide and compact Discover (approved October 31)

- Replaced the standalone panels with measured spotlights and pointed speech bubbles. Home Saved/In Progress and the Discover dock item are actual anchors. Underlying production actions remain blocked throughout the guide.
- Ten short stops cover the nine approved narrative sections: Saved, In Progress, Discover, sample View Details, eligibility after scrolling, Start Application, confirmation explanations, demo submission, View Tracker, temporary Tracker. The sample screens exist only inside the guide and have no application, upload, file-picker, or bookmark service imports.
- Finite pulses and an upward swipe cue accompany the automatic sample scrolling; reduced motion uses immediate scrolling and static highlights. The Discover scrolling check uses real Geist font metrics at 390×844.
- Back, Escape/Skip, Finish, per-account dismissal and Settings replay remain. Finish and Skip remove samples and return to Home with the dock expanded. Discover filter state is never mutated.
- Independent read-only review identified stale anchor bounds on resize, action occlusion in short viewports, and inaccessible demo caveats. Fixed with observation of naturally scheduled layout frames, an action inside the instruction bubble when space is insufficient, and accessible status/caveat text. Regression coverage includes resize, landscape, missing anchors, 320 px/200% text, and blocking the real stat callback.
- Discover now uses one 16 px gap after the filter area and 12 px after “Matched for you.” Removed its standalone Soonest Deadline/Highest Amount popup. Deadline filtering, the existing Filters sheet (including its sort options), result order and matching remain.

### Fresh verification

- 151 focused tests passed across guide/tour, dashboard, Discover, quick actions, dock/navigation, Settings, scholarship cards and applications. After the final cue visibility refinement, all 10 guide/tour checks passed again. Targeted analysis is clean (eight files, followed by the final two changed files).
- Full-suite run: 1,214 passed, nine skipped, four failed. All four failures are in untouched `test/admin_users_tab_test.dart`: creates a new user account, edits role/status, deactivates a user, and deletes a user, each expecting audit-event logging. The suite is not globally green. The last full run preceded the final small scroll/cue refinement; focused checks cover that refinement.
- Changed-source whitespace checks pass. Repository-wide whitespace checking also reports pre-existing Markdown hard-break trailing spaces in the unrelated readiness report; left intact.
- Browser access recovered after refreshing the browser-control session. Checked the existing port 5047 process before restarting that same preview target to compile current source. Captures are in `contextual-guide/`, all full views at a 390×844 browser viewport. Verified both gender illustrations by sight. Confirmed the full demo path, final receipt, Tracker, Finish removal with unchanged visible Home counts, replay, Skip, and compact Discover. No physical iPhone or assistive-technology device run is claimed.
- No commit, push, version change, dependency installation or IPA build. HEAD remains `e657672`; all prior unrelated local work is preserved.

## Ari-led journey, Chat, and mandatory Geist Sans follow-up

- New optional welcome uses the student's first name and a clipped, half-body portrait peeking from the left edge. Profile gender selects the male/female portrait, including Discover greeting and practice-submission celebration. Existing first-use opt-outs and per-account Settings replay remain.
- Explanatory stops use “Tap anywhere to continue”; only the initial welcome has Continue. Action stops still require the indicated button. Home Saved/In Progress are retained; recommendation and first View Details anchors now point at the actual Home components.
- The extended sequence covers Home recommendations and example detail, return to Home, Discover greeting, two example matches, broader catalog, detail eligibility/requirements, review packet/confirmations, simulated submission, celebration, Tracker, real Profile academic/location/financial sections, and plus-menu shortcuts. DOST/CHED-shaped examples reuse production ScholarshipCard presentation; the first Home scholarship's title is retained when available. Samples never enter real data providers.
- A right-side finger cue accompanies manual drag/wheel/keyboard scrolling. Explanatory scroll stops require seeing their section. Large wheel jumps record the crossed region; if an earlier swipe passed the next section it is repositioned ahead of the student. Screen-reader section scrolling has an equivalent semantic action; keyboard End locates the section. Reduced motion is supported.
- Read-only review found Enter/Space interception, duplicate keys under rapid Back transitions, and unseen-section unlocking at the bottom. Regression tests reproduce each; fixes preserve standard button activation, allocate unique page keys/controllers per transition, and count actual movement with section visibility. Back/Skip/account teardown still remove temporary content.
- Chat is the first plus-menu item. Its screen has a profile greeting and matching mascot, help, editable composer, and disabled send with explicit “AI replies are not connected yet.” No AI API, message transmission, microphone, payment, or simulated assistant answers were added. QR scan/document-upload routing remains real outside the guide.
- Typography audit replaced 13 explicit GoogleFonts overrides across admin/provider/receipt text with bundled `geist()`, changed both tracked preview themes to Geist, and corrected the ignored local preview's Poppins label. All explicit app UI font-family declarations now use `Geist`, and no GoogleFonts calls remain under `lib/`. Native keyboard/pickers and fallback glyphs are OS/font owned. An offline reference-pill regression test proved the prior RobotoMono override and now passes.

### Verification status for this follow-up

- Browser access initially worked at 390×844: visually confirmed male welcome portrait/crop, personalized greeting, Saved tap-anywhere note, and actual Home scroll gating. Captures saved under `ari-journey/`. Browser then explicitly reported “Local browser use is disabled in Work settings.” No alternate capture method or older screenshots are claimed as evidence for this final revision. Fresh female welcome, Chat, full extended path, and final cue refinements still need browser/device visual verification.
- 132 combined focused tests passed, including the extended path with actual Geist metrics, male/female welcome/chat selection, manual scrolling and unseen-section gating, 320 px/200% text, landscape/resize, keyboard target activation, rapid Back, account teardown/replay, real stat/card callback blocking, Chat, Home, Discover, Profile, cards and navigation. Analysis across all 34 changed/new Dart files reports no issues. The design detector returns `[]`; changed app/test whitespace checks pass.
- Final full suite: **1,223 passed, nine skipped, four failed** (`ari-full-suite-final.log`). The four failures are the previously observed admin audit-event assertions for creating, changing role/status, deactivating and deleting users in `admin_users_tab_test.dart`; no tour/chat/typography/student test failures remain. The suite is not globally green. The earlier intermediate full run's two journey failures are corrected.
- Still uncommitted, no push/version bump/IPA. Landing, readiness report, assets and IPA archives preserved.

## Waving male welcome and side-swipe follow-up

- User requested one new male welcome pose. Generated a transparent waist-up, smiling/waving version from the existing male portrait using the built-in ImageGen tool; saved non-destructively to `assets/images/mascot_male_welcome_wave.png` and registered it in `pubspec.yaml`. Male welcome/Discover greetings use it; the female asset path and celebration remain gender specific.
- Welcome has Skip and Continue inside the speech note. Its top Skip guide control is absent until after the introduction. At enlarged text the two actions wrap rather than overflow.
- The local male/unset regression preview now uses the fictional name Gb; female remains Maria Santos. Production student names/gender remain profile driven.
- Replaced the small stock hand icon with `StudentSwipeCue`, a shaded, rounded one-finger hand with green cuff and upward trail at the right edge. It performs two upward demonstration sweeps; reduced motion keeps a static cue. Existing real drag/wheel scrolling and gating remain.
- Verification: 21 guide/tour/chat/quick-action tests pass; targeted analysis of six files clean; changed-file whitespace checks pass. Verified upward hand movement and static reduced-motion behavior in a widget test. Browser retry still reports local browser use disabled in Work settings, so no current app screenshot of these refinements is claimed. Preview hot restart requested; no IPA/version/commit/push.
- Image prompt (built-in edit): preserve the existing Filipino male character, short swept black hair, warm skin, green graduation cap and gold tassel, green gown/gold trim, white collar/tie, clean 2D rendering; make a waist-up three-quarter portrait smiling warmly and waving an open hand beside his head, fully inside transparent margins; one character, no text/logos/background/effects. Original reference and generated original preserved.

## Real-screen tour correction — latest local implementation

This section supersedes the earlier example-page journey described above.

- Tour notes use 28 px phone margins (334 px width at 390), 18 px padding, 20 px headings and 15 px body text at 1.45 line height in Geist. The high-contrast tap instruction is outside the white note. Initial welcome retains in-card Skip and Continue; later mascot greetings advance from the copy, portrait or background, while drag gestures remain independent.
- Home now waits for a resolved student profile before greeting, including queued replay. This prevents the pending female profile from briefly receiving the male/default greeting. Account changes clear queued replay.
- Removed the separate fabricated guide-page implementation. Home, Discover, Tracker and Profile stay on their actual retained app screens. The guide opens one real ScholarshipDetailScreen, followed by the actual SubmitApplicationReviewDialog, using optional isolated presentation hooks.
- Discover uses its actual scroll controller and a real end-of-feed target. Both the end target and current bottom scroll metrics must be reached; elapsed time and short swipe distances cannot unlock the next step. No timed advancement occurs. The first actual match, or first actual catalog card when there are no matches, is highlighted only after browsing. The selected scholarship is retained through review.
- The detail tour waits for its actual Back to top area and bottom metrics. Back to top returns through the real detail scroll controller before introducing Start Application. Duplicate taps and stale animation callbacks cannot skip stages. Production content is excluded from keyboard focus during the overlay; demo callbacks also enforce the current stage.
- The real review packet, confirmations and signature layout are preserved. Demo confirmations are prechecked and noninteractive. Upload, save-draft and real submission actions are blocked; the final tour action only advances to celebration. Actual Tracker is shown without inserting a fabricated application.
- Latest integrated verification: 69 affected tests passed across guide, tour, real detail/review, Home, Discover, chat, quick actions, save/draft regressions and Geist. Tests cover partial versus end scrolling, the actual zero-match catalog target, one detail through review, duplicate Back to top taps, blocked early callbacks, exterior instruction placement and 320 px/200% text. Targeted analysis of ten implementation/test files is clean; scoped whitespace checks pass. The full suite was not rerun for this correction; earlier unrelated admin audit-log failures remain documented above.
- Existing port 5047 preview was checked and hot-restarted, without starting another server. Fresh browser verification remains unavailable: the retry returned `Local browser use is disabled in Work settings`. No older screenshot or generated image is presented as a fresh app capture.
- HEAD remains e657672. No commit, push, version change or IPA build. Unrelated landing, reports, assets and archives were preserved.

## Shared soft card surfaces — approved follow-up

- Consolidated the scholarship card's visual surface in app_theme.dart: kRadiusCard is 26 px, kCardBorderCrisp is a faint 0.5 px neutral outline, kCardElevationCrisp uses a 16 px soft blur with a 4 px downward offset, and kSoftCardDecoration combines them.
- Reused the decoration across the main student Home/Discover, Tracker/application detail, Profile, Settings, scholarship detail, application review/receipt and empty-state cards. Matching Material/InkWell/clip outlines use the card radius. Status-specific border colors remain meaningful. The shared Material Card theme and admin/provider card tokens also use the common shape/elevation values. Buttons, fields, badges, icon containers, nested rows, navigation glass and the mascot artwork retain their own geometry.
- Tracker cards now have 20 px padding like scholarship program cards. An existing 360 px populated Tracker test caught a 4.5 px overflow in the timeline footer after the padding increase. Its status/date row now wraps naturally rather than forcing both into one line; that regression and the combined affected suite pass.
- Added the shared card rule to AGENTS.md. Geist typography, CAPTCHA and application behavior remain unchanged.
- Verification: 156 affected tests passed; targeted analysis of all 15 changed Dart files clean; scoped whitespace checks clean. The mechanical design detector returned no findings. No whole-suite or physical-device run is claimed for this refinement.
- Browser retry still reports local browser use disabled in Work settings; no fresh screenshots are claimed. Changes are prepared for the same IPA handoff branch with no local IPA build or version bump. Unrelated landing work, readiness reports and archives remain untouched.
