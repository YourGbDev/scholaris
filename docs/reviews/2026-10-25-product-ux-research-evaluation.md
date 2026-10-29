# Scholaris product and UX research — October 25, 2026

Status: research for owner evaluation only. No product/UI/backend implementation, release or scope expansion. Student app polish proposal is approved in chat; implementation sequencing remains separate. Existing landing page and green/gold identity preserved.

## Method and limits

Inspected current landing-page source and existing provider overview implementation/prior verification report. Researched public first-party product pages, developer release notes and government design guidance. This is an opportunity report, not a fresh full UI audit, authenticated competitor-portal test or measured user study. Vendor claims are descriptions of offered capabilities, not independent proof of conversion, usability or time saved. Benefits below are hypotheses for Scholaris testing.

## Sources and transferable patterns

- Common App https://www.commonapp.org/ — combines education mission with explore/plan/apply steps and audience-specific guidance. Adapt content-to-action clarity; don't reproduce its branding or institution claims.
- Scholarship America https://scholarshipamerica.org/students/ — distinct student/sponsor resources and clear routes into scholarship browsing. Adapt role clarity and preparation help.
- Submittable https://www.submittable.com/solutions/scholarship-management — publicly documents reviewer roles/tasks, comments, permission/anonymization tools and multi-program review cycles. Adapt organization workflow context; do not impose committees/rubrics on individual benefactors.
- Blackbaud Award Management https://www.blackbaud.com/products/award-scholarship-management — describes qualified opportunity recommendations and coordinated review with flexible permissions. Adapt explainable matching and appropriate visibility, not opaque rankings/guaranteed eligibility.
- GOV.UK task completion https://design-system.service.gov.uk/patterns/complete-multiple-tasks/ — shows task order and completion. Useful for document preparation/provider setup, with real completion checks rather than cosmetic percentages.
- GOV.UK confirmation https://design-system.service.gov.uk/patterns/confirmation-pages/ — reference/receipt and what happens next. Improve existing Scholaris receipt/status patterns; do not duplicate them or promise delivery channels not connected.
- Linear https://linear.app/ — demonstrates product interfaces and workflow relationships. Adapt connected product explanation on landing page and relevant context during work, without dark-tech restyling.
- Tarsi guide https://www.tarsi.cloud/guide — short topic guides with optional sequence and browser-local progress. Adapt contextual help instead of large mandatory tours.

## Landing page: preserve, deepen, prove

Existing hero, Discover/Apply/receipt/Track story, mascots and individual/organization preview selector already provide a foundation. Retain these; do not add another screenshot carousel or redundant journey section.

1. Why Scholaris exists: founder-origin editorial section about scattered announcements, missed opportunities and uncertain progress. Real wording; no fabricated testimony/impact numbers. Low implementation, highest personal distinction.
2. One application, both sides: optional clearly fictional interactive scene connecting student submission, provider review and student update. Evolves existing separate demos rather than adding a disconnected animation. Medium presentation work; preserve human decision and no guaranteed awards. Static/stepped Reduced Motion fallback, keyboard controls.
3. Practical preparation block: what students should prepare, which documents vary by program, who reviews an application and what submission does/doesn't mean. Role-specific provider checklist. Existing FAQ can absorb this; no new feature required.
4. Truthful trust explanation: exact provider review meaning, student information boundaries, reporting/support entry points, current beta/demo availability. Avoid badges implying accreditation, verified funds or legal certification.
5. Later genuine school case study, only with permission and actual participation; use interviews to validate needs. No school logos/endorsements/testimonials before authorization.

## Student experience

Approved polish: Home label; glass bottom navigation with separate+; bottom sheets; actionable summaries; visible/clearable filters; small purposeful mascot reactions. Test full navigation before deciding scroll-collapse behavior.

