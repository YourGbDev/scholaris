// lib/app/recovery_redirect.dart
//
// Platform-aware password-recovery redirect target.
//
// The forgot-password screen passes a `redirectTo` to
// `auth.resetPasswordForEmail`. On mobile (Android/iOS) that target is the
// custom scheme registered in the platform manifests; browsers cannot open
// custom schemes, so on web the target must be an HTTP(S) URL served by the
// app. This file is the single source of truth for both, and lives in tracked
// code so the web behavior is part of the repository (the Supabase URL/anon
// key themselves stay in the gitignored `supabase_config.dart`).

import 'package:flutter/foundation.dart' show kIsWeb;

/// Custom-scheme redirect target for the password-recovery deep link on
/// native platforms (Android/iOS). Registered in the Android manifest, the
/// iOS Info.plist, and passed as `redirectTo` when requesting a reset email.
const String resetPasswordRedirectMobile = 'scholaris://reset-password';

/// The password-recovery redirect target for the current platform.
///
/// On mobile this is the custom scheme registered in the platform manifests.
/// On web, browsers cannot open custom schemes, so the recovery link must
/// return to an HTTP(S) URL served by this app. The URL is derived from the
/// page that initiated the request at runtime (e.g.
/// `http://localhost:<port>/reset-password`) so local development needs no
/// hardcoded port. The exact origin must be allow-listed under
/// Auth → URL Configuration → Redirect URLs in the Supabase Dashboard.
String get resetPasswordRedirect => kIsWeb
    ? webResetPasswordRedirectFrom(Uri.base)
    : resetPasswordRedirectMobile;

/// Builds the web recovery redirect for [base] (the page URL at the time of
/// the request). Pure so it can be unit-tested without a browser.
///
/// Always points at the `/reset-password` route of the given origin, which
/// the GoRouter handles as the set-new-password screen. Query and fragment
/// on the requesting page are dropped so only the app origin is used.
String webResetPasswordRedirectFrom(Uri base) =>
    base.resolve('/reset-password').toString();
