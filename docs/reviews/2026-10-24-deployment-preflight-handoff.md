# Scholaris Deployment Preflight & Multi-Agent Coordination Handoff — October 24, 2026

> [!WARNING]
> **SUPERSEDED DOCUMENT**: This preflight draft has been superseded by the authoritative runbook at `docs/reviews/2026-10-25-authoritative-deployment-runbook.md`. Refer to the October 25 document for exact function contracts, reconciled fail-stop postchecks, and the multi-tier recovery framework.

## 1. Status & Session Pause Notice

- **Session State**: Work paused for the night as requested by user.
- **Working Tree**: `C:\scholaris` on branch `fix/touch-targets-oct02` (HEAD `1ea30bb`). All uncommitted modifications and specialist worktrees are preserved intact.
- **Active Processes**: All background dev servers (Provider Preview on port 5025 and Admin Preview on port 5027) have been cleanly terminated. Zero background processes running.
- **Authorization Status**: **Strictly zero** git commits, pushes, remote migrations, production writes, deployments, or IPA builds have been executed. No remote execution is approved until Codex completes an independent adversarial review of this preflight.

---

## 2. Preflight Requirements Reconciliation & Exact Evidence Paths

### Requirement 1: Migration SHA-256 Hashes & Remote Delta
- **Target Database**: `https://yqwbarzxpduzmtrxnrbm.supabase.co` (PostgreSQL 17.6 on `aarch64-unknown-linux-gnu`).
- **Remote Application Status**:
  - `0001` through `0026`: **Applied** remotely.
  - `0028_student_onboarding_recovery.sql`: **Applied** remotely (`idx_applications_user_status` and trigger present).
  - `0027`, `0029`, `0030`, `0031`, `0032`, `0033`: **Pending** remotely.
- **Exact SHA-256 Hashes**:
  - `0027_individual_provider_lifecycle.sql`: `98FE922D423C2A88D1396D4C1BB7B6D2F9AAA6BB3ECA2BE759AC458F56CC7DFF`
  - `0028_student_onboarding_recovery.sql`: `8AFF3678D0F8C763F4AE35DB7501D4D78BF1FB3785C0E8E0E66EBADB0E24E73E` (Skip during remote application)
  - `0029_individual_support_ledger.sql`: `B72F757E09B774B72A0DD9D8A1371899B5B160E7E95A1E14EDC599B53287E3A8`
  - `0030_individual_support_recovery.sql`: `585901CBA80A9C7D366EA8EE26CF92B8FA5D470C00D96BABDA687B31509DF195`
  - `0031_provider_payment_review_requests.sql`: `7980AB3F33891B08803045C8A0BBC9D00AB7C187F6824F7C0D9AB47D78267B6E`
  - `0032_student_safety_reports.sql`: `626EA141FC27B9F932D2826EC43488BF3FC164D756D2558D01A5A1D2F2E34ECC`
  - `0033_provider_review_changes.sql`: `443DDE9DD02E73AAF9E9BE6080B63C2956AA4853FC6D05E318AE4C8FB49DA5E9`

### Requirement 2: Storage Bucket Configuration, Privileges & Triggers
- **Storage Bucket Contract**:
  - Bucket name: `safety_reports` (Private, max 5,242,880 bytes, MIME types: `image/jpeg`, `image/png`, `image/webp`, `application/pdf`).
- **Deletion Guard Trigger & Advisory Lock**:
  - Migration `0032` installs `public.guard_safety_report_evidence_delete()` with trigger `BEFORE DELETE ON storage.objects`.
  - Transaction-scoped advisory lock `pg_advisory_xact_lock(hashtext('safety_reports:' || name))` serializes concurrent `DELETE` and `attach_safety_report_evidence` calls.
- **Fail-Stop Postchecks (Runbook)**:
  1. `FAIL-STOP 1`: Bucket `safety_reports` exists in `storage.buckets`. If missing, abort before 0032.
  2. `FAIL-STOP 2`: Trigger `trg_guard_safety_report_evidence_delete` is enabled on `storage.objects`.
  3. `FAIL-STOP 3`: Direct table write grants on `student_safety_report_evidence` revoked from `anon` and `authenticated`.
  4. `FAIL-STOP 4`: Routine `public.is_admin_active` exists and rejects suspended administrators.

