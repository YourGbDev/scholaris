# 3rd Increment Checking: Live Demo Script & Verification Guide

**Project:** Scholaris — Intelligent Student-Scholarship Matching & Provider Ecosystem  
**Course / Milestone:** Application Development — 3rd Increment Checking (End-to-End Transaction Cycle)  
**Date:** October 15, 2026  
**Author:** 🔍 QA Specialist (`cerith` / `ai/qa`)  
**Status:** `STATUS: VERIFIED & READY FOR EVALUATION`

---

## 1. Executive Summary & Grading Alignment

The 3rd Increment Checking requires demonstrating a **complete, closed-loop transaction cycle** across multiple roles (Student -> Provider -> Student) backed by real Supabase database persistence.

This guide provides instructors and evaluators with:
1. **Chronological 3-Act Demo Script**: Click-by-click instructions from initial application submission to institutional committee rubric scoring and student award celebration.
2. **Direct Supabase SQL Verification**: Concrete SQL queries to inspect all mutated tables (`applications`, `application_evaluations`, `application_status_history`, and `notifications`).
3. **Strict System UI Compliance**: Audit confirming **zero** browser `window.alert` popups ("localhost says"), zero raw crashes, and consistent branded feedback (`ScholarisSnackBar`, Apple HIG modals, animated celebrations).
4. **Data Privacy (RA 10173) & RLS Isolation Proof**: Multi-tenant database boundary verification guaranteeing providers only access applicants to their own scholarships without leaking unselected applicant data.

---

## 2. Test Account Matrix

Use the following pre-configured credentials or create new accounts with these attributes:

| Role | Username / Email | Password | Pre-Conditions & Attributes |
| :--- | :--- | :--- | :--- |
| **Student** (Applicant) | `student.demo@scholaris.edu.ph` | `Scholaris2026!` | • University: *University of the Philippines Diliman*<br>• Course: *BS Computer Science*<br>• Year Level: *3rd Year*<br>• GWA: *1.24* (Philippine Scale)<br>• Monthly Household Income: *₱15,000*<br>• Avatar / Identity Photo: *Configured* |
| **Provider** (DOST Reviewer) | `provider.dost@scholaris.gov.ph` | `Scholaris2026!` | • Organization: *DOST-SEI (Science Education Institute)*<br>• Role: *Scholarship Committee Reviewer*<br>• Owned Scholarship: *DOST-SEI Undergraduate Scholarship* |
| **Admin** (Telemetry/Oversight) | `admin@scholaris.edu.ph` | `Scholaris2026!` | • Platform Administrator with `is_admin() = true`<br>• Global analytics & audit log visibility |

> [!NOTE]
> If testing on an ephemeral local instance or reset database, log in as `student.demo@scholaris.edu.ph` and complete the 4-step Profile Setup screen once to ensure `setup_complete: true` and avatar selection are stored.

---

## 3. End-to-End Live Demo Script

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                 THE TRANSACTION CYCLE                                  │
│                                                                                        │
│   [ ACT 1: Student ]          [ ACT 2: Provider ]             [ ACT 3: Student ]       │
│  ┌──────────────────┐       ┌──────────────────────┐        ┌──────────────────────┐   │
│  │ Discover Grant   │       │ Incoming Apps Queue  │        │ Notification Center  │   │
│  │ Match Breakdown  │ ───►  │ 4 Rubric Sliders     │  ───►  │ Approved Status      │   │
│  │ 3-Step Review    │       │ Approve Award        │        │ 🎉 Award Ceremony    │   │
│  │ Submit App       │       │ DB Audit Trail       │        │ Package Confirmation │   │
│  └──────────────────┘       └──────────────────────┘        └──────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### ACT 1: Student Application Submission

#### Objective
Demonstrate that a student discovers an eligible scholarship, reviews institutional requirements, agrees to Data Privacy stipulations, digitally signs, and submits their application into the database.

#### Step-by-Step Click Path
1. **Sign In**:
   - Navigate to `/login`.
   - Enter `student.demo@scholaris.edu.ph` and `Scholaris2026!`. Tap **"Sign In"**.
   - Student lands on the **Home Dashboard** (`/home`).
2. **Navigate to Discover**:
   - Tap the **"Discover"** tab in the bottom navigation bar (`/discover`).
3. **Select Scholarship**:
   - Locate **"DOST-SEI Undergraduate Scholarship"** (or use the search bar: type `DOST`).
   - Tap the scholarship card. The **Scholarship Detail Screen** (`/scholarship/:id`) opens with hero banner and deadline indicators.
4. **Evaluate Matching Power & Eligibility**:
   - Scroll down to the **"Your Eligibility Breakdown"** card.
   - Observe live match criteria:
     - Academic GWA: `1.24` (Meets requirement `2.00` or higher) — *Green check*.
     - Degree Program: `BS Computer Science` (Priority STEM field) — *Green check*.
     - Overall Matching Power: `94% Match`.
