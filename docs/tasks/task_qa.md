# Task Card: Q&A (Master Remediation Verification)

> **Assigned Role**: 🔍 Q&A Engineer (`ai/qa`)  
> **Assigned Worktree**: `.../scholaris/cerith`  
> **Master Plan**: `docs/plans/2026-10-06_master_remediation_plan.md`  
> **Status**: `AWAITING HUMAN APPROVAL`

---

## 1. Objectives
Independently test and verify all P0/P1 remediation fixes. A Builder claiming "fixed" is **NEVER** sufficient to mark something verified.

---

## 2. Allowed Files to Modify
* `test/...`
* `integration_test/...`

---

## 3. Verification Checklist
- [ ] **Test Finding 3.2.1**: Write and execute unit tests for Philippine GPA validation:
  - Input `1.25` on 5.0 scale -> Passes.
  - Input `88.5` on percentage scale -> Passes.
  - Input `3.75` on 4.0 scale -> Passes.
  - Input `0.5` or `105.0` -> Fails with appropriate error message.
- [ ] **Test Finding 3.2.2**: Verify tapping "Edit Location" on `ProfileTabScreen` navigates to financial/location step without 404.
- [ ] **Test Finding 3.2.3**: Verify profile badges with clean account: zero fake "Verified" badges shown.
- [ ] **Test Finding 3.3.1**: Verify Discovery filter chips ("Match >90%", "₱50k - ₱150k+") reactively filter results.
- [ ] **Test Viewports**: Verify layouts at 320px, 360px, 440px, and 1280px. Confirm zero `RenderFlex` overflows in browser console.

---

## 4. Output Report
Save report to: `docs/reports/remediation_qa_report.md`
Commit to branch `ai/qa`:
```bash
git add <test-files> docs/reports/remediation_qa_report.md
git commit -m "test(qa): verify master remediation results"
```
