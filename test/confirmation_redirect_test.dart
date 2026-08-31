// Focused tests for the email-verification redirect target (Day 13).
//
// Mirrors the password-recovery redirect tests: the value the signup and
// verify-email screens pass to Supabase as `redirectTo`, the Android manifest
// declares as an intent-filter, and the iOS Info.plist accepts as a custom
// scheme must match exactly, and the web derivation must stay pure and drop
// any query/fragment from the requesting page.
//
// No network is involved: the getter is platform-aware and the web helper is a
// pure function.

import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/app/confirmation_redirect.dart';

void main() {
  group('email confirmation — deep-link redirect target', () {
    test('emailConfirmationRedirect is the single source of truth', () {
      // The value emailConfirmationRedirect is the constant that the signup
      // and verify-email screens pass as emailRedirectTo, that the Android
      // manifest declares as an intent-filter, and that the iOS Info.plist
      // registers as a URL scheme. All three must match this exact string.
      // On non-web (tests run on the Dart VM) the getter must return the
      // mobile custom scheme unchanged.
      expect(emailConfirmationRedirect, 'scholaris://verify-email');

      final uri = Uri.parse(emailConfirmationRedirect);
      expect(uri.scheme, 'scholaris');
      expect(uri.host, 'verify-email');
      expect(uri.hasQuery, isFalse);
    });

    test('web redirect targets the /verify-email route on the app origin', () {
      // Browsers cannot open the scholaris:// custom scheme, so on web the
      // confirmation link must return to the HTTP(S) origin serving the app
      // with the verify-email route. The origin is read from the requesting
      // page at runtime; these cases mirror a local `flutter run` server and a
      // page already on the signup screen.
      expect(
        webEmailConfirmationRedirectFrom(
          Uri.parse('http://localhost:8080/'),
        ),
        'http://localhost:8080/verify-email',
      );
      expect(
        webEmailConfirmationRedirectFrom(
          Uri.parse('http://localhost:8080/signup?x=1'),
        ),
        'http://localhost:8080/verify-email',
      );
      // Query and fragment on the requesting page must not leak into the
      // confirmation redirect.
      expect(
        webEmailConfirmationRedirectFrom(
          Uri.parse('http://localhost:8080/?utm_source=test#section'),
        ),
        'http://localhost:8080/verify-email',
      );
    });
  });
}
