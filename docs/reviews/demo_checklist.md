# Manual Presentation Demo Checklist: November 4–6, 2026 Checking

**Target Milestone**: Verified System Readiness for Formal Evaluation (November 4, 5, and 6, 2026)  
**Evaluators**: 
- **Mr. Ian Celmar A. Avila, MIT** (App Dev Program Chair) — 4th Increment & Full Demo Cycle  
- **Mr. Roel Daniot, MSIT** (IT Security Instructor) — IAS 1 Final Project Security Requirements  
**Student**: Gilbert Bulado (No. 44)  
**Repository Branch**: `fix/touch-targets-oct02` (Canonical workspace `C:\scholaris`)  
**Document Owner**: 🔍 QA Specialist (`cerith` Session)  
**Date Generated**: October 25, 2026  

---

> [!IMPORTANT]
> ### Crucial Verification & Evidence Notice
> **Headless unit and widget tests do NOT establish that the complete live demo flow was rehearsed against the real backend.**
> Headless tests render with fixed-width mock fonts (`Ahem`) under synthetic local memory data sources.
> Every item in this checklist is strictly classified into one of two empirical states:
> 1. `[LOCALLY TESTED]`: Verified locally using automated Dart tests, widget testers, or isolated EmbeddedPostgres SQL scripts.
> 2. `[PENDING DEMO BACKEND]`: Requires manual rehearsal against the live Supabase demo project (`yqwbarzxpduzmtrxnrbm.supabase.co`) with authenticated test accounts.
> 3. `[OPEN PREREQUISITE]`: Gate 2 (direct remote PostgreSQL catalog inspection on `yqwbarzxpduzmtrxnrbm`) and Gate 3 (genuine containerized Storage API verification) remain open prerequisites awaiting designated operator execution.
> 4. `[UNRESOLVED]`: IAS Section D3 (CAPTCHA on Continued Failures) remains explicitly unresolved pending working credentials or formal written waiver from Mr. Roel Daniot.

---

## 1. Demo Credentials & Environment Matrix

| Role | Demo Email | Demo Password | Persona & Environment | Status / Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Platform Admin** | `admin@scholaris.edu.ph` | `Scholaris2026!` | Desktop Web (1280×800) • `is_admin() = true` • Full telemetry, provider verification queue (Tab 2), safety oversight (Tab 9) | `[PENDING DEMO BACKEND]` |
| **Org Provider Admin** | `provider.dost@scholaris.gov.ph` | `Scholaris2026!` | Desktop Web (1280×800) • DOST-SEI Org Admin • Incoming application review drawer, scholarship posting | `[PENDING DEMO BACKEND]` |
| **Org Reviewer / Staff** | *(To be provisioned if multi-actor cycle)* | `Scholaris2026!` | Desktop Web (1280×800) • DOST-SEI Academic Committee Reviewer | `[PENDING DEMO BACKEND]` |
| **Student (Applicant)** | `student.demo@scholaris.edu.ph` | `Scholaris2026!` | Mobile Viewport (360×800 / 440×956) • BS CS 3rd Year • GWA 1.24 • Income ₱15,000 | `[PENDING DEMO BACKEND]` |

### Pre-Demo State Cleanliness
1. To reset student demo state to zero applications and notifications:
   `SELECT public.reset_demo_student();` (executed in Supabase SQL Editor by designated operator).
2. Ensure `public.organization_memberships` contains an active `org_admin` record for `provider.dost@scholaris.gov.ph` under DOST-SEI.

---

## 2. Part I: App Dev 4th Increment Presentation Sequence (Mr. Avila)

This sequence exercises the primary end-to-end scholarship lifecycle in 7 distinct operational steps.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        APP DEV 4TH INCREMENT DEMO CYCLE (STEPS 1–7)                    │
│                                                                                        │
│  [ Step 1: Provider Signup ] ──► [ Step 2: Admin Approval ] ──► [ Step 3: Post Grant ] │
│                                                                        │               │
│  [ Step 6: Decision Letter ] ◄── [ Step 5: Provider Review ] ◄── [ Step 4: Apply ]     │
│             │                                                                          │
│             ▼                                                                          │
│  [ Step 7: Safety & Support Concerns Oversight (Tab 9) ]                               │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

