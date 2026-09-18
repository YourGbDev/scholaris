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

    test('signed-in providers are sent to /provider-home from /ceremony', () {
      // Role branch wins over setup/completeness routing regardless of the
      // setupComplete flag — a provider row is never forced through the
      // student wizard.
      for (final complete in [true, false]) {
        expect(
          authRedirectDecision(
            location: '/ceremony',
            isLoggedIn: true,
            recoveryActive: false,
            onAuthRoute: true,
            onSetupRoute: false,
            profileLoading: false,
            profileComplete: complete,
            role: 'provider',
          ),
          '/provider-home',
          reason: 'provider must leave /ceremony (setupComplete=$complete)',
        );
      }
      // Recovery still outranks the provider branch.
      expect(
        authRedirectDecision(
          location: '/ceremony',
          isLoggedIn: true,
          recoveryActive: true,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: false,
          role: 'provider',
        ),
        '/reset-password',
      );
    });
  });

  group('authRedirectDecision: student navigation and detail routing', () {
    test('signed-in student with complete profile can visit /scholarship/:id', () {
      final redirect = authRedirectDecision(
        location: '/scholarship/f8940e50-40e6-43c1-a6aa-724e1b671eb6',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: true,
        role: 'student',
      );
      expect(redirect, isNull);
    });

    test('signed-in student with complete profile can visit /saved', () {
      final redirect = authRedirectDecision(
        location: '/saved',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: true,
        role: 'student',
      );
      expect(redirect, isNull);
    });

    test('signed-in student with complete profile stays on /home', () {
      final redirect = authRedirectDecision(
        location: '/home',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: true,
        role: 'student',
      );
      expect(redirect, isNull);
    });

    test('signed-in student on auth route is redirected to /home', () {
      final redirect = authRedirectDecision(
        location: '/login',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: true,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: true,
        role: 'student',
      );
      expect(redirect, '/home');
    });

    test('signed-in student on setup route is redirected to /home', () {
      final redirect = authRedirectDecision(
        location: '/profile-setup/personal',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: true,
        profileLoading: false,
        profileComplete: true,
        role: 'student',
      );
      expect(redirect, '/home');
    });

    test('signed-in student on /onboarding is redirected to /home', () {
      final redirect = authRedirectDecision(
        location: '/onboarding',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: true,
        role: 'student',
      );
      expect(redirect, '/home');
    });

    test('signed-in student attempting provider routes is redirected to /home', () {
      final redirect = authRedirectDecision(
        location: '/provider-home',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: true,
        role: 'student',
      );
      expect(redirect, '/home');
    });

    test('signed-in student with incomplete profile is redirected to setup from /scholarship/:id', () {
      final redirect = authRedirectDecision(
        location: '/scholarship/f8940e50-40e6-43c1-a6aa-724e1b671eb6',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
        role: 'student',
      );
      expect(redirect, '/profile-setup/personal');
    });

    test('signed-in provider can visit provider application detail', () {
      final redirect = authRedirectDecision(
        location: '/provider-application/123',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
        role: 'provider',
      );
      expect(redirect, isNull);
    });
  });
}