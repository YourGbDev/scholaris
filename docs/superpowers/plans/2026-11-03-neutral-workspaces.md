# Neutral provider and admin workspaces

Approved scope: individual providers, organization providers and admin. Match the student's white/neutral discipline; retain Geist, crisp full-card tokens, existing behavior and semantic colors for warnings, errors, decisions, charts and primary actions.

1. Add shared workspace theme tokens for neutral surfaces and charcoal-selected filters; scope inheritance to provider/admin shells so student screens do not change. Verify real filter selection and contrasting labels.
2. Remove decorative green/blue/cream backgrounds from informational panels, ordinary form fields, metadata and category decoration. Keep actual status/attention colors and data-series distinctions. Audit both explicit colors and inherited Material colors.
3. Add regression coverage for individual/org chip styling, the support panel, neutral admin canvas and semantic colors. Preserve all callbacks, filtering, safety guidance and review workflows.
4. Run provider/admin/theme checks, scoped analysis and builds; inspect actual individual, organization and admin previews at desktop/mobile sizes. Review final remaining color usages and document intentional semantic exceptions. No commit, release bump or IPA in this task.

## Completion and validation

Implemented shared neutral workspace theme scoped to individual/provider organization shells, admin and the routed scholarship form. Decorative pastel containers, routine metadata, identity badges, filter controls and supporting panels now use white/neutral surfaces. Brand navigation/actions, actual status/attention colors and chart series remain meaningful exceptions. Geist and shared crisp-card tokens remain in use. Added regression coverage for role surfaces and selected-school contrast; independent review found no remaining issues after the contrast fix.

Validation:
- Full suite during implementation: 1,285 passed, 6 skipped, no failures (`build/neutral-workspaces-full-tests.log`). Subsequent paint/contrast refinements received focused verification below.
- Latest relevant focused checks: 68 admin/workspace tests, 12 role visual/flow regressions and all 4 scholarship-form tests passed. Selected-school regression reproduced the white-on-white issue before the fix and passed afterward.
- Scoped analysis clean; provider and admin web preview builds successful; `git diff --check` clean.
- Inspected actual individual and organization desktop feeds and support surfaces, admin desktop and narrow reports/safety layout. Final refreshed provider feeds show neutral GWA/honor metadata and readable controls. No browser console errors in the three role previews. Narrow/enlarged-text behavior also covered by widget tests.
- Temporary browser viewport reset. Preview records are fictional and have no backend connection. No physical-device or new IPA verification was performed. No commit, push or release build performed for this follow-up.

## November 4 commit verification

User authorized committing the pending polish. Fresh full suite: 1,286 passed, 6 skipped, no failures (`build/precommit-nov04-tests.log`, exit 0). Landing JavaScript syntax and diff checks passed; all 11 local landing image references resolved. Commit includes the approved operational workspace/header changes, roadmap additions and landing assets/phone-frame fixes. Existing Build 29 version bump is preserved; no new IPA or push is authorized by this commit request.