| Step & Action | Screen / Endpoint | Expected Presentation Behavior | Verification Evidence Status | Live Demo Rehearsal Check |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Provider Registration** | `ProviderSignupScreen`<br>`/provider-signup` | • Toggle between **Organization** and **Individual Provider** cards.<br>• Fill organization name, SEC registration number, tax ID, and contact details.<br>• Dynamic password complexity checklist validates in real time.<br>• Upload document (PDF/PNG SEC Certificate).<br>• Submits to `public.provider_verifications` with status `'pending'`. | `[LOCALLY TESTED]`<br>`individual_provider_flow_test.dart` (Passed)<br>`provider_large_text_test.dart` (Passed) | [ ] Unchecked<br>*(Verify live signup against remote Supabase)* |
| **Step 2: Admin Verification & Approval** | `AdminHomeScreen`<br>`AdminProvidersTab` (Tab Index 2) | • Admin logs in at `/admin-login` and lands on `/admin-home`.<br>• Switches to **Tab 2 (Providers)**.<br>• Sees pending verification request in the review queue.<br>• Reviews uploaded SEC certificate and provider details.<br>• Clicks **Approve Provider** (invokes RPC `review_provider_verification`).<br>• Audit trail logs approval event atomically; provider status updates to `'approved'`. | `[LOCALLY TESTED]`<br>`admin_home_screen_test.dart` (13/13 passed)<br>`test_provider_review_security.mjs` (Passed) | [ ] Unchecked<br>*(Verify live RPC execution and state update)* |
| **Step 3: Scholarship Posting** | `OrgScholarshipsTab`<br>`ScholarshipFormScreen` | • Provider logs into `/provider-home`.<br>• Verification banner displays "Verified Organization".<br>• Opens "Create Scholarship" form.<br>• Configures grant title, monetary award, deadline, and capacity limit (e.g. `slots = 10`).<br>• Publishes scholarship; record appears in live active scholarship directory. | `[LOCALLY TESTED]`<br>`scholarship_repository_test.dart` (Passed) | [ ] Unchecked<br>*(Verify live insert to `scholarships`)* |
| **Step 4: Student Discovery & Application** | `DiscoverScreen`<br>`ApplicationDetailScreen` | • Student logs into mobile interface.<br>• Navigates to **Discover**; browses grants with real-time match breakdown.<br>• Selects the DOST grant; reviews eligibility criteria.<br>• Submits application packet (academic transcript, household income proof, statement).<br>• Application transitions from `'draft'` to `'submitted'`. | `[LOCALLY TESTED]`<br>`discovery_widget_test.dart` (Passed)<br>`application_workflow_transport_test.dart` (Passed) | [ ] Unchecked<br>*(Verify live packet submission & RLS)* |
| **Step 5: Provider Committee Decision** | `OrgIncomingApplicationsTab`<br>`ApplicantReviewDrawer` | • Provider opens incoming applications queue.<br>• Opens Applicant Review Drawer.<br>• RA 10173 Privacy View: sensitive fields (`birth_date`, `phone`, `gender`) are hidden.<br>• Committee Reviewer scores 4 rubric sliders and endorses (`'submitted'` $\rightarrow$ `'under_review'`).<br>• Org Admin approves final award (`'under_review'` $\rightarrow$ `'approved'`).<br>• Slot counter decrements atomically (1 slot reserved). | `[LOCALLY TESTED]`<br>`test_provider_review_concurrency.mjs` (100% passed)<br>`test_individual_provider_security.mjs` (Passed) | [ ] Unchecked<br>*(Verify live transaction cycle)* |
| **Step 6: Student Decision Result Letter** | `ApplicationDecisionLetter`<br>`/application/:id/decision` | • Student receives real-time in-app notification.<br>• Status badge updates to "Approved / Awarded".<br>• Taps notification to open official Decision Letter.<br>• Displays formal grant confirmation letter, provider badge, and next-step onboarding checklist. | `[LOCALLY TESTED]`<br>`application_decision_letter_test.dart` (9/9 passed) | [ ] Unchecked<br>*(Verify live notification receipt & letter)* |
| **Step 7: Safety Reporting & Concerns Oversight** | `StudentSafetyReportDialog`<br>`AdminHomeScreen` (Tab Index 9) | • Student submits safety/harassment complaint via floating safety action.<br>• Attaches private PNG/PDF evidence (guarded by advisory transaction lock).<br>• Admin navigates to **Tab 9 (Safety Reports)**.<br>• Audits complaint details, timestamp, and downloaded evidence.<br>• Confirms providers have zero visibility into private student complaints. | `[LOCALLY TESTED]`<br>`test_genuine_storage_api_plan.mjs` (4/4 passed)<br>`test_student_safety_security.mjs` (Passed)<br>`admin_reports_safety_ui_test.dart` (Passed) | [ ] Unchecked<br>*(Verify live storage upload & Admin Tab 9)* |

