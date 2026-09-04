// Day 19 tests: router recognition of /ceremony and its redirect behavior.
//
// /ceremony is the new opening route (replacing /intro). It must be treated
// like the old intro: signed-out visitors may stay, signed-in users are
// redirected away, and recovery still wins.

import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/app/router.dart';

void main() {
  group('authRedirectDecision: /ceremony', () {
    test('signed-out users may stay on /ceremony', () {
      expect(
        authRedirectDecision(
          location: '/ceremony',
          isLoggedIn: false,
          recoveryActive: false,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: false,
        ),
        isNull,
      );
    });

    test('signed-out users elsewhere are still sent to /login', () {
      expect(
        authRedirectDecision(
          location: '/home',
          isLoggedIn: false,
          recoveryActive: false,
          onAuthRoute: false,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: false,
        ),
        '/login',
      );
    });

    test('signed-in users never linger on /ceremony', () {
      // Profile complete → straight to home.
      expect(
        authRedirectDecision(
          location: '/ceremony',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: true,
        ),
        '/home',
      );
      // Profile still loading → stay put; splash is no longer the universal
      // holding room. The destination screen should show its own loading state.
      expect(
        authRedirectDecision(
          location: '/ceremony',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: true,
          profileComplete: false,
        ),
        isNull,
      );
      // Incomplete profile → onboarding, never the ceremony.
      expect(
        authRedirectDecision(
          location: '/ceremony',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: false,
        ),
        '/profile-setup/personal',
      );
    });

    test('an active recovery session still wins from /ceremony', () {
      expect(
        authRedirectDecision(
          location: '/ceremony',
          isLoggedIn: true,
          recoveryActive: true,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: true,
        ),
        '/reset-password',
      );
    });
  });
}