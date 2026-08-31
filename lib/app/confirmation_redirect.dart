// lib/app/confirmation_redirect.dart
//
// Platform-aware email-verification redirect target.
//
// The signup and verify-email screens pass a `redirectTo` to Supabase so the
// confirmation email's link returns to the app. On mobile (Android/iOS) that
// target is the custom scheme registered in the platform manifests; browsers
// cannot open custom schemes, so on web the target must be an HTTP(S) URL
// served by the app. This file is the single source of truth for both, and
// lives in tracked code so the web behavior is part of the repository (the
// Supabase URL/anon key themselves stay in the gitignored
// `supabase_config.dart`).

import 'package:flutter/foundation.dart' show kIsWeb;

/// Custom-scheme redirect target for the email-verification deep link on
/// native platforms (Android/iOS). Registered in the Android manifest (the iOS
/// Info.plist registers the host-agnostic `scholaris` scheme) and passed as
/// `redirectTo` when requesting a confirmation email.
const String emailConfirmationRedirectMobile = 'scholaris://verify-email';

/// The email-verification redirect target for the current platform.
///
/// On mobile this is the custom scheme registered in the platform manifests.
/// On web, browsers cannot open custom schemes, so the confirmation link must
/// return to an HTTP(S) URL served by this app. The URL is derived from the
/// page that initiated the request at runtime (e.g.
/// `http://localhost:<port>/verify-email`) so local development needs no
/// hardcoded port. The exact origin must be allow-listed under
/// Auth → URL Configuration → Redirect URLs in the Supabase Dashboard.
String get emailConfirmationRedirect => kIsWeb
    ? webEmailConfirmationRedirectFrom(Uri.base)
    : emailConfirmationRedirectMobile;

/// Builds the web confirmation redirect for [base] (the page URL at the time
/// of the request). Pure so it can be unit-tested without a browser.
///
/// Always points at the `/verify-email` route of the given origin. Query and
/// fragment on the requesting page are dropped so only the app origin is used.
String webEmailConfirmationRedirectFrom(Uri base) =>
    base.resolve('/verify-email').toString();
