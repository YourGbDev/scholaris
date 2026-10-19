# Task Card: Security (`fusilier` / `ai/security`)

**Sprint:** 3rd Increment Pre-Presentation Audit  
**Role:** 🛡️ Supabase RLS, Privacy & Authorization Specialist  
**Reference Plan:** `docs/plans/2026-10-19_increment3_pre_presentation_audit_plan.md`  
**Status:** `READY FOR AUDIT`

---

## 1. Objective
Audit the database security layer, Row-Level Security (RLS) policies, and Philippine Data Privacy Act (RA 10173) compliance across the 3-role transaction cycle. Verify that reviewer and org_admin RBAC permissions are strictly partitioned, sensitive student demographics remain masked, and document access is tightly restricted to authorized parties.

---

## 2. Permitted Files
- `supabase/migrations/0023_transaction_cycle_persistence.sql`
- `supabase/migrations/0024_organization_review_cycle.sql`
- `supabase/migrations/0025_preserve_existing_award_transition.sql`
- `supabase/tests/organization_review_cycle_live.sql`
- `test/rls_applicant_credentials_scoping_test.dart`
- `tools/test_organization_review_cycle.mjs`
- `docs/reports/2026-10-19_increment3_security_report.md` (report deliverable)

---

## 3. Specific Audit Checklist

### A. RA 10173 Sensitive Data Boundaries
1. **Provider Security Barrier View**:
   - Audit `public.provider_applicant_profiles` in migration 0024.
   - Confirm that sensitive personal data is strictly excluded from provider/reviewer queries:
     - `birth_date` (protects minors) — MUST NOT be exposed.
     - `gender`, `phone`, `email` — MUST NOT be exposed in review views.
     - `has_disability`, `is_indigenous` — MUST NOT be exposed in review views.
     - Confirm `monthly_family_income` is exposed strictly for means-tested evaluation.
2. **Draft & Withdrawn Application Protection**:
   - Confirm providers can NEVER view applications in `'draft'` or `'withdrawn'` status (`a.status NOT IN ('draft', 'withdrawn')`).

### B. RBAC & State Machine Authorization
1. **Separation of Duties (Reviewer vs Org Admin)**:
   - Verify `organization_memberships` table policies.
   - Reviewer role (`'reviewer'`):
     - Can insert into `application_reviews`.
     - Can update application status to `'under_review'` or `'endorsed'`.
     - **CANNOT** update status to `'approved'` or `'awarded'`.
   - Org Admin role (`'org_admin'`):
     - Can transition status from `'endorsed'` to `'approved'` or `'awarded'`.
2. **Student Isolation**:
   - Verify that students can only read and write their own applications (`user_id = auth.uid()`).
   - Confirm students cannot modify reviewer scores or read internal deliberation notes.

### C. Automated Security Verification
1. Run automated RLS and RBAC scoping tests:
   ```bash
   flutter test test/rls_applicant_credentials_scoping_test.dart
   ```
2. Verify security assertions in `tools/test_organization_review_cycle.mjs`:
   ```bash
   node tools/test_organization_review_cycle.mjs
   ```

---

## 4. Deliverable Report
Commit completion report to:
`docs/reports/2026-10-19_increment3_security_report.md`

Must include:
- `### RA 10173 Privacy Compliance Matrix`
- `### RLS & RBAC Boundary Findings`
- `### Storage Policy Audit`
- `### Implemented / Audited`
- `### Verified`
- `### Not verified`
- `### Remaining risks`
