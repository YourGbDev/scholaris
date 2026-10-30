# Real-screen student tour correction

User explicitly approved the two re-audit fixes and requested replacing invented guide screens with actual app views, a compact readable note with exterior tap instruction, and genuine end-of-content gates.

- Preserve unrelated work and Geist Sans; no commit/push/version/IPA.
- Delay first/replayed welcome until profile data resolves. Tap anywhere on non-intro mascot greetings, including bubble text/portrait; first greeting retains Skip/Continue.
- Use real Home, Discover, ScholarshipDetailScreen, SubmitApplicationReviewDialog, Tracker, Profile and quick menu presentation. No fabricated demo Discover/detail/Tracker pages. Only one scholarship is opened, from Discover after browsing.
- Add optional isolated detail/review presentation hooks that disable live upload/edit/submission callbacks, while reusing the exact production widgets and layout.
- Discover scroll gate uses current scroll metrics extentAfter <=24, not elapsed time, short swipe distance, or crossing an anchor. Only after reaching the real feed bottom may the tour point to one actual card.
- Actual detail scroll gate reaches its existing Back to top area before Apply instruction. Tapping Back to top scrolls the actual detail view and advances to Apply.
- Notes use 28px phone margins, about20px heading/15px body, rounded22px and exterior white tap-anywhere text. Scroll stages keep content visible and do not auto-advance.
- Submission remains simulated with no writes; celebration explicitly says nothing was sent. Tracker lesson uses the actual Tracker screen without inserting a fake application.
- Test both audited defects, real-screen component reuse, partial/bottom scroll boundaries, one detail opening, Back to top sequencing, no production callbacks, narrow/large text, Skip/replay/account change. Run affected tests/analysis and attempt fresh390×844 browser verification; report if disabled.

Execution: parent owns main journey/Home/Discover. Independent tasks own detail/review hooks and greeting/audit fixes; final integrated review and checks remain parent responsibility.