5. **Initiate Application**:
   - Tap the primary action button: **"Start Application"**.
   - The 3-step **Application Review Sheet** opens:
     - **Step 1 (Academic Track & Personal Statement)**: Verify prepopulated course and GWA. Type or inspect the statement text:
       `"Aspiring software engineer dedicated to building open-source civic technology for Philippine local communities."`
     - **Step 2 (Data Privacy & Certifications)**: Check the boxes for:
       - *[✓] I certify that all information submitted is true and correct.*
       - *[✓] I consent to RA 10173 data processing for institutional grant evaluation.*
     - **Step 3 (Digital Signature)**: Type student name `Juan Dela Cruz` in the signature confirmation box.
6. **Submit**:
   - Tap **"Submit Application"**.
   - **Visual Feedback**: The button enters a progress spinner state to prevent duplicate submissions, followed by a branded green `ScholarisSnackBar`:
     > *"Application submitted successfully! Your submission has been transmitted to DOST-SEI."*
   - Student is returned to the detail screen where the action button now reflects **"Application Submitted"** (disabled).

#### Supabase Database Verification (Act 1)
Run in the Supabase SQL Editor:
```sql
-- Query 1: Verify submitted application row
SELECT 
    id AS application_id,
    user_id,
    scholarship_id,
    status,
    applied_at,
    notes
FROM public.applications
WHERE status = 'submitted'
ORDER BY applied_at DESC 
LIMIT 1;
```
**Expected Result**:
- `status`: `'submitted'`
- `notes`: Contains the submitted statement text
- `applied_at`: Recent timestamp within current minute

---

### ACT 2: Provider Deliberation & Rubric Scoring

#### Objective
Demonstrate that the institutional committee reviewer accesses their console, reviews the applicant's scoped academic profile, adjusts weighted rubric sliders, enters committee deliberation notes, and executes the formal approval transaction.

#### Step-by-Step Click Path
1. **Switch to Provider Account**:
   - Sign out of the student session or open a separate browser profile/incognito window.
   - Navigate to `/provider-login` (or select Provider mode).
   - Enter `provider.dost@scholaris.gov.ph` and `Scholaris2026!`. Tap **"Sign In"**.
   - Provider lands on the **Provider Console** (`/provider-home`).
2. **Access Incoming Applications Queue**:
   - Tap the **"Incoming Applications"** tab.
   - Observe the applicant queue showing `Juan Dela Cruz` under **DOST-SEI Undergraduate Scholarship** with status pill `"SUBMITTED"`.
3. **Open Applicant Review Drawer**:
   - Tap **"Review Application"** (or tap the applicant row).
   - The **Institutional Applicant Review Drawer** smoothly animates from the right/bottom:
     - Scoped profile shows: GWA `1.24`, `BS Computer Science`, `UP Diliman`, Family Income `₱15,000`.
     - Sensitive personal contact info (e.g. mobile number, home address) remains hidden in accordance with Philippine RA 10173.
4. **Operate the 4-Criteria Rubric Sliders**:
   - Under **"PROVIDER SCORING RUBRIC"**, adjust the sliders:
     - **Academic Excellence (Weight: 40%)**: Drag to `95.0`
     - **Financial Need & Context (Weight: 30%)**: Drag to `88.0`
     - **Leadership & Community (Weight: 20%)**: Drag to `92.0`
     - **Innovation Essay & Vision (Weight: 10%)**: Drag to `90.0`
   - Observe the live **Composite Score Pill** dynamically update to:
     $$\text{Composite} = (95.0 \times 0.40) + (88.0 \times 0.30) + (92.0 \times 0.20) + (90.0 \times 0.10) = 91.80 / 100$$
5. **Record Deliberation Remarks**:
   - In the **"Deliberation Remarks & Committee Notes"** field, input:
     `"Unanimous committee approval. Candidate demonstrates outstanding academic consistency and impactful community involvement in STEM literacy."`
6. **Execute Award Decision**:
   - **Reviewer Endorsement Path**: When evaluating as a Reviewer/Evaluator, tap **"Endorse to Org Admin for Decision"** and confirm. The application transitions to `under_review` with persisted rubric scores and reviewer ID.
   - **Org Admin Decision Path**: When evaluating as Org Admin (or single-provider mode), tap **"Approve Award"**.
   - An Apple HIG-styled confirmation dialog appears:
     - Title: *"Confirm Grant Award"*
     - Message: *"Approve Juan Dela Cruz for the DOST-SEI Undergraduate Scholarship with composite score 91.8/100?"*
     - Buttons: *"Cancel"* / *"Confirm Approval"*
   - Tap **"Confirm Approval"**.
   - **Visual Feedback**: The drawer shows a brief saving state, emits haptic feedback, closes cleanly, and displays a success toast:
     > *"Application #app-... approved! Rubric evaluation and student notification recorded."*
   - The applicant's badge in the table immediately updates to green `"APPROVED"`.