---

## 3. Part II: IAS 1 Final Project Security Requirements (Mr. Daniot)

This checklist covers all 8 security sections (Sections A through H) of the Information Assurance & Security curriculum.

### Section A: Database Relationships & Account Architecture
| Item | Requirement & Implementation | Expected Demo Evidence | Classification | Live Check |
| :--- | :--- | :--- | :---: | :---: |
| **A1** | **Relational Integrity & Unique Accounts**: Foreign keys link `profiles`, `applications`, `scholarships`, `audit_logs`. `profiles.email` has unique constraint. | Show ER diagram and PostgreSQL table definitions in migration `0001`–`0026`. Show duplicate email rejection on signup. | `[LOCALLY TESTED]` / `[PROVISIONAL]` | [ ] Unchecked |
| **A2** | **Login Page with Show/Hide & Forgot Password**: `LoginScreen` includes show/hide password toggle and "Forgot Password" link. | Toggle eye icon in password field to reveal plaintext; tap "Forgot Password" to reach reset flow. | `[LOCALLY TESTED]`<br>`ias_security_test.dart` | [ ] Unchecked |
| **A3** | **Admin User Management**: Admin can search users, filter by role, activate/deactivate accounts. | Open `PlatformOverviewScreen` / `AdminUsersTab`; search student by email; demonstrate role badge and lock status. | `[LOCALLY TESTED]`<br>`admin_home_screen_test.dart` | [ ] Unchecked |
| **A4** | **Role-Based Separation**: Student `/home`, Provider `/provider-home`, Admin `/admin-home`. | Attempt to load `/admin-home` as student; verify redirect gate fails closed to authorized destination. | `[LOCALLY TESTED]`<br>`router.dart` redirect tests | [ ] Unchecked |

### Section B: OTP Verification & Password Recovery
| Item | Requirement & Implementation | Expected Demo Evidence | Classification | Live Check |
| :--- | :--- | :--- | :---: | :---: |
| **B1** | **OTP Verification on Signup & Recovery**: 8-digit verification code sent via Supabase Auth email. | Complete signup; demonstrate OTP entry screen (`VerifyEmailScreen`) requiring 8-digit token before activation. | `[PROVISIONAL]`<br>(Supabase Auth engine) | [ ] Unchecked |
| **B2** | **OTP Expiry, Cooldown & Attempt Limiting**: 60-second client resend cooldown timer and server-side token expiration. | Attempt immediate resend; observe disabled button and 60s countdown timer. | `[LOCALLY TESTED]`<br>`verify_email_screen.dart` | [ ] Unchecked |
| **B3** | **Working Password Recovery & Deep Links**: Password reset email dispatches deep link `scholaris://reset-password`. | Submit reset request; receive email; open reset URL; confirm `ResetPasswordScreen` accepts new password. | `[LOCALLY TESTED]`<br>`ias_security_test.dart` | [ ] Unchecked |

