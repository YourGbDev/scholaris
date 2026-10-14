# Task Card: Security (`fusilier` / `ai/security`)

**Sprint:** 3rd Increment Checking (End-to-End Transaction Cycle)  
**Role:** 🛡️ RLS Policies, Auth & Multi-tenant Isolation Specialist  
**Reference Plan:** `docs/plans/2026-10-15_3rd_increment_transaction_cycle_plan.md`  
**Status:** `READY FOR IMPLEMENTATION`

---

## 1. Objective
1. Review and verify that Row-Level Security (RLS) policies (especially migrations 0001, 0006, 0009, 0020, 0022) do **NOT** block the live demo transaction cycle.
2. Establish strict, audited RLS policies for the new migration `0023_transaction_cycle_persistence.sql` covering `application_evaluations`, `application_status_history`, and `notifications`.
3. Verify RA 10173 (Philippine Data Privacy Act) compliance: ensure multi-tenant isolation prevents unauthorized providers from viewing draft, withdrawn, or other providers' applications.

---

## 2. Deliverables & Specifications

### A. RLS Policy Specification for Migration 0023
Formulate the exact RLS policies to be included in `supabase/migrations/0023_transaction_cycle_persistence.sql`:
1. **`public.application_evaluations`**:
   - `enable row level security;`
   - **INSERT**: Allowed for authenticated users where `auth.uid() = reviewer_id` AND the reviewer owns the scholarship associated with `application_id`.
   - **SELECT**:
     - Allowed for the reviewer/provider who owns the scholarship.
     - Allowed for system admins (`public.is_admin()`).
     - Allowed for the student owner of `application_id` for transparent feedback (or restricted if confidential deliberation notes; specify decision clearly).
2. **`public.application_status_history`**:
   - `enable row level security;`
   - **INSERT**: Allowed for authenticated users where `auth.uid() = changed_by`.
   - **SELECT**:
     - Allowed for the student who submitted the application (`applications.user_id = auth.uid()`).
     - Allowed for the provider who owns the scholarship (`scholarships.created_by = auth.uid()`).
     - Allowed for admins.
3. **`public.notifications`**:
   - `enable row level security;`
   - **INSERT**: Allowed for authenticated users (e.g. provider triggering a notification upon status change, or service functions).
   - **SELECT**: Restricted to the owner (`auth.uid() = user_id`).
   - **UPDATE**: Restricted to the owner (`auth.uid() = user_id`) to mark `is_read = true`.

### B. Transaction Cycle RLS Verification Checklist
Audit and document verification for each link in the transaction chain:
- [ ] **Link 1 (Student Submit)**: Can student insert into `public.applications`? (Verified: `0001` allows `auth.uid() = user_id`).
- [ ] **Link 2 (Provider Fetch)**: Can provider query incoming applications? (Verified: `0022` allows `status not in ('draft', 'withdrawn') and s.created_by = auth.uid()`).
- [ ] **Link 3 (Provider Scoped Profiles)**: Can provider view the student's academic profile? (Verified: `0020` view `provider_applicant_profiles` allows access once submitted).
- [ ] **Link 4 (Provider Status Update)**: Can provider update `applications.status` to `'approved'`? (Verified: `0006` allows update where `s.created_by = auth.uid()`).
- [ ] **Link 5 (Admin vs Provider Award Guard)**: Does provider update to `'approved'` succeed without triggering the restrictive `'awarded'` admin guard in `0009`? (Verified: Provider updates to `approved`, NOT `awarded`).
- [ ] **Link 6 (Student Status Check)**: Can student fetch their own updated application with status `'approved'`? (Verified: `0001` allows owner select).

---

## 3. Allowed Files to Modify / Create
- `supabase/migrations/0023_transaction_cycle_persistence.sql` (co-authored with Builder)
- `docs/reports/2026-10-15_security_transaction_audit.md` (audit report)

---

## 4. Verification & Testing
Verify that all SQL policies syntax-check cleanly and maintain strict tenant isolation without recursive RLS triggers.
