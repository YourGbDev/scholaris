# Ari student journey refinement

User authorized this refinement through the detailed Tarsi walkthrough, Chat references, mandatory Geist Sans requirement, and gender-matched companion instruction. Implement inline; preserve prior local work, no commits/push/version/IPA.

## Design and interfaces

- Optional personalized, half-body peeking mascot welcome with Skip/Continue. Male/female selected by profile gender using existing assets. Replay begins with this greeting too. Mascot returns at Discover and demo celebration only.
- Explanations advance by tapping anywhere; highlighted actions require the named target. Back/Skip remain, keyboard and screen readers have equivalent actions. No Continue buttons except welcome; no auto-advancing steps.
- Home: Saved, In Progress, scroll to real Recommended section, highlight its real View Details, show temporary detail anatomy, slide back to Home, highlight Discover.
- Discover: greeting, two illustrative matches using production ScholarshipCard, a broader catalog example, scroll back to View Details, requirements/eligibility, Start Application, review packet/confirmations, final demo submission, celebration, Tracker.
- Then point to Profile and scroll its real academic/location/financial sections, then Plus and explain Chat/QR/upload. Guide cannot edit profile, bookmark, upload, or submit. All temporary samples disappear on Finish/Skip/account change.
- User scrolling is real: overlay forwards vertical drag/wheel/keyboard scrolling to the current view. A right-side one-finger cue points upward; explanatory scroll stops require seeing the relevant section before advancing. Reduced motion remains supported.
- New Chat action first in compact menu; familiar greeting/composer/help, honest AI-not-connected state. No network, generated replies, payment flow, or claim that messages were sent. Both mascot variants covered.
- Geist Sans is mandatory for all app-owned visible text, via family `Geist`. Separate audit fixes direct overrides across existing app; native keyboard/OS-owned dialogs are outside app font control.

## Tasks and verification

- [x] RED: update journey tests for welcome, tap-anywhere, required scrolling, full highlighted-action path, no service writes, gender variants, Back/Skip/replay/account teardown, 320 px/200% text and resize.
- [x] Wire optional Home recommendation/card and Profile section anchors/scroll controllers. Keep their normal callbacks unchanged.
- [x] Replace guide progression, greeting and sample surfaces; reuse production card presentation and preserve measured spotlight/collision fallback.
- [x] Parallel isolated Chat and typography tasks; review their edits and run combined focused tests/analysis.
- [ ] Fresh browser 390×844 inspection/captures of both mascots, key tour stages, scrolling, menu and chat. Independent read-only review; full suite and report actual failures, including existing admin audit-log failures.

No change to real application eligibility, submission, profile edits, search/filter semantics, hero, glass dock, or unrelated landing/archive work.

Progress: 132 focused tests pass; combined analysis of 34 Dart files clean. Independent review findings on keyboard activation, transition keys and unseen-scroll readiness corrected with regression tests. Browser verified male peeking welcome, Saved tap-anywhere and manual Home scrolling before local browser use was disabled in Work settings. Final female/chat/full-tour browser verification remains pending. Final full suite: 1223 passed, nine skipped, four known admin audit-event assertion failures. No student/tour/chat/typography failures. No commits or builds.

Implementation complete; visual verification is PARTIAL because Work settings disabled local browser use. Remaining visual checks are explicitly recorded in implementation.md, not represented by older screenshots. All three independent review findings addressed.
