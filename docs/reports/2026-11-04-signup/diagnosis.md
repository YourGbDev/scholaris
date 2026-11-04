# Signup email and UI diagnosis — November 4, 2026

Working source: `815967a2b7075357679193dfbe7fc7ad37270186` plus the uncommitted task changes below. No IPA, account changes, SMTP changes, template changes, release, or commit was made. Existing unrelated work was preserved.

## Live Supabase findings

Inspected the authenticated in-app browser project `yqwbarzxpduzmtrxnrbm`, matching the project's configured Supabase URL and iOS workflow fallback. Native Chrome control had failed URL identification; the in-app tab worked.

- The owner-specified Gmail account already existed and was confirmed October 22, 2026 at 20:58 in the dashboard. Last sign-in was October 22 at 22:08. Confirmation-sent shows no timestamp.
- Its recent Auth event, November 4 at 23:07:57 as displayed by the dashboard, is `user repeated signup: request completed`, HTTP 200, POST `/signup`, log ID `de2b6850-c8bb-47ca-a434-1ef6d8b7cb48`.
- This attempt was a repeat signup against a confirmed account, not a new account awaiting verification. A successful signup response is not proof of a confirmation-email dispatch. Supabase documents obscured responses for already-confirmed users depending on confirmation settings: https://supabase.com/docs/reference/dart/auth-signup . No client-side account-existence probe or authentication bypass was added.
- In the inspected Auth log window (November 3 23:21–November 4 23:07), the dashboard showed 41 Auth entries: 40 success, one 4xx warning, zero 5xx errors. This is a bounded observation, not a delivery receipt or proof of no historical SMTP failure.
- Custom SMTP is enabled: `smtp.gmail.com`, port 465, sender name Scholaris. Sender and username are populated; stored password stays hidden. The dashboard warns that personal-email SMTP may affect deliverability. Credentials were neither revealed nor copied.
- Confirmation template: subject “Your Scholaris verification code”; contains `{{ .Token }}` and legacy `{{ .ConfirmationURL }}`.
- Recovery template: subject “Your Scholaris password reset code”; contains the recovery token and legacy confirmation URL.
- Email signups and Confirm email are enabled. Email OTP length is eight digits, expiration 3600 seconds, matching the client. These settings were inspected without modification.

For this already-confirmed account, use Log in, or the existing Forgot password flow if needed. A new signup confirmation is not a suitable delivery test for this address. Actual SMTP acceptance and Gmail inbox/spam receipt of a fresh eligible message remain unverified. No email was triggered during this read-only investigation.

## Local fixes

- `signup_screen.dart`: the overlay runs after Supabase's signup response. It inherited scholarship-analysis defaults. The caller now supplies “Continue to email verification” and “Use the code from your email to finish signing up.” It makes no claim that a new account was created or that mail arrived. Other callers retain their existing content.
- `verify_email_screen.dart`: the asset was present and registered, not missing. `MascotPoseView` intentionally reserves an empty box while no profile is available. Before confirmation there is no authenticated student profile. The verification screen now explicitly uses the existing unset-gender fallback, displaying Ariel's bundled celebrating asset in the existing 165 px slot. The shared profile-loading behavior remains intact.
- Enlarged-text checks exposed overflow in Password Complexity (32 px at 320 px width) and the populated Confirm Password / Passwords match row. Both now wrap instead of forcing one horizontal line. Existing font roles, sizes, scaling, colors and shared styling remain unchanged.

## Verification

- Regression tests failed first for the incorrect overlay copy and missing mascot, then passed after the fixes.
- 29 focused tests passed: signup/mobile regression, verification code/session/error/resend behavior, and 12 narrow-layout/capture cases.
- 48 related tests passed: semantic/reference/current UI typography, profile-loading mascot identity, CAPTCHA gate/mobile protocol, and password recovery.
- Typography source guard passed; all three Node typography tests passed.
- Focused analysis of the two production files and the verification/capture tests passed with no issues. The broader initial analysis also reported two pre-existing transitive `http` dependency notices in `student_signup_mobile_regression_test.dart`; no new dependency was added.
- Scoped whitespace checks passed; the UI detector returned no findings.
- Offline Flutter-test checks used 320 and 390 logical-pixel widths at 100% and 200% text. Matched signup/verification images are in `before/` and `after/`; new overlay captures are in `after/`. Verification controls remain reachable by scrolling. These captures and synthetic HTTP responses do not establish live authentication or native font rendering.

## Pending physical checks

Fresh eligible email delivery and receipt; native iPhone and Android rendering; installed-iPhone CAPTCHA/login; other-device session logout; physical-device lockout and inactivity checks. No new IPA was authorized or built, so these local UI changes are not yet in the installed app. CAPTCHA and required email confirmation were not disabled.
