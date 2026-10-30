# Task Card: Security (`fusilier` Session)

**Sprint**: Round 6 — Inactivity Persistence, Zero Synthetic State & Pre-Integration Verification  
**Role**: 🛡️ Information Assurance, Privacy & Security Controls Specialist  
**Assigned Workspace**: `C:\Users\Windows 11\orca\workspaces\scholaris\fusilier`  
**Active Branch**: `codex/round6-security` (Baseline: `41454588d88323db4f9cf80ac5f852a4c7bf598c`)  
**Standing Contract**: [`docs/coordination/SPECIALIST_CONTRACT.md`](../coordination/SPECIALIST_CONTRACT.md)  
**Status**: `READY`

---

## 1. Permitted Files (Strict Sole Ownership)

### Sole Edit Ownership:
- `docs/reviews/2026-10-30-inactivity-storage-audit.md`
- `docs/reports/task_security_report.md`

### Read-Only / Excluded:
- `lib/` Dart source files (read-only audit by absolute path)
- `test/` (read-only audit of test suites)
- Remote Supabase migrations / SQL console

---

## 2. Directives & Tasks

1. **Security & Privacy Audit of Inactivity Persistence**:
   - Inspect Builder's evolving files read-only via absolute path (`C:\Users\Windows 11\orca\workspaces\scholaris\cowrie\lib\core\security\inactivity_guard.dart` and `inactivity_storage*.dart`) while Builder works.
   - Verify that stored values contain strictly integer millisecond timestamps (`millisecondsSinceEpoch`); confirm zero plaintext passwords, tokens, hashes, emails, or PII are stored in `SharedPreferences`.
   - Verify user key scoping (`inactivity_deadline_$userId`) and account-switch purging (`storage.remove(_key(previous))`).
   - Audit fail-closed error handling: verify that if storage throws an exception, protected UI remains blocked and does not fall back to an open/unlocked state.
2. **Evidence Boundary & Compliance Distinction**:
   - Explicitly distinguish client-side local UI locking (defense against shoulder surfing and device abandonment) from server-side JWT session revocation.
   - Do NOT issue a blanket Philippine DPA compliance certificate. Provide factual, technical security/privacy findings only.
3. **Delivery**:
   - Cite Builder’s delivered immutable commit SHA in your final audit verdict.
   - Deliver audit review to `docs/reviews/2026-10-30-inactivity-storage-audit.md` and report to `docs/reports/task_security_report.md`.