### Section C: Password Security & Storage
| Item | Requirement & Implementation | Expected Demo Evidence | Classification | Live Check |
| :--- | :--- | :--- | :---: | :---: |
| **C1** | **Password Complexity Validation**: Minimum 8 characters, at least 1 uppercase, 1 lowercase, 1 number, 1 special character. | Enter weak passwords (short, all-lowercase, no special char); verify validator rejects each with specific guidance. | `[LOCALLY TESTED]`<br>`ias_security_test.dart` (Passed) | [ ] Unchecked |
| **C2** | **Dynamic Password Meter**: Visual checklist badges that update color in real time as criteria are satisfied. | Type password interactively; observe 4 requirement badges dynamically turn green. | `[LOCALLY TESTED]`<br>`SignupScreen` widget tests | [ ] Unchecked |
| **C3** | **Secure Password Hashing**: Passwords hashed using bcrypt/Argon2 by Supabase Auth; never stored in plaintext. | Inspect `public.profiles` schema: verify password column does not exist (handled solely by `auth.users`). | `[LOCALLY TESTED]`<br>Schema inspection | [ ] Unchecked |
| **C4** | **Session Invalidation on Password Change**: Invalidate existing sessions across other devices when password is changed. | Execute password change in account settings or recovery; demonstrate `signOut(scope: SignOutScope.others)` wire call and non-fatal revocation handling. | `[LOCALLY TESTED]` / `[PENDING LIVE INVALIDATION]`<br>(Local request sequencing verified; live session invalidation pending) | [ ] Unchecked |

### Section D: Login Protection & Account Lockout
| Item | Requirement & Implementation | Expected Demo Evidence | Classification | Live Check |
| :--- | :--- | :--- | :--- | :---: |
| **D1** | **3 Failed Attempts Allowed**: Warning banner displayed after 1st and 2nd failed login attempts. | Enter wrong password twice; observe warning banner: "Invalid credentials. Attempt X of 3". | `[LOCALLY TESTED]`<br>`ias_security_test.dart` (Passed) | [ ] Unchecked |
| **D2** | **Progressive Lockout Backoff**: 3 attempts = 5 min, 4 attempts = 15 min, 5+ attempts = 60 min. | Trigger 3rd failed attempt; observe "Account Locked" banner and countdown timer; submit button disabled. | `[LOCALLY TESTED]`<br>`LoginLockoutService` tests | [ ] Unchecked |
| **D3** | **CAPTCHA on Continued Failures**: Challenge mechanism upon repeated lockouts. | Document cross-platform CAPTCHA options (Turnstile/hCaptcha on Web vs Mobile Webview) and evaluation trade-offs. | `[UNRESOLVED]`<br>(Pending active implementation or formal waiver from Mr. Daniot) | [ ] Unchecked |
| **D4** | **Reset on Success & Persistence Across Restart**: Successful login resets counter; lockout persists in `SharedPreferences`. | Log in successfully; counter resets to 0. Lock account, restart app; verify lockout countdown remains active. | `[LOCALLY TESTED]`<br>`ias_security_test.dart` (Passed) | [ ] Unchecked |

### Section E: Session Management & Inactivity
| Item | Requirement & Implementation | Expected Demo Evidence | Classification | Live Check |
| :--- | :--- | :--- | :---: | :---: |
| **E1** | **Secure Session Creation & End on Logout**: JWT storage in tab session storage; tokens purged on logout. | Log out via `LogoutConfirmationDialog`; verify tokens removed from `sessionStorage` and user redirected to `/`. | `[LOCALLY TESTED]`<br>`logout_confirmation_dialog_test.dart` | [ ] Unchecked |
| **E2** | **Multi-Tab Isolation & Logout Behavior**: `TabScopedLocalStorage` isolates tokens; tab-scoped `BroadcastChannel` prevents cross-tab login interference. Same-account cross-tab logout synchronization and different-account isolation verified in multi-tab test harness (`test/cross_tab_logout_test.dart`). | Open Tab 1 as Org Admin and Tab 2 as Org Staff in same Chrome window. Observe independent sessions. Verify live decoupled or synchronized logout across demo tabs. | `[LOCALLY TESTED]` / `[PENDING DEMO BACKEND]`<br>(Local multi-tab simulation passed 10/10; live multi-tab Chrome rehearsal pending remote Supabase) | [ ] Unchecked |
| **E3** | **15-Minute Inactivity Auto-Logout**: Inactivity timer tracks pointer and keyboard events; displays pre-logout warning. | Demonstrate session inactivity detection and warning modal structure. | `[PROVISIONAL]`<br>`inactivity_service.dart` | [ ] Unchecked |

