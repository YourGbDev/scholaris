# Scholaris Password Recovery — Day 7

This document covers the account-recovery flow: requesting a reset email, the
deep link that returns the app to the set-new-password screen, and the Supabase
Dashboard configuration that is **required but manual**.

Source of truth: `lib/features/auth/presentation/forgot_password_screen.dart`,
`lib/features/auth/presentation/reset_password_screen.dart`,
`lib/features/auth/controllers/auth_controller.dart`, and the platform-aware
redirect resolver `resetPasswordRedirect` /
`webResetPasswordRedirectFrom` in `lib/app/recovery_redirect.dart`.
(The Supabase URL/anon key live separately in the gitignored
`lib/app/supabase_config.dart`.)

---

## 1. The flow

1. **Forgot password** (`/forgot-password`) — user enters their email.
2. `resetPasswordForEmail(email, redirectTo: <platform target>)`
   (PKCE flow). Supabase emails a recovery link whose redirect target is
   platform-specific:
   - mobile: the app's custom scheme `scholaris://reset-password`;
   - web: an HTTP(S) URL served by the app, derived at runtime from the page
     origin (e.g. `http://localhost:<port>/reset-password`) so local
     development needs no hardcoded port.
3. The link returns the user to the app: on mobile it opens the custom scheme,
   on web the browser loads the app at `/reset-password` with the PKCE code in
   the query string. The supabase_flutter deep-link observer exchanges the auth
   code, and the auth boundary receives `AuthChangeEvent.passwordRecovery`.
4. The router forces `/reset-password`; the user sets a new password via
   `auth.updateUser`, which clears the recovery flag and returns the user to
   the normal signed-in landing.

The web target must stay a path-based URL (`.../reset-password`) rather than a
hash-based one: Supabase appends the PKCE code to the query string, which the
supabase_flutter web observer detects. A hash target would place the code inside
the fragment where it is not detected.

## 2. Platform registrations

| Platform | File | Registration |
|---|---|---|
| Android | `android/app/src/main/AndroidManifest.xml` | `VIEW`/`DEFAULT`/`BROWSABLE` intent-filter with `scheme="scholaris"`, `host="reset-password"` |
| iOS | `ios/Runner/Info.plist` | `CFBundleURLTypes` with `CFBundleURLSchemes` = `scholaris` |

Both must stay in sync with `resetPasswordRedirectMobile` in
`lib/app/recovery_redirect.dart`.

## 3. Manual Supabase Dashboard configuration (cannot be verified from the repo)

The recovery email will not return to the app until a project owner adds the
redirect target(s) in the Supabase Dashboard:

- **Authentication → URL Configuration → Redirect URLs**
- Add: `scholaris://reset-password` (mobile custom scheme)
- Add the web app origin(s), for example when validating locally:
  `http://localhost:8080/reset-password` (or a wildcard such as
  `http://localhost:8080/**` depending on the project's URL policy).

These are manual steps done in the dashboard and cannot be validated from this
repository. Real end-to-end testing of the emailed link is also manual: request
a reset, tap the link, confirm the app lands on set-new-password, then confirm
the updated password returns the user to the signed-in landing.

## 4. Known limitations

- A recovery session that survives a cold app restart (app killed mid-recovery,
  relaunched without the link) is not re-marked as recovery — Supabase does not
  persist the recovery marker. This is a documented limitation, not a bug.
- Full web recovery (real emailed link → code exchange → set-new-password) was
  **not** end-to-end verified in the Day 12 environment: it requires a real
  inbox and the Dashboard redirect allow-list above. Verified on web instead:
  the `/reset-password` route, the recovery session routing boundary, the
  path-based redirect target construction, and that the PKCE code in the query
  string is detected and handed to the auth boundary.
