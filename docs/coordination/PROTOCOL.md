# Scholaris Multi-Agent Coordination Protocol (Git-Backed Task-Card Relay with Automated Report Monitoring)

## 1. Overview & Architecture

Scholaris uses a distributed, Git-backed coordination protocol across five specialized Orca worktrees sharing the same underlying local repository:

| Role | Worktree Directory | Active Branch | Primary Responsibility |
| :--- | :--- | :--- | :--- |
| 🧠 **Architect** | `.../scholaris/whelk` | `ai/architect` | Central coordinator, technical lead, system design, task delegation, automated monitoring, report consolidation |
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

## 3. The Six-Phase Workflow Lifecycle

```
[USER / TECH LEAD]
       │
       ▼ (1. Feature Request)
[🧠 ARCHITECT in whelk]
       │ Analyzes codebase & drafts docs/plans/<feature>_plan.md + 4 task cards
       ▼
════════════════════════════════════════════════════════════════════════
PHASE 1: HUMAN APPROVAL (Non-Negotiable Gate)
════════════════════════════════════════════════════════════════════════
Architect HALTS at: "STATUS: AWAITING HUMAN APPROVAL".
Architect NEVER instructs specialists to begin without explicit human approval.
User reviews plan and approves ONCE: "> approved".
       │
       ▼
════════════════════════════════════════════════════════════════════════
PHASE 2: SPECIALIST TRIGGER
════════════════════════════════════════════════════════════════════════
Architect commits plan/tasks to ai/architect and announces the four 1-line triggers.
User sends the one-line trigger to each specialist worktree:
  • In cowrie (Builder):   "> execute assigned task"
  • In bowhead (UI/UX):    "> execute assigned task"
  • In cerith (QA):        "> execute assigned task"
  • In fusilier (Security):"> execute assigned task"
       │
       ▼
════════════════════════════════════════════════════════════════════════
PHASE 3: AUTOMATIC REPORT MONITORING (Zero Human Follow-Up)
════════════════════════════════════════════════════════════════════════
User does NOT need to say "collect reports" or monitor progress.
Architect schedules a lightweight background monitor via schedule tool:
  • Checks local Git refs every 2 minutes:
      git show ai/builder:docs/reports/<feature>_builder_report.md
      git show ai/ui:docs/reports/<feature>_ui_report.md
      git show ai/qa:docs/reports/<feature>_qa_report.md
      git show ai/security:docs/reports/<feature>_security_report.md
  • Self-terminating: As soon as all required reports exist, Architect
    cancels the schedule (manage_task kill) and automatically resumes.
       │
       ▼
════════════════════════════════════════════════════════════════════════
PHASE 4: ARCHITECT CONSOLIDATION
════════════════════════════════════════════════════════════════════════
Architect automatically retrieves all reports:
  git checkout ai/<role> -- docs/reports/<feature>_<role>_report.md
Architect inspects code diffs, logs, and test results against the master plan.
       │
       ├─► Are defects or regressions discovered?
       │   ▼
       │   ═════════════════════════════════════════════════════════════
       │   PHASE 5: REMEDIATION LOOP
       │   ═════════════════════════════════════════════════════════════
       │   • Architect creates docs/tasks/remediation_task_<role>.md
       │   • Architect notifies User with exact specialist trigger
       │   • Specialist fixes issue; QA/Security retests
       │   • Returns to Phase 3 monitoring until retest confirms pass
       │
       ▼ All acceptance criteria satisfied
════════════════════════════════════════════════════════════════════════
PHASE 6: FINAL VERIFICATION
════════════════════════════════════════════════════════════════════════
Architect verifies evidence under the Verification Integrity Rule.
Architect writes docs/reports/<feature>_FINAL_REPORT.md.
Architect presents final consolidated result to the Human Tech Lead.
```

---

## 4. Specialist Worktree Instructions

When a specialist receives `> execute assigned task`:

### Step 1: Retrieve Task Card from Git
Run:
```bash
git checkout ai/architect -- docs/plans/ docs/tasks/task_<role>.md
```
*(Replace `<role>` with `builder`, `ui`, `qa`, or `security`)*.

### Step 2: Read and Inspect
1. Read the master plan in `docs/plans/` for context.
2. Read your specific role card in `docs/tasks/task_<role>.md`.
3. Only modify files listed under **Allowed Files to Modify**.

### Step 3: Execute Domain Responsibilities
* **🔨 Builder (`cowrie`)**: Implement logic, widgets, or services. Run `flutter analyze` and `flutter test`.
* **🎨 UI/UX (`bowhead`)**: MUST load and apply the 7 mandatory design skills in `.agents/skills/`. Verify Apple HIG, contrast, touch targets, and Emil Kowalski motion rules.
* **🔍 QA (`cerith`)**: Independently test and verify. Ensure zero synthetic mocks or hardcoded completion states. Test terminal/browser execution with exit code 0.
* **🛡️ Security (`fusilier`)**: Audit RLS policies, storage boundaries, RA 10173 student privacy, and `auth.uid()` bindings.

### Step 4: Write Completion Report
Write your report to `docs/reports/<feature>_<role>_report.md`:
* **Implemented / Tested**: Exactly what was executed.
* **Verified**: Concrete command/check run and the actual terminal output/result.
* **Not Verified**: What could not be checked and why.
* **Remaining Risks / Discovered Bugs**: Any blockers or adjacent regressions.

### Step 5: Commit Your Changes
Stage code and report, then commit to your active branch:
```bash
git add <modified-files> docs/reports/<feature>_<role>_report.md
git commit -m "feat(<role>): complete <feature> task"
```

---

## 5. Automated Monitoring Mechanism Details

To preserve token quota and avoid continuous model spinning:

1. **Lightweight Schedule**:
   * Architect invokes `schedule(CronExpression="*/2 * * * *", Prompt="Check for completed specialist reports in docs/reports/", MaxIterations=15, IsDaemon=false)`.
   * Does not run heavy LLM inference during wait; runs a 1-second shell query against Git refs.
2. **Git Ref Polling**:
   * Checks branch heads without touching the working tree:
     ```bash
     git show ai/builder:docs/reports/<feature>_builder_report.md
     ```
3. **Immediate Self-Termination**:
   * When all declared reports return exit code 0, Architect immediately executes:
     ```json
     manage_task(Action="kill", TaskId="<scheduled-task-id>")
     ```
   * Architect immediately moves to Phase 4 (Consolidation).

---

## 6. Verification Standards & Terminology

Architect and specialists must strictly distinguish:

1. **`IMPLEMENTED`**: Code has been written or edited by Builder/UI, but has not yet been verified by QA or Security.
2. **`REVIEWED`**: UI/UX or Security has inspected the diff against design/privacy standards.
3. **`TESTED`**: QA has run tests and verified terminal/browser execution without errors.
4. **`VERIFIED`**: Both automated checks and end-to-end transaction validations have confirmed correctness with real evidence. A Builder saying "fixed" is **NEVER** sufficient to mark something verified.
5. **`BLOCKED`**: Progress cannot continue due to an upstream dependency, conflicting requirement, or un-resolvable failure.

---

## 7. Remediation Loop Protocol

If QA, Security, or UI/UX discovers a defect or security risk:
1. Specialist documents the defect under **Remaining Risks / Discovered Bugs** in their report.
2. Architect pulls the report, inspects the failure, and updates the task card (or creates `docs/tasks/remediation_task_<role>.md`).
3. Architect notifies the user with the exact remediation sequence.
4. Builder/UI implements the fix, and QA/Security retests until all acceptance criteria are **`VERIFIED`**.
