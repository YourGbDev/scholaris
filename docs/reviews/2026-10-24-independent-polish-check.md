# Independent check of Archi UI polish — October 24, 2026

## Decision

UI green signal withheld. Improvements are visible, but the browser-focus fix claim is contradicted by a fresh actual-browser reproduction. No backend wiring prompt issued pending correction/reverification. This is a read-only product review; only this evidence document and scratch verification outputs were created.

## Findings

1. **P1: browser focus assertion still occurs.** Current local admin preview, 1280×800, accessibility enabled: entered Provider approvals, pressed Tab, opened organization review, resized to 360×800 and pressed Tab. Browser console contains two `WidgetsBindingObserver.didChangeViewFocus` assertions with `RenderBox was not laid out: RenderSemanticsAnnotations`, at 2026-10-23T21:15:08.011Z and 21:15:34.310Z (October 24 Manila). Exact logs: `scratch/codex-polish-browser-errors.json`. Dialog remains visible/usable, but the assertion is not resolved. Transition/layout root cause is not established by this review; do not assume `StackFit.expand`/outgoing TickerMode fixes it.
2. **P2: duplicate sidebar button semantics.** `lib/features/admin/presentation/admin_home_screen.dart:376` wraps TextButton with `Semantics(container:true,button:true)`. Fresh browser tree shows nested `button Overview > button Overview`, and the same for Provider approvals, Reports & safety and other destinations. Expose one meaningful accessible control per destination; preserve selected state. Browser tree proves duplication; screen-reader audio impact was not tested.
3. **P2: browser verification overclaims.** `scratch/verify_admin_and_provider_browser.mjs` captures after a fixed 3.5 seconds without confirming Flutter readiness. Independently inspected desktop/narrow admin and desktop provider captures show loading screens; the admin 200%-text capture does show rendered enlarged content. Script never opens a dialog or switches destinations, and provider loop only tests default organization, not `?type=individual`. It collects console calls but not `Runtime.exceptionThrown` and returns success unless an overflow is detected, even when assertion/error counts are nonzero. Current clean-browser/full-resolution statement must be replaced with actual coverage and limits.
4. **P2: stale full-suite evidence.** `scratch/admin-ui-suite-verified.txt` still has October 24 04:33 timestamp, earlier than the 05:02–05:03 polish browser evidence; it is the preceding Codex run. It cannot substantiate a post-polish full-suite run. A fresh independent run is being recorded separately.
5. **Minor: contradictory financial heading.** `lib/features/admin/presentation/admin_scholarships_tab.dart:381` still says `Total Committed Capital`, while the same metric now says Listed Value and sums stated scholarship amounts. Use a consistent listed-value heading; it does not establish commitments.

## Independent verification

- Focused admin/motion/viewport/preview regression run: **42 passed**, exit 0 (`scratch/codex-polish-independent-tests.txt`).
- Eight changed production UI files analyzed: **No issues found**, exit 0 (`scratch/codex-polish-independent-analysis.txt`).
- Fresh full offline run: **963 passed / 9 skipped / zero failures**, exit 0 (`scratch/codex-polish-independent-full-suite.txt`). Passing widget tests do not override the actual browser assertions.
- Actual desktop Overview inspected: stronger actions and clearer status treatment, green identity retained. Provider queue/navigation keyboard sample and organization review at desktop/narrow mobile inspected. No comprehensive provider or full-admin-browser sign-off; no production/live backend evidence.
- Screenshot: `scratch/codex-polish-review-mobile.png`.

## Skills applied

Superpowers using-superpowers, requesting-code-review with separate read-only reviewer, and verification-before-completion. Apple Design read/applied for responsive feedback and restrained interruptible motion. Apple HIG references inspected: accessibility/Vision (larger text and perceivable interactions), layout/Visual hierarchy, typography/Ensuring legibility, color, designing-for-macos, sidebars, buttons/Style and cross-platform Flutter translation. Review prioritizes accessible controls and runtime correctness over decorative finishing.

## Next step for Archi

Correct the focus lifecycle fault, merge sidebar semantics to a single control, align the listed-value heading, and replace browser verification with readiness-aware real interactions. Inspect org and individual previews explicitly, real desktop/mobile/200%-text/short-window states, keyboard focus, dialogs, transitions, Reduced Motion, and both console/runtime exceptions. Repeat verification after changes and correct the handoff claims. Backend work remains the subsequent phase; no remote action is authorized by this review.