### Section F: Audit Trail & Compliance Logging
| Item | Requirement & Implementation | Expected Demo Evidence | Classification | Live Check |
| :--- | :--- | :--- | :---: | :---: |
| **F1** | **Immutable Audit Ledger**: `public.audit_logs` records logins, admin reviews, approvals, and role updates. | Execute provider approval; verify corresponding event appended to `audit_logs` table. RLS blocks `UPDATE`/`DELETE`. | `[LOCALLY TESTED]`<br>`test_provider_review_security.mjs` | [ ] Unchecked |
| **F2** | **Structured Log Schema**: Schema captures `user_id`, `action`, `resource`, `details`, `ip_address`, `created_at`. | Query `audit_logs` table; inspect JSONB `details` payload structure. | `[LOCALLY TESTED]`<br>Migration `0011` schema | [ ] Unchecked |
| **F3** | **Admin Audit View & Filtering**: Admin can view and filter audit logs; cannot edit or delete logs from UI. | Open `AuditTrailScreen` in Admin Portal; filter logs by action type; verify zero delete/edit buttons exist. | `[LOCALLY TESTED]`<br>`admin_audit_logs_tab_test.dart` | [ ] Unchecked |
| **F4** | **Sensitive Data Exclusion**: Passwords, OTP codes, and plain secrets are strictly excluded from audit payloads. | Inspect `record_audit_log` triggers and `LoginLockoutService`: confirm passwords and OTPs are scrubbed. | `[LOCALLY TESTED]`<br>`test_security_report.md` audit | [ ] Unchecked |

### Section G: Input Validation & Sanitization
| Item | Requirement & Implementation | Expected Demo Evidence | Classification | Live Check |
| :--- | :--- | :--- | :---: | :---: |
| **G1** | **Dual Client & Server Validation**: Client form validation mirrors PostgreSQL CHECK constraints and regex. | Attempt client bypass or invalid field entry (e.g. invalid GPA or email); verify server CHECK constraint halts write. | `[LOCALLY TESTED]`<br>Dart `validators.dart` + SQL DDL | [ ] Unchecked |
| **G2** | **Parameterized Queries & Action Confirmations**: PostgREST parameterized calls prevent SQL injection; destructive actions prompt confirmation dialog. | Review PostgREST REST query binding. Trigger scholarship deletion or logout; observe confirmation dialog. | `[LOCALLY TESTED]`<br>`logout_confirmation_dialog_test.dart` | [ ] Unchecked |
| **G3** | **Administrative Event Auditing**: Privileged admin actions call `record_audit_log` RPC atomically. | Approve provider; show atomic transaction guarantees audit entry is written alongside status change. | `[LOCALLY TESTED]`<br>`test_provider_review_security.mjs` | [ ] Unchecked |

### Section H: Backup & Disaster Recovery
| Item | Requirement & Implementation | Expected Demo Evidence | Classification | Live Check |
| :--- | :--- | :--- | :---: | :---: |
| **H1** | **Scheduled Database Backups**: Automated daily snapshots managed on the Supabase platform. | Review backup policy documentation and disaster recovery runbook. | `[PROVISIONAL]`<br>(Supabase platform) | [ ] Unchecked |
| **H2** | **Secure Offline Backup Storage**: Procedure for exporting encrypted database dumps to secure offline storage. | Document offline archive procedure and schema export commands in `docs/reviews/authoritative-runbook`. | `[PROVISIONAL]`<br>(Documentation verified) | [ ] Unchecked |
| **H3** | **Administrator Restore Capability**: Step-by-step restoration script using `psql` / `pg_restore`. | Demonstrate local schema rebuild via `EmbeddedPostgres` in `deploy_orchestrator.mjs` as local restore proof. | `[LOCALLY TESTED]`<br>`deploy_orchestrator.mjs` (Passed) | [ ] Unchecked |

---

## 4. Rehearsal Sign-Off Ledger

| Role | Reviewer Name | Signature / Status | Date |
| :--- | :--- | :--- | :--- |
| **Student Presenter** | Gilbert Bulado (#44) | [ ] Pending Live Rehearsal | Nov 2026 |
| **QA Specialist** | `cerith` Session | **VERIFIED CHECKLIST STRUCTURE** (`[LOCALLY TESTED]` vs `[PENDING DEMO BACKEND]`) | Oct 25, 2026 |
| **Coordinator / Architect** | `Archi` Session | [ ] Pending Consolidation | Oct 25, 2026 |
