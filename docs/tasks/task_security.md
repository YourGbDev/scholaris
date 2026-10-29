# Task Card: Security (`fusilier` Session)

**Sprint**: Final Focused Student Navbar Proportions Pass (`student-navbar-proportions-2026-10-27`) & Student Motion Integration  
**Target Deadline**: Completed — Standing down on standby; student navbar and motion handed off to Codex  
**Role**: 🛡️ Security, Privacy & Compliance Specialist  
**Assigned Workspace**: `C:\scholaris` on branch `fix/touch-targets-oct02`  
**Standing Contract**: [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)  
**Status**: `STANDBY (COMPLETED / HANDED OFF TO CODEX)`

---

## 1. Permitted Files (Exact Named Files Only)

### Sole Edit Ownership:
- `C:\scholaris\docs\reports\student-navbar-proportions-2026-10-27\security.md` (deliverable report)

### Read-Only / Invariants:
- All product and test files (read-only review)

---

## 2. Directives

1. **Accessibility Semantics & Touch Targets on Icon-Only Collapsed Control**:
   - Verify that collapsing the dock to an icon-only near-circle (52px width $\times$ 58px height) maintains minimum 44×44 pt touch targets.
   - Verify that the collapsed compact control retains full accessibility semantics (`Semantics(button: true, label: '${tab.label} Tab. Navigation collapsed, tap to expand navigation', hint: 'Restores all navigation tabs')`) so screen reader users are never left uninformed.
2. **Contrast Ratio Audit**:
   - Re-confirm contrast between `#0F4D2E` and `#DCF3E5` on the selected capsule (7.83:1 meets WCAG AAA).
   - Re-confirm high-contrast mode solid opaque white container fallback.
3. **Delivery**:
   - Deliver report to `C:\scholaris\docs\reports\student-navbar-proportions-2026-10-27\security.md`.
