# Task Card: UI/UX (Visual & Interaction Review/Design)

> **Assigned Role**: 🎨 UI/UX Specialist (`ai/ui`)  
> **Assigned Worktree**: `.../scholaris/bowhead`  
> **Feature**: [Feature Name]  
> **Master Plan**: `docs/plans/[feature]_plan.md`  
> **Status**: `TEMPLATE / READY FOR ASSIGNMENT`

---

## 1. Objective
[Concise summary of visual, motion, and interaction goals]

---

## 2. Mandatory Design Skills to Apply
Before auditing or designing, load and inspect the 7 skills in `.agents/skills/`:
1. `apple-design` (`.agents/skills/apple-design/SKILL.md`)
2. `apple-design/cross-platform.md`
3. `apple-design/hig-lookup.md`
4. `emil-design-eng` (`.agents/skills/emil-design-eng/SKILL.md`)
5. `emil-apple-design` (`.agents/skills/emil-apple-design/SKILL.md`)
6. `review-animations` (`.agents/skills/review-animations/SKILL.md`)
7. `animate` (`.agents/skills/animate/SKILL.md`)

*Brand Identity Reminder*: Preserve Scholaris's Filipino academic identity (forest green `#0F4D2E`, warm gold accent, institutional trust). Do NOT build an Apple clone.

---

## 3. Allowed Files to Modify
* `lib/features/.../presentation/...`
* `lib/shared/theme/...`
* `lib/shared/motion/...`

---

## 4. UI/UX Checklist
- [ ] Responsive layouts verified across 360px, 440px, and 1280px
- [ ] No `RenderFlex` overflow warnings
- [ ] Apple HIG compliance verified (touch target minimum 44×44pt, WCAG AA contrast ≥ 4.5:1)
- [ ] Emil Kowalski motion rules applied (`| Before | After | Why |` table, sub-300ms, `PressableScale`)

---

## 5. Output Report Destination
Save your report to: `docs/reports/[feature]_ui_report.md`
Commit your work:
```bash
git add <modified-files> docs/reports/[feature]_ui_report.md
git commit -m "feat(ui): [brief summary of UI changes]"
```
