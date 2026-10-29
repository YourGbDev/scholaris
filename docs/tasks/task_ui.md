# Task Card: UI/UX (`bowhead` Session)

**Sprint**: Final Focused Student Navbar Proportions Pass (`student-navbar-proportions-2026-10-27`) & Student Motion Integration  
**Target Deadline**: Completed — Standing down on standby; student navbar and motion handed off to Codex  
**Role**: 🎨 Presentation, Responsive Layout & Accessibility Specialist  
**Assigned Workspace**: `C:\scholaris` on branch `fix/touch-targets-oct02`  
**Standing Contract**: [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)  
**Status**: `STANDBY (COMPLETED / HANDED OFF TO CODEX)`

---

## 1. Permitted Files (Exact Named Files Only)

### Sole Code & Report Ownership:
- `C:\scholaris\lib\features\home\presentation\home_screen.dart` (sole product code ownership)
- `C:\scholaris\lib\dev\student_navbar_preview\main.dart` (preview fixture alignment)
- `C:\scholaris\docs\reports\student-navbar-proportions-2026-10-27\ui.md` (deliverable report)

### Read-Only / Invariants:
- All test files in `test/` (QA ownership)
- Controller mechanics in `StudentScrollDockController` (Builder ownership; UI only updates layout dimensions / styling)
- Shared global `LiquidGlass` in `lib/shared/theme/app_motion.dart` (FROZEN)

---

## 2. Requirements & Aesthetic Specifications

Grounded in owner-approved concepts and latest reference screenshots:
- `ref_proportions_1.png` (`C:/Users/Windows 11/AppData/Local/Temp/codex-clipboard-cdd595d8-dce5-4ee4-9de5-e0afcf059e9f.png`)
- `ref_proportions_2.png` (`C:/Users/Windows 11/AppData/Local/Temp/codex-clipboard-e846b13e-f0a1-4c6f-8862-4453675e6a3c.png`)
- Apple Design Section 12 *Materials & Depth* & Apple HIG *Tab Bars*

### Exact Directives:
1. **Slimmer Standard Dock Height (56–60 logical px)**:
   - In `computeStudentDockHeight`: update standard non-accessible dock height from `62.0` to `58.0` logical px.
   - Separate Quick Action `+` button matches the dock height: `size = 58.0` logical px.
2. **Compact Outline Icons & Small Readable Labels**:
   - Tab icons: compact, consistent outline icons sized ~22–24 (e.g. `23.0` or `22.0`).
   - Tab labels: small readable labels at base font size `10.5` (outfit font, weight `w600` unselected, `bold` selected).
3. **Selected Soft Capsule Surrounds BOTH Icon and Label**:
   - In `_StudentNavItem`:
     - When `selected: true`: render a soft rounded capsule (`#DCF3E5` mint green) that encloses **BOTH** the icon and the label together.
     - Icon color: `#0F4D2E` (Scholaris deep green).
     - Label color: `#0F4D2E` (Scholaris deep green).
     - No solid green across the whole bar—only on the active tab's soft capsule.
     - Unselected items: `#1C1C1E` dark icon and label on transparent background (no capsule).
4. **Collapsed State: ICON-ONLY Near-Circle (48–52 logical px)**:
   - When collapsed, the 4-tab pill dock shrinks and left-anchors into a near-circle of **`50.0`–`52.0` logical px** (e.g. `pillWidth = effectiveCollapsed ? 52.0 : maxPillWidth`).
   - `_StudentNavCompactControl` renders **ICON ONLY**:
     - No visible label / no wide 112px pill.
     - Selected icon sized `24.0`, `#0F4D2E` deep green, centered inside the circular/pill mint container (`#DCF3E5`).
     - Semantic accessibility label strictly retained: `label: '${widget.label} Tab. Navigation collapsed, tap to expand navigation'`, `hint: 'Restores all navigation tabs'`, `button: true`.
     - Touch target meets platform minimum ($\ge 44\text{pt}$).
5. **Preserve Clearer 0.22 Directional Glass**:
   - Preserve `kStudentNavGlassTintOpacity: 0.22`, `DirectionalGlassRimPainter` with 85% Top-Left key light and 45% Bottom-Right ground bounce, and subtle ambient occlusion shadows.
6. **Accessible Mode & Geometry Clearance**:
   - In large dynamic type (2.0x, 3.0x), 2x2 reflow is preserved; do NOT shrink text.
   - `computeStudentContentClearance(context)` dynamically computes bottom clearance based on actual `dockHeight`: `bottomPad + dockHeight + 16.0` (which is `90.0px` under standard 1.0x with `dockHeight: 58.0`).
7. **Verification & Delivery**:
   - Run `cd C:\scholaris; flutter analyze lib/features/home/ lib/dev/`.
   - Deliver report to `C:\scholaris\docs\reports\student-navbar-proportions-2026-10-27\ui.md` including mandatory "Skills Applied" section.
