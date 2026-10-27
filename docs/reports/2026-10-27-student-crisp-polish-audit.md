# Student app crispness audit

## Scope and evidence

Reviewed the user's iPhone screenshots and Tarsi reference, saved student captures, and current Flutter source for Home, Discover, Tracker, Profile, shared scholarship cards, the navigation dock, and representative secondary states. Some captures predate the current 1.0.0+8 source; they are not proof of current device rendering. No iPhone, live backend, frame-rate, screen-reader, or full accessibility audit was performed. The Tarsi reference is a still image, so its precise rendering and motion cannot be inferred.

## Priority findings

1. **Profile demo content.** `profile_tab_screen.dart` constructs a student ID from a name hash and year and displays an unconditional “UP CRS SSO Verified” badge. The user indicated these are placeholders; preserve them during this polish pass and connect them to verified data before presenting the app as live.
2. **Empty Tracker demo content.** `applications_screen.dart` contains a fixed scholarship example, a fallback count and an 83% funding statistic. Treat these as demo placeholders during this pass; confirm the data and copy before presenting them as live.
3. **Responsive Tracker.** At 320 logical pixels and 1.4x text scaling, the empty state and loading skeleton produced multiple overflow errors. This pass adds wrapping and scrolling and a regression test. Test on actual phones and with additional text sizes remains pending.
4. **Scholarship card hierarchy.** The shared card already has softer sage and neutral treatments in current source; older purple-heavy screenshots are not a current baseline. Its fit, deadline, provider, award, eligibility, requirements, and action rows remain dense. Review on-device with real long titles and data before adjusting shared hierarchy. Preserve meaningful status and both actions.
5. **Home composition.** The illustration and greeting give Scholaris a distinctive welcoming character. Review alignment and vertical rhythm among hero, status, statistics, alert, heading, and list; make lower-priority labels quieter without weakening urgent alerts.
6. **Discover.** Search, filters, active-profile context, sort and cards crowd the first viewport. Check their grouping and labels on a real phone; preserve filter state, and verify clear/search and empty results interactions.
7. **Tracker.** Summary, status filters, cards and empty states need consistent type and spacing; verify long statuses and empty/error/loading states. The skeleton previously exceeded short viewports.
8. **Profile.** Several supporting labels use 10–11 logical pixels and some values are truncated. Review legibility, text scaling, and long school/course names; avoid blanket size increases without testing wrapping.
9. **Navigation and motion.** Glass contrast depends on underlying content, and captured previews do not establish iPhone shader behavior. Check expanded and collapsed states over light and busy content, rapid switches, reduced motion, and frames on-device. Keep controls readable, centered, and immediately responsive.
10. **Secondary paths.** Audit filter and notification sheets, scholarship detail, `+` actions, keyboard and scroll insets, focus, touch targets, and loading/error/recovery states against actual usage. Current evidence is insufficient to rate these comprehensively.

## Follow-up: Profile and populated Tracker

- Profile's credentials heading could overflow at 320 logical pixels with larger text. Its status now wraps, the page subtitle can use two lines, and academic grid subtitles use a more legible size and can wrap. A focused narrow-screen widget test passes; actual device review is pending.
- A focused widget test at 320 logical pixels with 1.3x text scaling reproduced overflow in the **populated** Tracker. The compact layout now scrolls its summary and lazily built cards as one page, and the amount, status and metadata can wrap. The regression test also checks an empty filter; actual device review and very long lists remain pending.
- The existing `application_detail_screen_test.dart` test “the withdrawn filter surfaces withdrawn applications” fails when the test taps a filter that does not receive pointer events, even after an isolated retry. Its cause is not established; do not classify that flow as verified until investigated.

## Suggested sequence

First resolve misleading identity and recommendation content with actual data contracts. Then review shared cards and type hierarchy on Home and Discover, followed by Tracker and Profile. Finally compare glass, motion, scrolling and accessibility on the target iPhone and check secondary paths and long-content states. Preserve the user's chosen colors, illustration, navbar and interaction design while refining consistency.

## Completed local browser polish pass — 2026-10-27

The follow-up sequence above is superseded for this pass by the user's explicit instruction to preserve demo placeholders. No demo identity, verification, recommendation, funding, or statistical copy was replaced. No IPA was built or deployed. Unrelated provider/admin/auth/landing changes were preserved; no commit, reset, or bulk formatting was performed.

### Changes in this continuation

- Discover: the results heading and complete summary use their own line on narrow or enlarged-text layouts; the sort control moves underneath. Sort and criteria Edit have at least 44 logical pixels of height, and Edit also has at least 44 logical pixels of width.
- Home and Discover: the existing brand mark can fit into the available header space without pushing notification/avatar controls offscreen under enlarged text.
- Shared cards: deadline labels can wrap. At widths below 350 logical pixels or enlarged text above the compact threshold, award amount, frequency and benefit stack/wrap instead of compressing the amount to an unreadable size. Normal-width, normal-text presentation is preserved.
- Quick actions: the existing spring sheet now has a Material surface, fixing inherited underline styling observed in the browser. Its content scrolls on short enlarged-text phones. Its close button has an accessible name. The original actions and spring motion are preserved.
- Notifications: long titles wrap and status badges move to the next line when needed.
- Withdrawn-filter regression: root cause was test timing. The first timed pump after activating Tracker started the entrance ticker rather than completing it. An initial frame now starts the ticker before advancing time. App filtering and entrance animations were not changed.
- Navigation regression: replaced the obsolete IndexedStack-specific assertion with checks that each destination becomes active immediately, other pages are offstage, and all four page Elements remain identical across switches.
- Added `lib/dev/student_regression_preview/main.dart`: explicit local-only target using fictional in-memory repositories. Supports width/height/text scale/tab and populated/empty/loading/error states, plus reduced motion via `motion=off`. Empty state supplies both empty applications and empty scholarship feeds. No Supabase initialization or real record writes.

