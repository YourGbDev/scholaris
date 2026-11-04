# Scholaris iOS IPA Build 35 Handoff Report — Signup UI Fixes & Bookmark Flicker Fix

**Date**: 2026-11-04 (Asia/Manila)  
**Target Release**: Build 35 (`1.0.0+35`)  
**Branch**: `codex/typography-refinement`  
**Feature Commit**: [`69a019b`](https://github.com/YourGbDev/scholaris/commit/69a019b) ("feat(auth, ui): complete signup email verification flow and bookmark button flicker fix")  
**Release Commit**: [`fbb3a37`](https://github.com/YourGbDev/scholaris/commit/fbb3a37) ("chore(release): bump iOS build number to 1.0.0+35")  
**GitHub Actions Run**: [#41860682139](https://github.com/YourGbDev/scholaris/actions/runs/41860682139) (macOS runner job `126701885138`)  

---

## 1. IPA Build Artifact & Cryptographic Verification

* **Destination Folder**: `C:\scholaris\latest_ipa_student_build35_nov04\`
* **IPA Binary**: `C:\scholaris\latest_ipa_student_build35_nov04\Scholaris.ipa`
* **File Size**: `50,286,850 bytes` (~47.96 MB)
* **SHA-256 Checksum**:
  ```
  C3A2563D5816144E27262A96043E0D3465ED7AFD000ED13959156671CC9B8169
  ```
* **Artifact Zip Archive**: `C:\scholaris\latest_ipa_student_build35_nov04\artifact.zip` (`50,208,260 bytes`)
* **Archive SHA-256 Digest**:
  ```
  E00EAA6FF6BAD765F2664B0E70A1CC107D65C02304E5FF09203D59317AADB698
  ```
* **Direct GitHub Download**: [Run #41860682139 Artifacts](https://github.com/YourGbDev/scholaris/actions/runs/41860682139)
* **Plist Extraction Verification**:
  - `CFBundleIdentifier`: `com.example.scholaris`
  - `CFBundleShortVersionString`: `1.0.0`
  - `CFBundleVersion`: `35`
  - `MinimumOSVersion`: `15.0`

---

## 2. Authorized Fixes Included in Build 35

### A. Signup Screen Overlay Copy
* **File**: `lib/features/auth/presentation/signup_screen.dart`
* **Change**: Replaced generic scholarship-analysis text in the success overlay with explicit, non-presumptive instructions:
  - Title: `"Continue to email verification"`
  - Subtitle: `"Use the code from your email to finish signing up."`
  - Pose: `MascotPose.celebrating`

### B. Email Verification Mascot Display Before Profile
* **File**: `lib/features/auth/presentation/verify_email_screen.dart`
* **Change**: Explicitly passed `gender: ''` into `MascotPoseView(pose: MascotPose.celebrating, gender: '', height: 165)` so Ariel celebrating displays immediately during OTP verification before an authenticated student profile exists.

### C. Large Text Wrapping (Accessibility & Narrow Viewports)
* **File**: `lib/features/auth/presentation/signup_screen.dart`
* **Change**: Converted horizontal `Row` layout for "Password Complexity" and "Confirm Password" / "Passwords match" indicators to `Wrap(alignment: WrapAlignment.spaceBetween, spacing: 8, runSpacing: 4)`.
* **Benefit**: Zero layout overflow on narrow 320 px screens or 200% text scaling.

### D. Save / Bookmark Button Glitch & Flicker Fix
* **File**: `lib/shared/widgets/scholarship_card.dart`
* **Root Cause**: `_BookmarkButtonState._handleTap()` was immediately clearing `_pendingBookmark = null` in its `finally` block upon HTTP resolution. Because Riverpod state update cycles rebuild the widget tree asynchronously (1-2 frames later), `showFilled` momentarily fell back to `widget.isBookmarked` (`false`), causing a visible 16–33 ms unbookmark flicker before returning to filled.
* **Fix**:
  1. Maintained `_pendingBookmark` until the parent delivers updated `widget.isBookmarked` in `didUpdateWidget()`.
  2. Removed transient green (`kPrimary`) flash from the burst animation; retained clean gold (`kAccent`) bookmark fill throughout.
  3. Smoothed spring sequence to 320 ms using `easeOutCubic` / `easeInCubic`.

### E. Preserved Assets & Unrelated Work
* Preserved universal Geist font family (`Geist-Regular.ttf`, `Medium`, `SemiBold`, `Bold`, `ExtraBold`).
* Preserved canonical mascot artwork (all 22 approved PNGs) restored in Build 34.
* Preserved all prior build archives (`build29` through `build34`).
* Preserved `landing/index.html` and readiness audit documentation.

---

## 3. Compiler Flags & Mandatory CAPTCHA Settings

Verified from remote macOS runner compilation logs (Workflow Run `41860682139`, Job `126701885138`):

```bash
flutter build ios --release --no-codesign -v \
  --dart-define=SCHOLARIS_CAPTCHA_ENABLED=true \
  --dart-define=SCHOLARIS_CAPTCHA_SITE_KEY=0x4AAAAAAFq-mSfnVs6Xvvjo \
  --dart-define=SCHOLARIS_CAPTCHA_PAGE_URL=https://scholaris-captcha.pages.dev/captcha_challenge
```

Compiler Snapshot Log Evidence:
```text
frontend_server_aot.dart.snapshot
  -DSCHOLARIS_CAPTCHA_ENABLED=true
  -DSCHOLARIS_CAPTCHA_SITE_KEY=0x4AAAAAAFq-mSfnVs6Xvvjo
  -DSCHOLARIS_CAPTCHA_PAGE_URL=https://scholaris-captcha.pages.dev/captcha_challenge
  -DFLUTTER_BUILD_NAME=1.0.0
  -DFLUTTER_BUILD_NUMBER=35
  package:scholaris/main.dart
```

No secrets or service keys were exposed in compiler logs.

---

## 4. Verification Evidence Matrix

| Check / Test Tier | Command / Tool | Result |
| :--- | :--- | :--- |
| **Typography Source Guard** | `node tools/check_typography.mjs` | **PASS** (App font families and weights centralized) |
| **Typography Weights & License** | `node --test tools/check_typography.test.mjs` | **PASS** (3/3 tests passed) |
| **CAPTCHA Build Config** | `node tools/test_ios_captcha_build_config.mjs` | **PASS** (Push builds & default manual builds enforce CAPTCHA) |
| **CAPTCHA Gate & Mobile Protocol** | `flutter test test/captcha_gate_test.dart test/captcha_mobile_protocol_test.dart` | **PASS** (8/8 tests passed) |
| **Signup & Email Verification Regressions** | `flutter test test/student_signup_mobile_regression_test.dart test/verify_email_screen_test.dart` | **PASS** (17/17 tests passed) |
| **Bookmark Button Optimistic State & Flicker** | `flutter test test/scholarship_card_test.dart` | **PASS** (32/32 tests passed, including new flicker test) |
| **Offline UI Capture Matrix (320px/390px, 1.0x/2.0x)** | `flutter test test/signup_ui_capture_test.dart` | **PASS** (12/12 capture scenarios passed) |
| **Static Analyzer Cleanliness** | `flutter analyze lib/... test/...` | **PASS** (0 issues found across all modified files) |
| **IPA Binary Plist Extraction** | `tar.exe` extraction & inspection | **PASS** (`CFBundleVersion = 35`, `1.0.0`) |
| **Bundled Fonts & Mascots in IPA** | `tar.exe -tf Scholaris.ipa` | **PASS** (All 5 Geist weights and 22 mascot PNGs confirmed inside bundle) |

---

## 5. Verification Status & Non-Fabrication Notice

* **Automated Suites**: **VERIFIED** — all unit, regression, widget, typography, and protocol tests passed.
* **Cryptographic & Binary Integrity**: **VERIFIED** — SHA-256 computed on downloaded `Scholaris.ipa` and `artifact.zip`.
* **Hardware iPhone Testing**: **PENDING** — physical installation via AltStore / Sideloadly and live test on physical hardware have not yet been performed.
* **Live Email Delivery (SMTP)**: **UNVERIFIED** — The client UI overlay and verification screen now accurately guide the student without falsely claiming email delivery. Actual SMTP receipt in student inboxes depends on Supabase/Gmail SMTP server configuration and cannot be fixed by an IPA build alone.

---

## 6. Skills Applied

* **`verification-before-completion`** (`.agents/skills/verification-before-completion/SKILL.md`):
  - Strict adherence to the Iron Law: "No completion claims without fresh verification evidence."
  - Ran compiler log inspections, SHA-256 hash calculations, plist binary inspections, and targeted test suites with real output before reporting success.
* **`ponytail`** (`.agents/skills/ponytail/SKILL.md`):
  - Implemented the most concise, robust fix for the bookmark button flicker (holding `_pendingBookmark` until `didUpdateWidget` without adding global state or heavy wrappers).
  - Maintained zero bloat in `signup_screen.dart` and `verify_email_screen.dart`.
