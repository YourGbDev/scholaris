# Organization workspace review — October 23, 2026

## Scope and design direction

Scholaris organization workspace, Flutter web, primarily desktop with compact navigation. The intended audience is an organization administrator reviewing applications and managing scholarship programs. Its design should make operational state and available actions easy to understand, with professional language and restrained brand expression.

Applied the Apple HIG skill and Apple Design skill. Apple principles are translated to Flutter/web; this review does not require macOS menu bars, Apple-only materials or native iOS navigation in a browser. This is an audit, not a HIG certification or a security audit.

Browser inspected at 1440×1000: overview, applications, decisioning, scholarships, team empty/error states and activity empty/error states. Analytics was visually and interactively verified earlier in this session, including filters and CSV-copy feedback. Compact overview was inspected earlier; analytics/hero layout tests covered 360 and 1280 widths. Settings could not render in this disconnected fixture because it directly accesses the Supabase singleton. Settings, finance screens, application detail, create/edit scholarship form and reviewer assignment dialog received source review; their complete rendered flows remain unverified.

The preview initially lacked team/activity overrides. Added empty fixture overrides to the local preview entry only, permitting empty-state review without connecting to real records. The initial service errors are preview limitations, not evidence that production Supabase is broken. No live decisions, assignments, saves, exports of personal records or database changes were performed. No production UI was changed during this review.

## Findings in priority order

### High — Settings promises persistence for fields it does not save

`lib/features/provider/presentation/org/org_settings_tab.dart:127` — `_handleSave` updates only the profile name and optional phone, while the screen offers registration, address, representative, mission and notification controls and reports that the profile **and preferences** were updated. A null authenticated user also reaches the success message without a write. Users cannot reliably tell what persisted.

Recommendation: define which fields are supported, persist them or clearly mark them unavailable, preserve dirty state on failure, and report success only for confirmed writes. Do not claim preferences saved until they are stored. HIG: `feedback.md › Best practices`; `entering-data.md › Best practices`.

### High — Several export buttons give a success impression without an export

`org_incoming_applications_tab.dart:434` only invokes a toast saying applicant dossiers were exported. `org_scholarships_tab.dart:388` only shows a portfolio export success snackbar. Finance `org_disbursements_tab.dart:987` invokes a “generating” toast; legacy `org_analytics_tab.dart:86` likewise describes PDF/Excel generation without a corresponding export in that handler.

Recommendation: implement the actual export, or explicitly disable/label unavailable actions. The new org-admin analytics CSV-copy action does perform a clipboard write and correctly says **Copy report**, so use that honesty as the standard. HIG: `feedback.md`; Apple Design §1 Response — feedback must reflect the actual operation.

### High — Scholarship management presents unsupported assurances as facts

`org_scholarships_tab.dart:1610` and `:1670` claim all portfolios have been audited and secured through an accredited escrow bank. The screen also displays “Fully Escrowed,” while the implementation does not establish that condition from a verified escrow record. Applications show a fixed compliance statement (`org_incoming_applications_tab.dart:1917`). These are factual product claims, not decoration, even in a demo.

Recommendation: replace with neutral recorded status, such as “Funding verification not recorded,” and only expose certificate/verified labels when supported by a verifiable record. Remove fixed academic-year assertions from reusable screens. HIG: `charting-data.md › Best practices` on descriptive accuracy; skill Responsibility principle. This is a product-truth finding, not a legal conclusion.

### High — Custom segmented controls lack standard keyboard/selection behavior

Scholarship segments at `org_scholarships_tab.dart:862` use `GestureDetector` plus animated containers instead of focusable semantic selection controls. Pointer activation is implemented, but the widget does not supply button/selected semantics or keyboard activation. Similar custom controls warrant a shared audit.

Recommendation: use Flutter selection/button components or provide explicit focus, keyboard activation and selected semantics. Verify Tab/Shift-Tab/Enter/Space and visible focus. Sidebar InkWell at `org_provider_shell.dart:792` explicitly suppresses focus highlighting; it needs a visible replacement. HIG: `accessibility.md`; `sidebars.md › Best practices`; `buttons.md`.

### Medium — Opening a program's applicants loses the program context

`org_provider_shell.dart:160` accepts a scholarship ID from the scholarship screen but only switches to Applications. The ID is ignored, so the destination does not apply the selected program filter.

Recommendation: retain the scholarship ID and show its filter on arrival, with an obvious way to return to all applications. HIG: `layout.md › Best practices` on hierarchy and context; Apple Design on spatial consistency and predictability.

### Medium — Team and Activity error states expose raw technical details and lack an obvious retry

`org_team_view.dart:150` and `org_activity_log_view.dart:131` display `err.toString()`. The disconnected preview showed local paths and framework assertions. Pull-to-refresh exists, but recovery is not obvious to a desktop user.

Recommendation: concise user-facing error, persistent Retry action, technical details in diagnostics. Settings' direct singleton access also makes isolated preview/testing harder; the observed red error screen was fixture-specific and is not a confirmed production crash. HIG: `feedback.md`, `accessibility.md`, `layout.md`.