### Visual evidence and coverage

Used this session's in-app browser with the actual Flutter student screens and theme in the local fixture on port 5033. This is browser preview evidence, not physical iPhone evidence. Representative logical layouts were 360×800 and 440×956 at normal text and 320×640 at 1.4× text; the short quick-action regression also used 320×568 at 1.4× in widget tests.

| Surface | Browser observations | Automated/source checks |
| --- | --- | --- |
| Home | Greeting/hero, status, statistics, recommended cards, glass dock, navigation to Saved; normal and enlarged text | Dashboard widget checks; retained navigation and card regressions |
| Discover | Search/filter controls, normal and enlarged-text feed, full summary, cards, filter sheet | Search/clear, sorting, filter chips/reset, empty results, narrow touch targets and overflow |
| Tracker | Populated list at 360 and 440, empty and loading at narrow enlarged text; application detail entry | Loading/empty/error, compact populated list, filter state, withdrawn selection, tab replay and scroll retention |
| Profile | Long institution/course at 360; lower academic/financial sections by scrolling; error recovery at narrow enlarged text | Existing narrow profile/credential checks and error/empty paths |
| Saved | Empty suggestions and populated bookmark feedback at 320 and 1.4× text; scrolling | Saved search/filter/remove and card regressions |
| Details | Scholarship detail and submitted receipt, application status/notes/withdrawal surface at 440 | Application detail, notes, withdrawal and document tests |
| Sheets | Filter sheet; notifications at 320 and 1.4×; quick actions before/after fix; document type/file/upload controls reachable by scrolling | Long notifications, quick-action Material/overflow/scroll test, navbar sheet launch/dismiss checks |
| Dock/motion | Glass over card content, enlarged-text two-row layout, tab switches and scrolling | Reduced motion, high contrast, keyboard avoidance/traversal, selection motion/reversal, collapse/expand, inactive-tab scroll isolation and sheet focus locks |

Saved final screenshots are in `docs/reports/student-crisp-polish-2026-10-27/`. The frozen Tracker loading and Profile error fixtures intentionally remain in those states; retrying them does not simulate a successful backend recovery.

### Verification results

- Core student pass: **164 tests passed**, including application detail, Tracker, Profile, cards, discovery/search/filters, Saved, notifications, retained navigation, navbar accessibility, glass refraction and indicator motion.
- Dock/sheet follow-up: **34 tests passed** across the new quick-action check, navbar accessibility and scroll-dock suites.
- Final affected-surface pass: **55 tests passed** across cards, discovery search, Saved, notifications and quick actions. These suite counts overlap and must not be summed as unique coverage.
- Dashboard/document follow-up also passed (44-test combined run with discovery before the final card adjustment).
- Final card-only rerun: **21 tests passed**, including the full-width compact award tile.
- Scoped Flutter analysis of this continuation's 12 source/test targets: **No issues found**. Earlier scoped analysis also covered the carried-forward Tracker and Profile edits with no issues.
- Initial failures were reproduced and resolved: withdrawn-filter test timing; obsolete IndexedStack assertion; narrow Discover/header/deadline overflow; quick-action underline/bottom overflow; single-line notification truncation; unreadably scaled award amount.
- Independent code review found and resolved one fixture issue (empty state retained scholarship rows), then found no further actionable regressions in the scoped additions.

Test outputs are retained in `student-polish-test-output.txt`, `student-polish-secondary-test-output.txt`, and `student-polish-final-test-output.txt` alongside this report. They are scoped test output, not a claim that the entire unrelated working tree passes.

### Remaining verification limits

- No physical iPhone, native compositor/shader, real haptics, device frame-rate, VoiceOver, camera scanning, or real software-keyboard verification. Dock keyboard insets and reduced-motion behavior were checked through widget tests; browser desktop typing is not iPhone keyboard verification.
- No real application, document upload, account/profile change, financial operation, or backend recovery was submitted. The local fixture's attachment and safety-report sections show their unavailable/error paths where no backend is provided. Their successful live-data paths remain unverified.
- During development hot restarts the browser logged a disposed EngineFlutterView scheduler assertion. It was associated with rebuilding/reloading the debug preview, not reproduced as an ordinary tab-switch failure. This is not evidence of production iPhone behavior.
- Long titles/providers still use the existing card truncation policy, with full scholarship details reachable. Preserved demo suggestions and claims remain demo content.

The local browser/widget polish pass is complete within these limits. Physical iPhone and authenticated live-service acceptance remain separate follow-up verification.
