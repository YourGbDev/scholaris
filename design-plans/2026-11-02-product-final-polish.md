# Scholaris final product polish implementation plan

> For agentic workers: use executing-plans, with independent surface tasks delegated under dispatching-parallel-agents. Existing uncommitted Home work is the baseline; preserve it. User explicitly authorized execution and supplied visual references. No additional design approval gate; no commit/push/IPA requested yet.

Goal: unify the product with neutral surfaces, modestly stronger Geist titles and clear spacing, retaining Scholaris's green/mascot identity and all existing behavior.

Spec: the November2 user request and seven supplied screenshots. Scholaris screenshots show excessive lavender nesting and too many equally heavy labels; Tarsi references demonstrate quiet white cards and selective title emphasis. Borrow those principles, not its font or branding.

## Shared contract

- Bundled Geist only. Page/section/card titles700; supporting metadata500; prose400; actions600. No blanket800 promotion. Preserve explicit weight400/500 choices; 800 remains bundled for deliberate exceptions, not a theme default.
- White cards; pale neutral green-gray canvas; neutral nested data surfaces. Green for primary action/brand, existing meaningful error/warning/success/info statuses retain their semantics. Do not blindly replace every blue status.
- `kRadiusCard`26, `kCardBorderCrisp`0.5 and `kCardElevationCrisp`; matching outer corners. Nested rows/controls use purpose-specific shapes. Prefer grouping, dividers and whitespace over colored boxes inside cards.
- Keep the friendly campus hero and right-side See all behavior already accepted. No new imagery, dependencies or feature work. No shrinking text to hide overflow.
- Preserve security, data, auth, profile readiness, role permission and download behavior. Do not invent metrics or silently replace factual copy. No backend changes, commit, push or IPA.
- Preserve all unrelated edits/archives. Latest Flutter checkout: `C:/Users/Windows 11/.codex/worktrees/auth-tour-polish/scholaris`, HEAD61476a5 plus this chat's uncommitted work. Newer uncommitted landing at `C:/scholaris/landing` is source evidence; preserve its root copy.

## Task1 — shared styles and student surfaces (parent)

- Change shared theme neutral surface tokens and explicit title roles in `lib/shared/theme/app_theme.dart`; retire automatic800 promotion; align inherited theme roles. Update existing typography assertions to the new approved contract.
- Trace profile, account/settings, Tracker, Saved, scholarship details and application/receipt surfaces. Remove decorative lavender and navy-tinted supporting text; use coherent neutral panels and readable wrapping. Card titles700, supporting body400/500. Keep status colors and all data/actions unchanged.
- Existing tests: Geist hierarchy/loading, profile tab/completion/loading, account settings, saved, application workflow, scholarship card/details and Home/tour accessibility.

## Task2 — provider/admin surfaces (delegated)

- Own `lib/features/provider`, `lib/features/admin`, `lib/admin` and corresponding role tests. Parent owns shared theme. Reuse its incoming neutral surfaces/700 title rules; remove local title800 and decorative blue/lavender fills in role themes/workspaces/forms. Preserve status palettes, charts and data density. Do not redesign routes or business logic.
- Run relevant role widget tests and inspect rendered provider/admin preview at supported widths. Do not launch concurrent Flutter web builds in the shared checkout; coordinate renders with parent.

## Task3 — landing (delegated)

- Inspect the newer root landing, preserve its existing content/composition and local dependencies. Copy the necessary current page/dependencies to the Flutter worktree before polishing there; leave root original untouched. Do not replace its identity with the older committed landing.
- Calm global typography.css800/600 overrides to selective700 titles,400 prose,500 metadata and600 controls. Remove decorative blue/lavender neutral sections, polish grouping/spacing and mobile behavior. Keep actual links/media/behavior. Read design-taste-frontend refinement guidance and verify real browser desktop/mobile.

## Task4 — integration and review (parent)

- Review every task diff. Reconcile AGENTS.md so future edits do not restore obsolete weights/colors. Run appropriate combined widget suites, analyzer and landing checks; inspect final renders at320/390/440 and enlarged text, plus operator desktop and landing mobile/desktop.
- Fresh independent review of the integrated changes; fix introduced important findings. Report exact scope, checks, screenshots and any remaining device limitations. Keep changes reviewable and uncommitted until the user requests the commit.

## Review focus

Role-local text overrides must not reintroduce800. Neutralization must preserve meaningful states. Long institution/title text and 2x scaling must wrap. Sparse/empty/unknown data must remain honest. Landing import must preserve the user's newer work and required asset paths.
