# Task Card: Q&A (Testing & Verification)

> **Assigned Role**: 🔍 Q&A Engineer (`ai/qa`)  
> **Assigned Worktree**: `.../scholaris/cerith`  
> **Feature**: [Feature Name]  
> **Master Plan**: `docs/plans/[feature]_plan.md`  
> **Status**: `TEMPLATE / READY FOR ASSIGNMENT`

---

## 1. Objective
[Concise summary of testing and verification targets]

---

## 2. Scope & Verification Mandate
A Builder claiming "fixed" is **NEVER** sufficient to mark something verified. You must independently reproduce, test, and provide tangible evidence.

---

## 3. Allowed Files to Modify
* `test/...`
* `integration_test/...`
*(Do NOT modify application code unless approved for test harness support)*

---

## 4. Testing Checklist
- [ ] Automated widget & unit tests executed with exit code 0
- [ ] Live data integrity verified: zero synthetic mocks or hardcoded completion states
- [ ] Real-browser execution tested on narrow mobile (360px) and desktop (1280px)
- [ ] Console checked for exceptions or unhandled Riverpod errors

---

## 5. Output Report Destination
Save your report to: `docs/reports/[feature]_qa_report.md`
Commit your test code and report:
```bash
git add <test-files> docs/reports/[feature]_qa_report.md
git commit -m "test(qa): verify [feature] test results"
```
