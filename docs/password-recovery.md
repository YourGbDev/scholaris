# Scholaris Password Recovery — Day 7

This document covers the account-recovery flow: requesting a reset email, the
custom-scheme deep link that returns the app to the set-new-password screen,
and the Supabase Dashboard configuration that is **required but manual**.

Source of truth: `lib/features/auth/presentation/forgot_password_screen.dart`,
`lib/features/auth/presentation/reset_password_screen.dart`,
`lib/features/auth/controllers/auth_controller.dart`, and the deep-link
constant `SupabaseConfig.resetPasswordRedirect` in
`lib/app/supabase_config.dart`.

---

## 1. The flow

1. **Forgot password** (`/forgot-password`) — user enters their email.
2. `resetPasswordForEmail(email, redirectTo: 'scholaris://reset-password')`
   (PKCE flow). Supabase emails a recovery link whose redirect target is the
   app's custom scheme.
3. The link opens the app (`scholaris://reset-password?...`), the
   supabase_flutter deep-link observer exchanges the auth code, and the auth
   boundary receives `AuthChangeEvent.passwordRecovery`.
4. The router forces `/reset-password`; the user sets a new password via
   `auth.updateUser`, which clears the recovery flag and returns the user to
   the normal signed-in landing.

## 2. Platform registrations (same custom scheme, both platforms)

| Platform | File | Registration |
|---|---|---|
| Android | `android/app/src/main/AndroidManifest.xml` | `VIEW`/`DEFAULT`/`BROWSABLE` intent-filter with `scheme="scholaris"`, `host="reset-password"` |
| iOS | `ios/Runner/Info.plist` | `CFBundleURLTypes` with `CFBundleURLSchemes` = `scholaris` |

Both must stay in sync with `SupabaseConfig.resetPasswordRedirect`.

## 3. Manual Supabase Dashboard configuration (cannot be verified from the repo)

The recovery email will not return to the app until a project owner adds the
redirect target in the Supabase Dashboard:

- **Authentication → URL Configuration → Redirect URLs**
- Add: `scholaris://reset-password`

This is a manual step done in the dashboard and cannot be validated from this
repository. Real-device end-to-end testing of the emailed link is also manual:
request a reset, tap the link, confirm the app lands on set-new-password, then
confirm the updated password returns the user to the signed-in landing.

## 4. Known limitations

- A recovery session that survives a cold app restart (app killed mid-recovery,
  relaunched without the link) is not re-marked as recovery — Supabase does not
  persist the recovery marker. This is a documented limitation, not a bug.
