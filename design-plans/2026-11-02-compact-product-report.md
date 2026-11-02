# Compact typography rollout — November 2, 2026

User approved the homepage sample, then authorized applying its compact/selectively bold hierarchy to existing student tabs, settings, forms, provider, super admin and landing. Implemented in auth-tour-polish checkout. No commit, push, IPA, generated onboarding/art or new AI/chat behavior. Existing intro/onboarding composition remains deferred to its planned redesign; this pass updates existing working surfaces.

## What changed

- Shared Geist hierarchy: student page20px700, section17px700, card15px700, prose13–14 regular, metadata12–13/500, controls13/600. Approved Home greeting20, recommendation heading17, amount18, summary16 and trailing See all remain.
- Shared themes and explicit overrides aligned across Discover, Saved, Tracker/application details, Profile and setup, account/settings, auth/recovery, existing chat, safety/reporting, document dialogs and common state/dialog widgets.
- Provider/admin page titles adapt:20px at narrow widths and24px on desktop. Desktop metrics24–28 remain useful; operator body13.5–14 and existing small labels remain readable. No global font multiplier or text-scaling cap.
- Landing retains its accepted composition and content, with hero52 desktop/30–34 phone and section32/24, prose14–16. Recorded app screenshots and dimensional device labels retain their existing pixels/scale.
- Settings security/password heading groups and report-evidence label/button now wrap to preserve full-size readable text. Email label can wrap as well. Existing26px full-size cards, status semantics, auth/CAPTCHA/security, routing, repositories and application behavior remain intact.
- AGENTS.md updated to record the approved cross-role compact hierarchy. Root C:/scholaris and unrelated work preserved.

## Verification

- Full suite after integration/reflow fix: **1,251 passed, six skipped, six failed**. Failures match the six already reproduced against unchanged commit61476a5: three admin audit-write expectations and three scholarship/matching-order expectations. Not hidden or disabled. Log: build/product-compact-full-tests-final.log. After the final email-label wrapping refinement, account/safety targeted suite:33 passed.
- Provider/admin targeted suite:68 passed, including narrow/desktop/short-height200% text. Updated shared hierarchy and student suites run; visual assertions updated for intended size changes.
- Analyzer has no errors/warnings and12 informational lint findings in existing statement/string/test helper patterns. Role-only analysis clean. No claim of completely clean full analysis. Git whitespace check passed.
- Student/provider/admin web preview builds pass. Chrome captures cover Home, Discover, Tracker, Profile, detail groups, Settings,320/390 phone sizes,1440/768 operator layouts, and200% text. Final Settings checks replace the initially overflowing capture. Provider/admin overview/settings previews have no recorded runtime/overflow errors. No whole-app native-device verification claimed.
- Landing Chrome checks1440/390/320, normal/reduced motion,200% text reflow, custom Geist glyph faces, FAQ/provider switch/menu/modal keyboard behavior and media playback pass. See docs/reports/2026-11-02-compact-landing-typography.md.
- Independent integrated static review found no Critical/Important introduced issue. Browser screenshots use fictional local fixtures; Settings Unknown/unverified values reflect preview auth state, not a live user account.

## Remaining limits

No physical iPhone/Safari verification, release build, or live authenticated/backend actions tested here. Provider fixed-width sidebar labels can still truncate at200% text; core content reflows and role tests pass. Landing films/screenshots still show their previously recorded app UI; no media regenerated. Prior baseline test failures need separate functional follow-up before release. Full logs/capture matrices live under ignored build/product-compact-*; selected durable examples are in design-plans/2026-11-02-compact-product-evidence.