### Requirement 3: Binary Storage API & Metadata Contract
- **Test Evidence Path**: `C:\scholaris\tools\test_storage_api_binary_integrity.mjs`
  - Result: **100% passed** on PostgreSQL 18.4 (exit code 0).
  - Confirmed byte-for-byte binary preservation (2048-byte PNG payload intact after denied concurrent delete).
  - Confirmed zero metadata mismatch between storage object and evidence record.
  - Confirmed physical binary cleanup on failed registration (zero orphan clutter).
  - Confirmed idempotent ambiguous response recovery without extra slot burn.
- **Transport Suite**: `C:\scholaris\test\safety_report_repository_test.dart` (real HTTP transport test passes).

### Requirement 4: Chrome DevTools Protocol (CDP) Browser Verification
- **Test Evidence Path**: `C:\scholaris\scratch\rigorous_browser_verification_results.json` and `scratch/rigorous_*.png` (15 captures).
- **Responsive Flex Fix**: Fixed narrow mobile (360×800) overflow in `lib/features/provider/presentation/org/org_incoming_applications_tab.dart` by wrapping 4 metrics columns into a 2×2 responsive grid with `Flexible` text guards.
- **Verification Telemetry**:
  - Nested Buttons in AXTree: **0**
  - RenderFlex Overflows: **0**
  - Assertions Count: **0**
  - Uncaught Exceptions: **0**
  - Total Error Logs: **0**
  - Viewports verified: 1280×800, 360×800, 440×956, 1280×420, 200% text scale, Reduced Motion.
  - Portals verified: Admin Preview (`http://localhost:5027`) and Provider Preview (`http://localhost:5025`, Org and Individual shells).

### Requirement 5: Scoped Tests & Static Analysis
- **Focused Test Suite**: `test/safety_report_repository_test.dart`, `test/student_safety_report_widget_test.dart`, `test/provider_verification_resubmission_test.dart`, `scratch/codex_same_filename_evidence_probe_test.dart`, `test/admin_reports_safety_ui_test.dart`, `test/admin_workspace_priority_test.dart` (42 / 42 passed).
- **Scoped Static Analysis**: `flutter analyze lib/features/provider/presentation/org/org_incoming_applications_tab.dart lib/admin/ lib/features/safety/`: **No issues found** (0 warnings, 0 errors).

---

## 3. Remaining Blockers & Preflight Limitations

1. **Codex Independent Review Required**: The entire deployment preflight handoff, migration hash matrix, binary integrity test, and browser verification must be independently reviewed and accepted by Codex before any remote execution.
2. **Remote Deployment Authorization Withheld**: No execution on `https://yqwbarzxpduzmtrxnrbm.supabase.co` is permitted until explicit user authorization is granted.
3. **Storage Bucket Dependency**: Remote migration `0032` requires that the private storage bucket `safety_reports` is created beforehand via dashboard or storage API; applying `0032` before the bucket exists will trigger `FAIL-STOP 1`.
4. **Physical Assistive Hardware**: Accessibility tree semantics and focus trapping were verified via Chrome CDP; physical iOS VoiceOver and Android TalkBack on actual mobile devices have not been exercised.

---

## 4. Multi-Agent Coordination Plan for Tomorrow

Tomorrow, resume under Architect coordination (`whelk`). Specialist worktrees will be inspected and reused with explicit file ownership and zero cross-worktree interference:

| Worktree | Branch / Role | Focused Assignment & File Ownership |
| --- | --- | --- |
| **`whelk`** | `ai/architect` | System design, protocol coordination, migration ledger verification, runbook updates. Owns `docs/coordination/`, `docs/reviews/`. |
| **`cowrie`** | `ai/builder` | Unit & integration test suites, repository error propagation. Owns `lib/features/safety/data/`, `test/safety_report_repository_test.dart`. |
| **`bowhead`** | `ai/ui` | Mobile & desktop UI verification, responsive layouts, Apple HIG styling, motion craft. Owns `lib/admin/`, `lib/features/provider/presentation/`. |
| **`cerith`** | `ai/qa` | Regression hunting, multi-session concurrency reproduction, edge case probing. Owns `tools/`, `scratch/`. |
| **`fusilier`** | `ai/security` | Supabase RLS, storage bucket boundaries, Data Privacy Act (RA 10173) compliance. Owns `supabase/migrations/`. |

### Next Steps When Resuming:
1. Codex conducts independent adversarial recheck of preflight artifacts (`tools/test_storage_api_binary_integrity.mjs`, `scratch/rigorous_browser_verification_results.json`, and migration hashes).
2. Upon user authorization, execute the ordered deployment runbook defined in `docs/reviews/2026-10-24-super-admin-ui-handoff.md#section-4`.
