# iPhone Build 12 Handoff: CAPTCHA, Admin Controls, Audit Hardening & Provider Assets

**Date:** October 30, 2026 (Asia/Manila)  
**Branch:** `fix/touch-targets-oct02`  
**Build Version:** `1.0.0+12` (Build 12)  
**Release Target:** iPhone sideloadable installation via Sideloadly  

---

## 1. Build Identity & Artifact Verification

| Attribute | Value |
|---|---|
| **App Version** | `1.0.0+12` |
| **Commit SHA** | `f456c4e138a063d3f9b2d398f6d628eb19d08e56` (HEAD on `fix/touch-targets-oct02`) |
| **Base Commit** | `563d440ac1223802597a8bf4adcc69d00ce06e96` |
| **GitHub Actions Run ID** | [`40913507792`](https://github.com/YourGbDev/scholaris/actions/runs/40913507792) |
| **GitHub Actions Job ID** | `123587491610` (`Build iOS Application in 4m52s`) |
| **Trigger Mechanism** | `workflow_dispatch` with input `captcha_enabled=true` |
| **Runner Image** | `macos-latest` (Apple Silicon M-series runner) |
| **Primary IPA Location** | `C:\scholaris\latest_ipa_student_build12_oct30\Scholaris.ipa` |
| **Sideloadly Drop Path** | `C:\scholaris\Scholaris.ipa` |
| **File Size** | `30,066,772 bytes` (28.67 MB) |
| **SHA-256 Checksum** | `83494B301A405C4F25D0DC275E220FB0AAC9FBC7359A83AF050C73E8975A1242` |

### Compiler Dart Defines Exercised in CI Build
From exact runner compile step log (`Build iOS App (.app)`):
- `-DSCHOLARIS_CAPTCHA_ENABLED=true`
- `-DSCHOLARIS_CAPTCHA_SITE_KEY=0x4AAAAAAFq-mSfnVs6Xvvjo`
- `-DSCHOLARIS_CAPTCHA_PAGE_URL=https://scholaris-captcha.pages.dev/captcha_challenge`
- `-DFLUTTER_BUILD_NAME=1.0.0`
- `-DFLUTTER_BUILD_NUMBER=12`
- `-DFLUTTER_VERSION=3.47.8` (Dart `3.13.7`, Xcode 26.6 / iOS SDK)

---

## 2. Changes Included in Build 12

### A. Mobile CAPTCHA Support (`webview_flutter` & Protocol)
- **Native Challenge View** (`lib/core/security/captcha_view_native.dart`): Added native iOS/Android WebView challenge presenter using `webview_flutter: 4.14.1`. Loads the hosted HTTPS challenge page with isolated navigation guards restricted to the challenge origin.
- **Protocol Validation** (`lib/core/security/captcha_mobile_protocol.dart`): Secure URL constructor verifying HTTPS scheme, non-empty host, and query binding; nonce-matching token parser and failure detector.
- **Conditional Compilation** (`lib/core/security/captcha_challenge.dart`): Wire `captcha_view_native.dart` for native mobile runtimes (`dart.library.io`) while retaining web and stub implementations.

### B. Untracked Provider Assets & Pubspec Updates
- **Provider Hero Illustration** (`assets/images/provider_hero_illustration.png`): Included the required image (1.76 MB, SHA-256 `160CC7E540A4C26BEEBA16359BAB712A27CCFB1A8864E864FD527875D795BA3E`) declared in `pubspec.yaml` and displayed in `ProviderOverviewPanel`.
- **Version Bump**: `pubspec.yaml` version bumped from `1.0.0+11` to `1.0.0+12`.

### C. Admin & Scholarship Persistence Integrity
- **Admin Activation RPC** (`lib/features/admin/presentation/admin_scholarships_provider.dart`): Replaced direct table updates with backend RPC `set_admin_scholarship_active`, verifying returned record ID to prevent false client success indications.
- **Zero Client Synthetic Audit** (`lib/features/admin/presentation/admin_users_provider.dart`, `lib/features/admin/repositories/admin_audit_log_repository.dart`): Eliminated client-side synthetic audit fabrication; removed in-memory audit log fallbacks.
- **Row-Count Confirmation** (`lib/features/profile/repositories/profile_repository.dart`): Guard profile update and delete operations to strictly assert exactly 1 row returned from PostgreSQL.

### D. Authentication, Password & Account Lockout
- **Password Complexity** (`lib/features/account/repositories/account_repository.dart`): Pre-validate password complexity locally via `PasswordValidator.isComplex` before contacting authentication.
- **Session Swapping Guard**: Abort password updates if signed-in user ID changes during reauthentication.
- **Lockout Escalation** (`lib/core/security/login_lockout_service.dart`): Retain accumulated failed attempts across expired lockout windows to ensure escalation tier progression.

### E. Provider Presentation Polish
- **Stale Academic Year Removal**: Provider screens (`org_analytics_tab.dart`, `org_disbursements_tab.dart`, `provider_application_detail_screen.dart`, `provider_incoming_applications.dart`, `provider_scholarships_tab.dart`) now display neutral phrasing rather than hardcoded `AY 2024–2025`.
- **Honest Export Notices**: Replaced simulated PDF/Excel export animations with transparent notices indicating export functionality is not yet available.

### F. Backend Security & Audit Reference Files
- Included migrations `0037_admin_profile_audit.sql`, `0038_audit_log_mutation_privileges.sql`, and `0039_trusted_audit_events.sql` alongside audit verification test suites in `tools/`.

---

## 3. Verification Evidence

### Local Test Execution (Exit Code 0)
- `test/captcha_mobile_protocol_test.dart`: 3/3 passed (HTTPS challenge enforcement, nonce binding, error parsing).
- `test/admin_audit_write_test.dart`: 2/2 passed (RPC audit validation).
- `test/admin_profile_write_transport_test.dart`: 1/1 passed (1-row write assertion).
- `test/admin_scholarship_write_test.dart`: 7/7 passed (RPC zero-row failure propagation).
- `test/account_repository_test.dart`: 12/12 passed (Password complexity, reauth sequencing, session guard).
- `test/ias_security_test.dart`: 28/28 passed (Lockout escalation, session revocation).
- **Total targeted tests:** 53 passed, 0 failures.

### Static Analysis
- `flutter analyze --no-pub lib/`: **No issues found!** (Exit 0).
- `flutter analyze --no-pub [targeted tests]`: **No issues found!** (Exit 0).

### Code Generation
- `dart run build_runner build --delete-conflicting-outputs`: Built with `build_runner/aot` in 67s; 12 outputs written with zero conflicts.

### Archive Inspection of `Scholaris.ipa`
Verified internal contents of `Payload/Runner.app`:
- `webview_flutter_wkwebview_webview_flutter_wkwebview.bundle` present.
- `flutter_assets/assets/images/provider_hero_illustration.png` present (1,762,606 bytes).
- Compiled Flutter product binary `Frameworks/App.framework/App` (12,121,552 bytes) present.

---

## 4. Sideloadly Installation Instructions for iPhone

1. **Launch Sideloadly** on your computer.
2. **Connect your iPhone** via USB (or ensure Wi-Fi sync is connected).
3. **Select IPA**: Drag and drop `C:\scholaris\Scholaris.ipa` (or `C:\scholaris\latest_ipa_student_build12_oct30\Scholaris.ipa`) into the Sideloadly window.
4. **Apple ID**: Enter your Apple ID credentials in Sideloadly for signing.
5. **Install**: Click **Start** and allow Sideloadly to sign and install the app onto your iPhone.
6. **Trust Developer Certificate**: On your iPhone, navigate to **Settings > General > VPN & Device Management**, tap your developer certificate, and tap **Trust**.

---

## 5. Security Coordination & Critical Invariants

1. **Supabase CAPTCHA Remains Disabled**:
   - Supabase CAPTCHA must **NOT** be enabled until Build 12 has been installed on the test iPhone and confirmed to load the Cloudflare Turnstile challenge page correctly during login/signup flows.
   - Enabling CAPTCHA in Supabase before verifying client compatibility would block authentication for mobile devices.
2. **Turnstile Secret Key Protection**:
   - When ready to activate, the Cloudflare Turnstile Secret Key must be entered **privately** by the operator directly inside the Supabase Auth Dashboard under **Authentication > Protection > Enable CAPTCHA**.
   - The Turnstile secret must **never** be committed to source code or pasted in chat.
3. **Server-Enforced Lockout Limitation**:
   - The Supabase hosted project is on the Free tier. The Supabase Password Verification Attempt Auth Hook is an Enterprise/Team tier feature and remains blocked on the Free plan.
   - Progressive lockout remains client/local-enforced on the device.
4. **Landing Page Status**:
   - The landing page (`landing/index.html`) is **not** published or deployed. Its modified state remains strictly local and was excluded from the release commit.
