# Scholaris — Build 26 iOS IPA Handoff Report

**Release Date & Time:** 2026-11-03T00:26:00+08:00  
**Build Target:** Student Experience (iOS Release `.ipa`)  
**UI Source Base Commit:** [`31a7f2fe38eb4e7505488c5283b307f75a069b2f`](https://github.com/YourGbDev/scholaris/commit/31a7f2fe38eb4e7505488c5283b307f75a069b2f)  
**Test Fixes Commit:** [`d08585a0c325e64883ba526ea250f22f7b8ca5a2`](https://github.com/YourGbDev/scholaris/commit/d08585a0c325e64883ba526ea250f22f7b8ca5a2)  
**Exact Release Commit SHA:** [`fbfd372e38b3400a4ceccdfc6692dc56aee0eeb5`](https://github.com/YourGbDev/scholaris/commit/fbfd372e38b3400a4ceccdfc6692dc56aee0eeb5)  
**Version / Build:** `1.0.0+26`  
**Branch:** `codex/auth-tour-polish`  
**GitHub Actions Run:** [41475477781](https://github.com/YourGbDev/scholaris/actions/runs/41475477781)  
**Job ID:** `125389097049`  
**Local Archive Path:** `C:\scholaris\latest_ipa_student_build26_nov02\Scholaris.ipa`  
**Artifact SHA-256:** `0B3C9B2A3C9229C64FD3C2C16B92AB906A4CE34F090CE133913D26B6E7CC0F4F`  
**Physical Device Verification:** Pending (no iOS device connected via USB)

---

## 1. Resolved Test Failures & Root Cause Analysis

### A. Admin Audit Write Failures (`test/admin_audit_write_test.dart`)
1. **Duplicate / Direct-Table Audit Writes**:
   - *Root Cause*: `logAdminAuditEvent` in `lib/features/admin/presentation/admin_users_provider.dart` called `LoginLockoutService.instance.logAuditEvent`, which performed a secondary direct table insert into `audit_logs` (`/rest/v1/audit_logs`), bypassing RPC-only server authorization and creating duplicate entries.
   - *Fix*: Added `recordInMemoryAuditLog` to `LoginLockoutService` to maintain in-memory audit logs for offline test verification without making direct `/rest/v1/audit_logs` HTTP writes.
2. **Swallowed Permission Errors**:
   - *Root Cause*: A blanket `catch (_)` in `logAdminAuditEvent` swallowed all errors, including 403 `PostgrestException` ("permission denied"), improperly reporting success when the server rejected the action.
   - *Fix*: Removed error swallowing. Server authorization errors (such as `PostgrestException`) now propagate cleanly to callers.
3. **Missing Audit ID Confirmation**:
   - *Root Cause*: The returned RPC result was not validated for non-empty string audit ID for general events and exceptions thrown during validation were caught by the error swallower.
   - *Fix*: Enforced `if (result is! String || result.isEmpty) throw StateError('The audit event could not be confirmed.');`.

### B. Ordering Failures (`test/scholarship_repository_test.dart`, `test/matches_provider_test.dart`, `test/auth_boundary_test.dart`)
- *Root Cause*: `FakeScholarshipDataSource.defaultRows` mixed a dynamic relative deadline (`DateTime.now().add(const Duration(days: 30))`) on `sch-dost` with fixed calendar deadlines (`'2026-11-30'`) on `sch-ched`. Once calendar time crossed into November 2026, `now + 30 days` became December 2, 2026, causing `sch-ched` (`2026-11-30`) to sort before `sch-dost` (`2026-12-02`), breaking repository ordering, match rankings, and account isolation expectations.
- *Fix*: Made fixture deadlines fully deterministic by setting `sch-dost`'s deadline to `'2026-11-15'`. This ensures `sch-dost` consistently has a sooner deadline than `sch-ched` (`2026-11-30`), while remaining in the future relative to test execution (`2026-11-02`) so eligibility filters remain satisfied.

---

## 2. Test Suite & Static Analysis Results

- **Targeted Test Suites**:
  - `test/admin_audit_write_test.dart`: 5/5 passed (0 failures).
  - `test/scholarship_repository_test.dart`: 3/3 passed (0 failures).
  - `test/matches_provider_test.dart`: 2/2 passed (0 failures).
  - `test/auth_boundary_test.dart`: 9/9 passed (0 failures).
  - `test/admin_users_tab_test.dart`: 9/9 passed (0 failures).
- **Full Test Suite (`flutter test`)**:
  - **1,253 passed**, 6 skipped, **0 failed** (exit code 0).
- **Full Static Analysis (`flutter analyze`)**:
  - **0 errors**, **0 warnings**, 12 informational lints (pre-existing baseline).

---

## 3. Cloudflare Turnstile CAPTCHA Compiler Proof

From the GitHub Actions build log for Job 125389097049 (Run 41475477781):
```text
/Users/runner/hostedtoolcache/flutter/stable-3.47.9-arm64/flutter/bin/cache/dart-sdk/bin/dartaotruntime \
  /Users/runner/hostedtoolcache/flutter/stable-3.47.9-arm64/flutter/bin/cache/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot \
  --sdk-root /Users/runner/hostedtoolcache/flutter/stable-3.47.9-arm64/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk_product/ \
  --target=flutter --no-print-incremental-dependencies \
  -DSCHOLARIS_CAPTCHA_ENABLED=true \
  -DSCHOLARIS_CAPTCHA_SITE_KEY=0x4AAAAAAFq-mSfnVs6Xvvjo \
  -DSCHOLARIS_CAPTCHA_PAGE_URL=https://scholaris-captcha.pages.dev/captcha_challenge \
  -DFLUTTER_BUILD_NAME=1.0.0 \
  -DFLUTTER_BUILD_NUMBER=26 \
  -DFLUTTER_VERSION=3.47.9 \
  -DFLUTTER_CHANNEL=stable \
  -DFLUTTER_DART_VERSION=3.13.7 \
  -Ddart.vm.product=true \
  --aot --tfa --target-os ios \
  package:scholaris/main.dart
```

---

## 4. Skills Applied

- **`systematic-debugging`**: Followed the four-phase methodology to isolate root causes of both audit log errors and deadline order shifting before touching code.
- **`ponytail`**: Formulated the minimal complete fix: added in-memory audit log recording on `LoginLockoutService` to isolate RPC calls from direct-table writes, removed error swallowing, and stabilized fixture dates with minimal diff.
- **`verification-before-completion`**: Verified every claim with real command execution — 5 targeted tests, 1,253 full unit/widget tests, full analyzer run, and verified compiler defines from remote build logs before claiming completion.