#### Supabase Database Verification (Act 2)
Run in the Supabase SQL Editor:
```sql
-- Query 2A: Verify Application Status Transition
SELECT id, user_id, scholarship_id, status, updated_at
FROM public.applications
WHERE status = 'approved'
ORDER BY updated_at DESC
LIMIT 1;

-- Query 2B: Verify Rubric Scores & Deliberation Notes Persistence
SELECT 
    id,
    application_id,
    reviewer_id,
    score_academic,
    score_financial,
    score_leadership,
    score_vision,
    composite_score,
    decision,
    deliberation_notes,
    created_at
FROM public.application_evaluations
ORDER BY created_at DESC
LIMIT 1;

-- Query 2C: Verify Status Audit Trail History Record
SELECT 
    id,
    application_id,
    changed_by,
    from_status,
    to_status,
    remarks,
    created_at
FROM public.application_status_history
ORDER BY created_at DESC
LIMIT 1;

-- Query 2D: Verify In-App Notification Generated for Student
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    is_read,
    created_at
FROM public.notifications
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Query Outputs**:
| Table | Column | Expected Value |
| :--- | :--- | :--- |
| `applications` | `status` | `'approved'` |
| `application_evaluations` | `composite_score` | `91.80` |
| `application_evaluations` | `score_academic` | `95.00` |
| `application_evaluations` | `decision` | `'approved'` |
| `application_evaluations` | `deliberation_notes` | Matches committee note entered |
| `application_status_history` | `from_status` $\to$ `to_status` | `'submitted'` $\to$ `'approved'` |
| `notifications` | `title` | `'Application Approved!'` |
| `notifications` | `is_read` | `false` |

---

### ACT 3: Student Confirmation & Award Ceremony Celebration

#### Objective
Demonstrate that the student receives the real-time notification, views their updated status, and triggers the animated Award Ceremony celebration flow.

#### Step-by-Step Click Path
1. **Switch Back to Student Session**:
   - Reopen student session or sign back in as `student.demo@scholaris.edu.ph`.
   - On the Home Dashboard (`/home`), notice the **Notification Bell** in the top navigation bar with an active unread indicator badge.
2. **Open Notification Center**:
   - Tap the **Notification Bell** icon.
   - The **Notifications Sheet** slides up, displaying:
     - Celebratory Trophy Icon 🏆
     - Title: **"Application Approved!"**
     - Message: *"Congratulations! Your application for DOST-SEI Undergraduate Scholarship has been approved."*
     - Timestamp: *"Just now"*
3. **Navigate to Application Detail**:
   - Tap the notification card (or navigate via bottom bar: **"Applications"** tab -> tap DOST card).
   - The **Application Detail Screen** loads with active award state:
     - Header Badge: **"Approved"** in vibrant emerald green.
     - Review Summary Card: Displays the committee decision date and verified match breakdown.
4. **Trigger Award Celebration & View Decision Letter**:
   - Locate the prominent celebration card:
     > **"Congratulations! Your Grant is Approved"**  
     > *"You have officially been selected as a DOST-SEI scholar for Academic Year 2026-2027."*
   - Tap **"🎉 View Award Ceremony & Package"**:
     - Mounts the official **Scholarship Approval Letter & Award Certificate** (`ApplicationDecisionLetter`):
       - Official institutional header with reference UUID (`APP-...`).
       - Addressed to applicant: `Juan Dela Cruz`.
       - Organization signatory: `DOST-SEI`.
       - Verified approval date stamp and institutional grant allocation terms.
       - Clean navigation back stack restoring application detail without state reset.
5. **Experience the Ceremony Screen Celebration**:
   - The app transitions into the full-screen **CeremonyScreen**:
     - Physics-based confetti cascade animation.
     - Animated graduation cap and celebratory scholarship banner.
     - Personalized congratulatory message: *"Grant Award Confirmed! Welcome to the DOST-SEI Scholars Circle."*
     - Clear breakdown of monetary grant terms (₱70,000/yr tuition + monthly stipend).
   - Tap the top-right **Close (✕)** or **"Return to Dashboard"** button:
     - Smoothly returns student to their application dashboard without re-prompting or losing navigation context.

---

## 4. Strict UI & Defensive UX Verification Checklist

Every action along the transaction cycle conforms to Scholaris's verified UI guidelines:

- [x] **Zero Browser Alerts**: No `window.alert`, `window.confirm`, or `"localhost says"` popups appear anywhere in the flow.
- [x] **Zero Raw Stack Traces**: All network and database operations use localized error handling with human-readable messaging.
- [x] **Branded Feedback**:
  - Success events emit emerald green `ScholarisSnackBar` with smooth entry/exit animations.
  - Critical actions (Award Approval, Rejection) require confirmation dialogs with 16dp rounded corners, clear primary actions, and destructive color coding.
- [x] **Apple HIG Ergonomics**:
  - All interactive buttons and sliders maintain touch targets $\ge 44 \times 44$ pt.
  - Rubric sliders provide responsive haptic tick feedback and live text readout.
- [x] **Multi-Viewport Responsiveness**:
  - Evaluated and verified across Narrow Mobile (`360×640`), Standard Smartphone (`440×956` iPhone 16 Pro Max), Tablet (`768×1024`), and Desktop (`1280×800`).
  - Defensive flex wrappers (`Flexible`, `Expanded`, `TextOverflow.ellipsis`) prevent all `RenderFlex` overflow errors.

---

## 5. Security & RA 10173 Multi-Tenant Isolation Proof

| Check # | Security Boundary | Enforcement Mechanism | Verification Result |
| :---: | :--- | :--- | :---: |
| **S-1** | Student cannot apply to other students' IDs | `auth.uid() = user_id` in RLS policy `0001` | **PASS**: Repository derives user from session |
| **S-2** | Provider cannot see draft/withdrawn applications | RLS policy `0022` (`status NOT IN ('draft', 'withdrawn')`) | **PASS**: Invisible in queue |
| **S-3** | Provider cannot see other providers' applicants | RLS policy `0005` & `0022` (`scholarships.created_by = auth.uid()`) | **PASS**: Multi-tenant isolation verified |
| **S-4** | Sensitive student personal data hidden from review | `public.provider_applicant_profiles` view (`0020`) strips birth date, phone, and home address | **PASS**: RA 10173 compliant |
| **S-5** | Terminal status protection prevents student withdrawal | Repository guard: `ApplicationStatus.approved.isPending == false` throws `ApplicationWithdrawalException` | **PASS**: Locked upon approval |

---

## 6. Automated Test Suite Execution

To execute the automated regression and transaction cycle verification suite:

```bash
flutter test test/features/applications/transaction_cycle_test.dart
```

### Execution Output
```
00:00 +0: loading test/features/applications/transaction_cycle_test.dart
00:00 +0: 3rd Increment Checking: Full Transaction Cycle Verification Act 1: Student Application Submission Student successfully submits application and row is persisted
00:00 +1: 3rd Increment Checking: Full Transaction Cycle Verification Act 1: Student Application Submission Enforces duplicate submission prevention for same student and scholarship
00:00 +2: 3rd Increment Checking: Full Transaction Cycle Verification Act 1: Student Application Submission Student can save draft and promote draft to submitted
00:00 +3: 3rd Increment Checking: Full Transaction Cycle Verification Act 2: Provider Deliberation, Rubric Scoring & Award Decision Calculates 4-criteria composite score correctly per institutional weighting
00:00 +4: 3rd Increment Checking: Full Transaction Cycle Verification Act 2: Provider Deliberation, Rubric Scoring & Award Decision Composite calculation respects boundary conditions (0% and 100%)
00:00 +5: 3rd Increment Checking: Full Transaction Cycle Verification Act 2: Provider Deliberation, Rubric Scoring & Award Decision Provider reviews submission, saves rubric evaluation, updates status, and logs history
00:00 +6: 3rd Increment Checking: Full Transaction Cycle Verification Act 3: Student Confirmation & Award Ceremony Celebration Student receives notification, views approved status, and terminal lock prevents withdrawal
00:00 +7: 3rd Increment Checking: Full Transaction Cycle Verification Act 3: Student Confirmation & Award Ceremony Celebration Admin confirms award from approved state
00:00 +8: All tests passed!
```

---

## 7. Instructor Quick Reference Card

If the instructor asks:
1. *"Show me the database tables mutated in this cycle."*  
   $\to$ Open Supabase Studio -> Tables:
   - `public.applications` (row status changed from `submitted` to `approved`)
   - `public.application_evaluations` (holds 4 criteria scores, composite score, and deliberation text)
   - `public.application_status_history` (audit trail of who changed status and when)
   - `public.notifications` (student notification record)
2. *"Can a student submit twice to the same scholarship?"*  
   $\to$ No. The UI disables the button, and `ApplicationRepository.apply` checks existing rows and throws `ApplicationDuplicateException`.
3. *"Does the rubric slider persist to the database?"*  
   $\to$ Yes. Evaluator scores are saved to `public.application_evaluations` with composite calculation $\sum (\text{score}_i \times \text{weight}_i)$.
4. *"Can an approved student cancel or withdraw their award?"*  
   $\to$ No. Approved/awarded applications are in terminal state and cannot be withdrawn.
