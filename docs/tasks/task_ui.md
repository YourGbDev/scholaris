# Task Card: UI/UX (Master Remediation)

> **Assigned Role**: 🎨 UI/UX Specialist (`ai/ui`)  
> **Assigned Worktree**: `.../scholaris/bowhead`  
> **Master Plan**: `docs/plans/2026-10-06_master_remediation_plan.md`  
> **Status**: `AWAITING HUMAN APPROVAL`

---

## 1. Objectives (WS-3, WS-4, WS-5, WS-6 Focus)
Eliminate fake verification badges, fix responsive flex overflows, expand touch targets, optimize LiquidGlass, and enforce design tokens.

---

## 2. Mandatory Design Skills to Apply
Before auditing or writing UI code, load and inspect the 7 skills in `.agents/skills/`:
1. `apple-design` (`.agents/skills/apple-design/SKILL.md`)
2. `apple-design/cross-platform.md`
3. `apple-design/hig-lookup.md`
4. `emil-design-eng` (`.agents/skills/emil-design-eng/SKILL.md`)
5. `emil-apple-design` (`.agents/skills/emil-apple-design/SKILL.md`)
6. `review-animations` (`.agents/skills/review-animations/SKILL.md`)
7. `animate` (`.agents/skills/animate/SKILL.md`)

*Brand Identity Reminder*: Preserve Scholaris's Filipino academic identity (forest green `#0F4D2E`, warm gold accent, clean academic surfaces).

---

## 3. Allowed Files to Modify
* `lib/features/profile/presentation/profile_tab_screen.dart`
* `lib/features/scholarships/presentation/scholarship_detail_screen.dart`
* `lib/features/home/presentation/home_screen.dart`
* `lib/features/dashboard/presentation/student_dashboard_screen.dart`
* `lib/features/provider/presentation/provider_review_screen.dart`
* `lib/shared/theme/...`
* `lib/shared/motion/...`

---

## 4. UI/UX Checklist
- [ ] **Fix Finding 3.2.3**: Purge hardcoded "Verified" badges in `ProfileTabScreen` (lines 572, 599, 769, 935, 978). Bind directly to live `StudentProfile` attributes. If unverified, render neutral badge with actionable CTA.
- [ ] **Fix Finding 3.3.2**: Align identity photo requirement upfront; add warning badge to avatar selector and allow draft saving.
- [ ] **Fix Finding 3.5.1**: Ensure floating bottom nav pill scales down without text truncation on 320px–360px viewports.
- [ ] **Fix Finding 3.7.1**: Guard criteria title in `ProviderReviewScreen` with `Expanded` / `Flexible` to eliminate `RenderFlex` overflow.
- [ ] **Fix A11Y-05**: Expand touch targets to minimum 44×44pt on close buttons and filter icons.
- [ ] **Fix Finding 4.1**: Optimize `LiquidGlass` with opacity fallback for low-spec devices; eliminate nested blur filters.
- [ ] **Fix Finding 4.3**: Wrap scholarship stipend currency text in `FittedBox(fit: BoxFit.scaleDown)` and add compact formatting.

---

## 5. Output Report
Save report to: `docs/reports/remediation_ui_report.md`
Commit to branch `ai/ui`:
```bash
git add <modified-files> docs/reports/remediation_ui_report.md
git commit -m "feat(ui): implement UI/UX audit remediation fixes"
```
