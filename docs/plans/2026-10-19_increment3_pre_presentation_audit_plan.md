# Master Audit Plan: Increment 3 Pre-Presentation Audit

**Date:** 2026-10-19  
**Coordinator:** 🧠 Architect (`whelk` / `ai/architect`)  
**Target:** 3rd Increment / Checking in Application Development  
**Feature Branch:** `fix/touch-targets-oct02` / `ai/architect` (Commit: `2609416`)  
**Status:** `AWAITING HUMAN APPROVAL`

---

## 1. Executive Summary & Objective

The objective of this comprehensive audit is to rigorously inspect and verify the Scholaris codebase and demo environment against the instructor's explicit requirements for the **3rd Increment / Checking in Application Development** before live classroom presentation:

1. **One Complete Transaction Cycle**:
   - Multi-role handoff: Student (`demo_student@scholaris.ph`) -> Evaluator (`demo_evaluator@scholaris.ph`) -> Organization Admin (`demo_provider@scholaris.ph`) -> Student.
   - Clean status progression: `draft` -> `submitted` -> `under_review` -> `endorsed` -> `approved` / `awarded`.
   - Real-time in-app receipt of award & official **Scholarship Approval Letter & Award Certificate** ([`ApplicationDecisionLetter`](file:///C:/scholaris/lib/features/applications/presentation/application_decision_letter.dart)).
2. **Database Expansion & Accurate Transaction Storage**:
   - Verification of transaction tables: `applications`, `application_reviews`, `organization_memberships`, `notifications`, `audit_logs`, `disbursements`.
   - Complete audit trail with timestamps, reviewer scores, decision rationales, and foreign keys.
3. **Zero Browser Alerts ("localhost says" strictly banned)**:
   - 100% in-system UI feedback: Flutter `SnackBar`, native modal `AlertDialog`, and `StudentNotificationsSheet`.
   - Absolute ban on browser alerts (`window.alert()`).
4. **Data Privacy & User Safety (RA 10173)**:
   - Security-barrier view enforcement (`public.provider_applicant_profiles`).
   - Demographics masking for minors and sensitive personal info (`birth_date`, `gender`, `phone`, `email`).
   - Strict RLS policies on storage bucket `application_documents`.

---

## 2. Specialist Audit Scopes & Assignments

| Role | Worktree | Branch | Primary Audit Focus | Report Deliverable |
| :--- | :--- | :--- | :--- | :--- |
| 🔨 **Builder** | `.../cowrie` | `ai/builder` | Database transaction persistence, atomic status machine, repository error handling, zero synthetic fallbacks | `docs/reports/2026-10-19_increment3_builder_report.md` |
| 🎨 **UI/UX** | `.../bowhead` | `ai/ui` | Zero browser alerts verification, responsive layouts (360px, 440px, 1280px), Apple HIG craft, optical typography, decision letter & certificate presentation | `docs/reports/2026-10-19_increment3_ui_report.md` |
| 🔍 **QA** | `.../cerith` | `ai/qa` | Automated test suite execution, transaction lifecycle verification, edge case testing (unauthorized submission, premature approval, withdrawal guard), demonstration script audit | `docs/reports/2026-10-19_increment3_qa_report.md` |
| 🛡️ **Security** | `.../fusilier` | `ai/security` | Supabase RLS policies (0023, 0024, 0025), RBAC separation between reviewer and org_admin, RA 10173 privacy barrier verification, storage document isolation | `docs/reports/2026-10-19_increment3_security_report.md` |

---

## 3. Strict Operating Rules During Audit

1. **READ-ONLY on Remote Database**:
   - Specialists must NOT insert, update, or delete records in the live Supabase production project.
   - Do NOT submit live applications, upload documents, endorse, or approve test records during this audit.
   - All tests must use local test suites, mocked data sources, or read-only REST inspection.
2. **File Scope Enforcement**:
   - Specialists must ONLY modify files permitted within their assigned task cards.
   - No cross-worktree file collisions.
3. **Evidence Over Confidence**:
   - No assumptions or claims without concrete command outputs and test execution logs.
   - All findings must report exact command, exit code, and inspected lines.

---

## 4. Execution Sequence & Lifecycle

1. **Phase 1 (Current)**: Architect writes master plan and 4 task cards -> **HALT for Human Approval**.
2. **Phase 2**: User sends 1-line triggers to each worktree:
   - `cowrie`: `> execute assigned task`
   - `bowhead`: `> execute assigned task`
   - `cerith`: `> execute assigned task`
   - `fusilier`: `> execute assigned task`
3. **Phase 3**: Architect schedules automated Git polling every 2 minutes for all 4 reports.
4. **Phase 4**: Architect consolidates reports, reviews diffs, and synthesizes `2026-10-19_increment3_FINAL_REPORT.md`.
5. **Phase 5**: Remediation loop triggered if any defect or privacy leak is discovered.
6. **Phase 6**: Final presentation briefing and live demonstration readiness sign-off delivered to user.
