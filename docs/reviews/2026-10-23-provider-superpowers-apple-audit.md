# Provider UI/UX audit — October 23, 2026

## Scope and method
Superpowers using-superpowers + requesting-code-review for independent read-only reviews; Apple Design + Apple HIG for design evaluation. Reviewed current tracked and untracked working-tree source, not just HEAD (baseline 1ea30bb). Organization and individual reviewers worked independently. No production files changed in this audit.

Root also ran scratch/provider_ui_audit_test.dart at 200% text: 360×800, 1280×600 and 1280×420, both account types. Four cases passed; individual desktop cases overflowed by 869px and 1049px. Evidence: scratch/provider-ui-audit-text-scale.txt. This audit probe is outside the normal test directory. The previous standard suite's 910 passes/9 skips does not cover these newly failing cases.

## High priority — fix before calling provider polish complete
1. Org financial labels imply money has moved when only approval exists. org_scholarships_tab.dart:202–204 derives disbursement from approved/awarded listing amounts, with a 50000 fallback; :596 says Tranche 1 Disbursed. Use actual payment records or honestly labelled commitments; missing values are not default awards.
2. Org funding verification is unconditional. org_scholarships_tab.dart:519 says Fully Escrowed; :1555 asserts audited escrow backing. Rendered through :295. Remove assurance until supported by recorded verification.
3. Settings false success. org_settings_tab.dart:127–158 persists only name/nonempty phone but claims profile/preferences saved; individual_settings_tab.dart:55–74 also reaches success with no authenticated user. Unsupported fields should be disabled/explained, supported writes validated and acknowledged only after success.
4. Individual Approved award value is not immutable. individual_applications_tab.dart:114–118 sums current listing amounts, despite fixed support-ledger commitments. Editing a listing rewrites the apparent approved total. Use ledger commitments, warn about missing legacy amounts, and distinguish unavailable from zero.
5. Individual sidebar fails large text in short desktop windows. individual_provider_shell.dart:76 Column and :125 Spacer keep navigation/footer in a non-scrolling fixed-width layout. Reproduced 200% text at 1280×600/420; see evidence above. Provide a flexible scrollable navigation region and footer that remains reachable.
6. Essential org filters lack keyboard/selected semantics. org_incoming_applications_tab.dart:802 and org_scholarships_tab.dart:807 use GestureDetector/containers. Replace with standard segmented controls or explicit focus/activation/selected semantics.
7. Individual occupancy becomes zero during application-loading/error. individual_grant_tab.dart:60 uses valueOrNull ?? []; zero capacity claims remain visible. Withhold unavailable occupancy and offer retry.

## Medium priority — finish interaction/recovery consistency
8. Individual grant status always Active Grant (individual_grant_tab.dart:226), even closed/expired. Derive actual state.
9. Individual Approved chip counts approved+awarded but filtering is exact-status (individual_applications_tab.dart:120/:341). Match count and results.
10. Org View applicants loses selected program ID (org_provider_shell.dart:162). Carry visible program filter into destination.
11. Org candidate export remains enabled but has no handler (org_incoming_applications_tab.dart:1485). Disable honestly or implement.
12. Org settings section scrolling (:190) and local filter transitions bypass Reduced Motion. Apply shared preference to local motion too.
13. Org Team/Activity errors expose raw technical strings with no visible retry (org_team_view.dart:152; org_activity_log_view.dart:131). Use concise error plus Retry; diagnostics elsewhere.
14. Student-confirmed payment correction says platform review required but provides no provider request-review route (support_payment_correction.dart:117–123). Add scoped request action without exposing private student reports.
15. Payment records omit recorded sent/received timestamps (individual_support_tab.dart:327; student_support_receipts.dart:46). Display timestamps with honest recorded-time labels; do not infer actual transfer dates.
16. Planned payment dates cannot be cleared and remain displayed after completion (individual_support_tab.dart:266). Support clear/update/current-value prefill and completed state.

## Keep
Green identity, cleaner individual review, task-first org overview, honest missing-data analytics, actual clipboard CSV action, immutable commitment ledger, independent receipt confirmation, history-preserving corrections. Shared transitions exclude outgoing views from input/focus/semantics; aggregate animations expose final accessible values. Standard buttons/fields and reduced-motion-aware shared transitions are a strong foundation.

## Apple guidance applied
Local references under .agents/skills/apple-hig/references/hig/: layout.md › Visual hierarchy / Adaptability (progressive disclosure and text-size adaptation); accessibility.md › Vision / Speech / Cognitive (large text, keyboard access, Reduced Motion); feedback.md › Best practices (truthful actionable state); entering-data.md › Best practices (clear inputs and existing-value prefill); sidebars.md › Best practices (adaptable navigation); motion.md › Providing feedback (brief, cancellable motion). Apple Design principles: instant response, interruptibility, spatial consistency and restrained motion. Applied to Flutter/web; no claim of native macOS compliance or certification.

## Limits and next pass
Audit only; no fixes, commits, deployment or remote DB changes. Live migration dependencies are not UI defects. No full screen-reader/keyboard browser session, measured contrast matrix, physical touch/frame timing or live provider-session verification. Approval dialog at small height/200% text remains a specific unverified overflow risk. Real concurrent receipt/correction races remain untested. Backend deployment belongs to Archi's later pass; the UI priorities above should be addressed before platform-admin polish is considered the next finished milestone.
