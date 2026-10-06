# Task Card: Security & Privacy (Master Remediation Audit)

> **Assigned Role**: 🛡️ Security Specialist (`ai/security`)  
> **Assigned Worktree**: `.../scholaris/fusilier`  
> **Master Plan**: `docs/plans/2026-10-06_master_remediation_plan.md`  
> **Status**: `AWAITING HUMAN APPROVAL`

---

## 1. Objectives
Audit profile data model, RLS policies, and sensitive demographic data boundaries against RA 10173 and `GEMINI.md`.

---

## 2. Allowed Files to Modify
* `supabase/migrations/...` *(Requires explicit human authorization)*
* `test/security/...`

---

## 3. Security Audit Checklist
- [ ] **Audit Finding 3.2.1**: Verify GPA scale changes do not weaken profile validation constraints or introduce SQL injection vectors.
- [ ] **Audit Finding 3.2.3**: Verify that live document verification status is read through authorized RLS views and does not expose other students' document records.
- [ ] **Verify Privacy Boundaries**: Confirm that provider queries continue using `public.provider_applicant_profiles` without leaking `birth_date`, `has_disability`, `is_indigenous`, `phone`, or `email`.
- [ ] **Verify Identity Enforcement**: Confirm all profile mutations remain strictly bound to `auth.uid()`.

---

## 4. Output Report
Save report to: `docs/reports/remediation_security_report.md`
Commit to branch `ai/security`:
```bash
git add docs/reports/remediation_security_report.md
git commit -m "audit(security): audit master remediation privacy boundaries"
```
