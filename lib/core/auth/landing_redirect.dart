import 'package:supabase_flutter/supabase_flutter.dart';

import 'landing_redirect_stub.dart'
    if (dart.library.js_interop) 'landing_redirect_web.dart' as impl;

/// Redirects the browser window to the Scholaris marketing landing page.
void redirectToLandingPage() {
  impl.redirectToLandingPage();
}

/// Signs out the provider from Supabase auth and immediately redirects to the
/// marketing landing page (`http://localhost:8080` in dev, `/` in prod).
///
/// This prevents GoRouter's unauthenticated redirect from bouncing providers
/// to the student login screen (`/login`).
Future<void> handleProviderSignOut() async {
  try {
    await Supabase.instance.client.auth.signOut();
  } catch (_) {}
  redirectToLandingPage();
}