### Medium — Older screens use dense, inconsistent operational language and stale dates

Applications/Decisioning/My Scholarships retain repeated KPI blocks, dense metadata and labels such as “Pending Categorization,” “Endowments,” “Dossiers,” and fixed AY 2024–2025, while Overview/Analytics use simpler terminology. Decisioning largely duplicates Applications with a different initial filter. The overview footer still contains “Clear criteria. Thoughtful reviews. Decisions made by people.” despite the recent professional-copy pass.

Recommendation: standardize “Applications,” “Under review,” “Scholarship programs” and “Review application”; use a recorded cycle label or omit it. Consider one Applications destination with clearly named views if Decisioning has no distinct task. Align heading sizes, padding and action placement across screens. HIG: `typography.md › Ensuring legibility`, `layout.md › Best practices`. Consolidating destinations is design judgment, not a mandated Apple rule.

### Medium — Form navigation can discard unsaved work without warning

`scholarship_form_screen.dart:275` and `:575` pop the route directly. No dirty-state PopScope/confirmation is present in this form. Validation and a saving state exist, which are good foundations, but accidental back navigation can lose a long eligibility configuration.

Recommendation: dirty-state tracking and a short discard/keep-editing confirmation; do not interrupt unchanged forms. HIG: `entering-data.md`, `feedback.md`.

### Medium — Motion/accessibility support is incomplete at screen level

Shared PressableScale, StaggeredListItem and other helpers check reduced-motion preferences. However, sidebar AnimatedContainer/AnimatedDefaultTextStyle (`org_provider_shell.dart:800` onward) and the scholarship segmented control's local animation (`org_scholarships_tab.dart:864`) use fixed durations without that check. Repeated entrance effects on a work screen should not delay access to content or input.

Recommendation: retain immediate press feedback, avoid decorative replays on frequent navigation, bypass local motion when requested and test rapid interrupted switching. Apple HIG `motion.md › Best practices`; Apple Design §1 Response and §3 Interruptibility. No need to add springs or animation libraries to a static reporting view.

## Screen coverage and disposition

| Screen | Evidence | Assessment |
| --- | --- | --- |
| Overview | Browser desktop/compact, source | Clear current state and direct review/analytics actions. Remaining footer language and screen-specific consistency work. |
| Applications | Browser populated fixture, source | Useful search/filter structure; export feedback, stale claims and dense terminology need correction. |
| Decisioning | Browser empty filtered view, source | Shares Applications implementation; clarify distinct job or merge views. Empty state offers guidance but no direct reset-filter action. |
| My Scholarships | Browser populated fixture, source | Recognizable program cards; unsupported funding assurances, nonfunctional export and lost applicant-filter context are priorities. |
| Org-admin Analytics | Browser and tests earlier this session, source | Clear labelled counts, meaningful filters, honest missing values and working aggregate copy action. No historical funnel is invented from current status. |
| Team & Reviewers | Browser empty/error, source | Grouping and role filters are understandable. Roster population, assignment modal and permission behavior need connected/fixture interaction coverage. Empty state should distinguish no team from no filter results. |
| Activity Log | Browser empty/error, source | Familiar search/filter structure; improve retry and error disclosure. Source `_getActionVisuals` checks “assign” before “unassign,” so unassignment uses the assignment icon; reorder checks. |
| Settings | Source; fixture render blocked | Persistence mismatch is highest priority. Long sections, unsupported actions, keyboard access and actual saving require dedicated verification. |
| Finance analytics / Disbursements | Source only | Export feedback and stale year labels need attention. Legacy analytics assigns honor tiers/default geography from incomplete profile information; show missing data instead. No payout or authorization was executed. |
| Scholarship create/edit | Source | Has validators and saving feedback; add unsaved-work protection. Full desktop/compact forms and school picker not visually verified. |
| Application detail / reviewer assignment | Source | Requires dedicated rendered accessibility/dialog review. No approval, rejection or assignment actions executed. |

## Color and motion evidence

Computed from repository tokens, not screenshot pixels: secondary text `#5A645C` on canvas `#FAFAF7` is **5.89:1**; muted text `#545D56` on white is **6.82:1**; white on primary `#0F4D2E` is **9.90:1**. These combinations pass normal-text WCAG AA contrast. This does not certify every badge, placeholder, animated state or full-screen accessibility.

Success green `#27C93F` on white is **2.21:1**; do not use it alone for essential text/icons without another perceivable cue. Its presence as a token is not itself a proven screen defect. Large-text scaling, complete keyboard traversal, screen-reader output, dark appearance and connected backend workflows have not been validated by this audit.

## Suggested implementation order

1. Correct save/export feedback and unsupported assurances.
2. Standardize interactive controls, visible focus, recovery and dirty-form handling.
3. Apply Overview/Analytics typography, spacing and professional copy consistently to the older screens.
4. Complete populated Team/Activity, Settings and finance fixture coverage, then test connected workflows and compact/large-text/keyboard/reduced-motion behavior.

No wholesale redesign is needed. Keep the familiar sidebar, forest-green identity, working filters and existing role separation. Improve the accuracy and consistency of the tools first.