Research additions for evaluation:
- Task-based readiness: actionable missing/ready/needs-update items, leading to exact field/document. No duplicate generic onboarding checklist if existing one works.
- Explainable matches: show recorded requirement comparisons and unknowns; never predict acceptance or treat GPA alone as eligibility. Additional logic/data is later scope.
- Existing receipt enriched with saved reference, timestamp, current status and next responsible role. Exact dates only if provider supplied; unknowns stay unknown.
- Filtered navigation retains filter and scroll context after detail/back.
- Inline short help on unfamiliar requirements rather than interruptive tours.

## Organization portal

Retain current separate reviewer/administrator authority and existing task-first overview.
- Review queue continuity: clear program+cycle context, status, last activity, next action; retain filters/scroll when returning. Avoid displaying invented overdue states where no review SLA exists.
- Review workspace keeps document, criteria and saved review notes near one another on desktop; accessible single-column alternative on narrow widths.
- Assigned-to-me/stage/needs-action views only when backing assignment/state exists. Avoid adding fake filters or duplicate dashboard tiles.
- Setup/publish readiness: program criteria, school restrictions, capacity, deadline, visibility and last check, with prepublication summary. May refine existing forms.
- Cycle summary answers operational questions (unreviewed, endorsed, approved, occupied places) with definitions; distinguish application count from distinct applicants.
- Saved views/assignment tooling/cycle reuse later if real multi-reviewer testing confirms need. Never clone student records/documents into a new cycle automatically.

## Individual portal

Do not shrink the org console and keep its jargon. Preserve direct personal decision flow and immutable approved commitments.
- Quiet next-action list: review applicant, finish draft grant, record planned support date. Use available actual data.
- Applicant decision summary: context, criteria evidence/unknowns, support amount/frequency, budget impact and what decision will notify. No automatic merit ranking or compelled funding decisions.
- Support states remain explicit: planned, provider-marked sent, student-confirmed receipt; approval is not payment, sent is not received. A timeline can improve existing ledger presentation without becoming a payment service.
- Contextual explanations for frequency, coverage, commitment and corrections; accessible via short help.
- Personal purpose visible on grant/public description, not an invented success story. No peer-to-peer private meetup or private student chat feature proposed.

## Shared/super-admin portal

Preserve provider approvals and reports as different decisions, task-first queues and correct application naming. Show origin/context, saved note state and next action. Helpful trust/help content can be public, but student safety case data never goes into provider views or public landing-page proof. Glass is a selective student-navigation material; dense provider financial/review surfaces stay solid and readable.

## Priority recommendation

Near-term candidate refinements: founder story; role-specific preparation/help copy; Home shortcut-to-filter behavior; queue context/back navigation; clear receipts/next steps; test approved navbar full state. Validate current implementation before labeling any item missing.

Next demo enhancement, if capacity permits: connected student/provider interactive landing demonstration using isolated fixtures.

After demo/validated need: saved review views, cycle templates, more advanced matching explanations, native privacy cover and deeper personalization.

Avoid before demo: full redesign, CRM/chat, payment rails, automated applicant ranking, forced mascots/gamification, invisible gesture-only navigation, glass on dense records and unrelated financial features.

## Evaluation plan

Small moderated task sessions with students, a school scholarship coordinator and an individual provider. Record task completion without help, wrong turns, error recovery and understanding of current/next status. Test whether user can identify why a scholarship is suggested, whether application was saved, who decides next, and whether payment is actually confirmed. Keyboard/mobile/200% text/Reduced Motion samples accompany task tests; do not equate aesthetic preference or vendor marketing with usability evidence.

## Skills applied

Read/applied design-taste-frontend for subject-led differentiation and preserving the existing design; its app-screen guidance for workspaces; impeccable routing for hierarchy, copy, states and restrained improvements. Apple Design/HIG-informed existing constraints retained (accessible controls, readable scaling, Reduced Motion, clarity), but this is not a fresh HIG compliance audit or contrast measurement. No design-direction generation/build was needed because task is external research/evaluation, not redesign implementation.
