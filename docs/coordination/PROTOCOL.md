# Scholaris Multi-Agent Coordination Protocol (Git-Backed Task-Card Relay)

## 1. Overview & Architecture

Scholaris uses a distributed, Git-backed coordination protocol across five specialized Orca worktrees sharing the same underlying local repository:

| Role | Worktree Directory | Active Branch | Primary Responsibility |
| :--- | :--- | :--- | :--- |
| 🧠 **Architect** | `.../scholaris/whelk` | `ai/architect` | Central coordinator, technical lead, system design, task delegation, report consolidation |
| 🔨 **Builder** | `.../scholaris/cowrie` | `ai/builder` | Application feature implementation, Flutter widgets, Riverpod providers, service logic |
| 🎨 **UI/UX** | `.../scholaris/bowhead` | `ai/ui` | Responsive layouts, Apple HIG review, Emil Kowalski motion craft, accessibility |
| 🔍 **QA** | `.../scholaris/cerith` | `ai/qa` | Independent testing, regression hunting, edge case verification, bug reproduction |
| 🛡️ **Security** | `.../scholaris/fusilier` | `ai/security` | Supabase RLS policies, storage bucket security, RA 10173 privacy boundaries, auth checks |

---

## 2. Directory Hierarchy

All coordination artifacts are versioned in Git under the `docs/` tree:

```
docs/
├── coordination/
│   └── PROTOCOL.md              # This protocol specification
├── plans/
│   └── <feature>_plan.md        # Master architecture & implementation plans (written by Architect)
├── tasks/
│   ├── task_builder.md          # Concrete assignment card for Builder
│   ├── task_ui.md               # Concrete assignment card for UI/UX
│   ├── task_qa.md               # Concrete assignment card for QA
│   └── task_security.md         # Concrete assignment card for Security
└── reports/
    ├── <feature>_builder_report.md
    ├── <feature>_ui_report.md
    ├── <feature>_qa_report.md
    ├── <feature>_security_report.md
    └── <feature>_FINAL_REPORT.md
```

---

## 3. End-to-End Workflow Lifecycle

```
[USER / TECH LEAD]
       │
       ▼ (1. Feature Request / Bug Report)
[🧠 ARCHITECT in whelk]
       │
       ├─► (2. Codebase inspection & architecture plan)
       ├─► (3. Writes docs/plans/<feature>_plan.md)
       ├─► (4. Writes docs/tasks/task_<role>.md for each relevant specialist)
       │
       ▼
[🛑 GATE: AWAITING HUMAN APPROVAL]
       │
       ▼ (5. Human reviews and types "> approved")
[🧠 ARCHITECT]
       │
       └─► (6. Announces execution sequence and exact specialist trigger commands)
       │
       ▼ (7. User issues 1-line trigger in specialist worktrees)
┌──────┴────────────────┬────────────────────────┬────────────────────────┐
▼                       ▼                        ▼                        ▼
[🔨 BUILDER]            [🎨 UI/UX]               [🔍 QA]                  [🛡️ SECURITY]
• Pulls task card       • Pulls task card        • Pulls test specs       • Pulls security specs
• Implements code       • Applies design skills  • Runs automated tests   • Audits RLS/privacy
• Runs analyzers/tests  • Checks Apple HIG       • Performs browser test  • Verifies data bounds
• Commits report        • Commits report         • Commits report         • Commits report
└──────┬────────────────┴────────────────────────┴────────────────────────┘
       │
       ▼ (8. Reports committed on specialist branches)
[🧠 ARCHITECT]
       │
       ├─► (9. Pulls all reports: git checkout ai/<role> -- docs/reports/...)
       ├─► (10. Reviews findings against verification standards)
       │        ├─► If issues found: Issues remediation task card & repeats loop
       │        └─► If all pass: Synthesizes findings
       │
       ▼
[📝 docs/reports/<feature>_FINAL_REPORT.md]
       │
       ▼ (11. Delivered to Human Tech Lead)
[USER / TECH LEAD]
```

---

## 4. Specialist Worktree Instructions

When a specialist receives a trigger command (e.g. `> run task` or `execute assigned task`), they MUST follow these steps:

### Step 1: Retrieve Your Task Card from Git
Do NOT wait for the user to paste instructions. Run:
```bash
git checkout ai/architect -- docs/plans/ docs/tasks/task_<role>.md
```
*(Replace `<role>` with `builder`, `ui`, `qa`, or `security`)*.

### Step 2: Read and Inspect
1. Read the master plan in `docs/plans/` to understand system context.
2. Read your specific role card in `docs/tasks/task_<role>.md`.
3. Inspect the files listed under **Allowed Files to Modify**. Do NOT modify files outside your assigned scope.

### Step 3: Execute Domain Responsibilities
* **🔨 Builder (`cowrie`)**:
  - Implement the requested logic, widgets, or services.
  - Follow existing conventions in `GEMINI.md`.
  - Run target analyzers (`flutter analyze <path>`) and unit tests (`flutter test <path>`).
* **🎨 UI/UX (`bowhead`)**:
  - MUST load and apply the 7 mandatory design skills in `.agents/skills/`.
  - Check Apple HIG guidelines and Emil Kowalski animation rules.
  - Test defensive layouts across 360px, 440px, and desktop (1280px).
* **🔍 QA (`cerith`)**:
  - Execute end-to-end tests and edge cases.
  - Verify live data integrity (no synthetic mocks or hardcoded completed states).
  - Test real browser rendering and console error logs.
* **🛡️ Security (`fusilier`)**:
  - Audit Supabase RLS policies and storage boundaries.
  - Enforce RA 10173 student privacy (no sensitive demographic fields leaked to providers).
  - Verify `auth.uid()` binding on all mutations.

### Step 4: Write Your Completion Report
Write your report to `docs/reports/<feature>_<role>_report.md` using the standard format:
* **Implemented / Tested**: Exactly what was executed.
* **Verified**: Concrete command/check run and the actual terminal output/result.
* **Not Verified**: What could not be checked and why.
* **Remaining Risks / Discovered Bugs**: Any blockers or adjacent regressions.

### Step 5: Commit Your Changes
Stage your modified code and report, then commit to your active branch:
```bash
git add <modified-files> docs/reports/<feature>_<role>_report.md
git commit -m "feat(<role>): complete <feature> task"
```

---

## 5. Verification Standards & Terminology

The Architect and all specialists must strictly distinguish between these five states:

1. **`IMPLEMENTED`**: Code has been written or edited by Builder/UI, but has not yet been verified by QA or Security.
2. **`REVIEWED`**: UI/UX or Security has inspected the diff against design/privacy standards.
3. **`TESTED`**: QA has run tests and verified terminal/browser execution without errors.
4. **`VERIFIED`**: Both automated checks and end-to-end transaction validations have confirmed correctness with real evidence. A Builder saying "fixed" is **NEVER** sufficient to mark something verified.
5. **`BLOCKED`**: Progress cannot continue due to an upstream dependency, conflicting requirement, or un-resolvable failure.

---

## 6. Remediation Loop Protocol

If QA, Security, or UI/UX discovers a defect or security risk:
1. The specialist documents the defect under **Remaining Risks / Discovered Bugs** in their report.
2. The Architect pulls the report, inspects the failure, and updates the task card (or creates `docs/tasks/remediation_task_<role>.md`).
3. The Architect notifies the user with the exact remediation sequence.
4. The Builder/UI implements the fix, and QA/Security retests until all acceptance criteria are **`VERIFIED`**.
