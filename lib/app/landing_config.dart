// lib/app/landing_config.dart
//
// Configuration for the public landing page URL.
//
// On mobile, external links to the landing page provider section are
// suppressed until a real public landing URL is configured via environment
// or deployment configuration.

import 'package:flutter/foundation.dart' show kIsWeb;

/// Public landing URL (e.g. `https://scholaris.ph`).
/// Defaults to empty until a public landing URL is deployed and configured.
const String kPublicLandingUrl = String.fromEnvironment('PUBLIC_LANDING_URL', defaultValue: '');

/// Whether the provider CTA should be visible in the current environment.
///
/// On web portals, provider registration and management flows are always active.
/// On native mobile, it remains hidden until a valid public landing URL is
/// configured to prevent shipping localhost or broken placeholder links.
bool get isProviderCtaVisible {
  if (kIsWeb) return true;
  return kPublicLandingUrl.trim().isNotEmpty;
}

/// Resolves the URI for the provider section on the public landing page.
Uri? get providerLandingUri {
  final trimmed = kPublicLandingUrl.trim();
  if (trimmed.isEmpty) return null;
  final parsed = Uri.tryParse(trimmed);
  if (parsed == null || !parsed.hasScheme) return null;
  return parsed.replace(fragment: 'providers');
}
