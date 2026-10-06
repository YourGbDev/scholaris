# Task Card: Security & Privacy (RA 10173 & RLS Audit)

> **Assigned Role**: 🛡️ Security Specialist (`ai/security`)  
> **Assigned Worktree**: `.../scholaris/fusilier`  
> **Feature**: [Feature Name]  
> **Master Plan**: `docs/plans/[feature]_plan.md`  
> **Status**: `TEMPLATE / READY FOR ASSIGNMENT`

---

## 1. Objective
[Concise summary of security, privacy, and authorization audit scope]

---

## 2. Security Boundaries & Mandates
* **RA 10173 (Philippine Data Privacy Act)**:
  - Providers must query `public.provider_applicant_profiles` or `public.get_applicant_profile()`.
  - Sensitive demographic fields (birthdate, disability, indigenous status, phone, email) must NEVER leak to provider surfaces.
* **Storage Buckets**:
  - `application_documents` access is restricted to the student owner, admins, or the provider managing that specific submitted application.
* **Draft & Withdrawn Protection**:
  - Applications in `draft` or `withdrawn` status must remain completely invisible to providers.
* **Identity**:
  - All RLS mutations must bind strictly to `auth.uid()`.

---

## 3. Allowed Files to Modify
* `supabase/migrations/...` *(Requires explicit human authorization)*
* `test/security/...`

---

## 4. Security Audit Checklist
- [ ] RLS policies inspected and tested against authenticated student/provider roles
- [ ] Document storage download URLs audited for token/time expiration
- [ ] No client-side bypasses or spoofable user IDs detected

---

## 5. Output Report Destination
Save your report to: `docs/reports/[feature]_security_report.md`
Commit your report:
```bash
git add docs/reports/[feature]_security_report.md
git commit -m "audit(security): review [feature] security boundaries"
```
