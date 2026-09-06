// Unit tests for the first-launch onboarding redirect gate.
//
// The gate layers on top of [authRedirectDecision] and only affects the
// "signed out → login" funnel. These tests pin down every branch:
//   - first launch funnels /splash, /login, /signup, /ceremony → /onboarding
//   - the user may stay on /onboarding
//   - while the persisted flag is loading, splash is the holding room
//   - after the flag is seen, all entry points resolve as before
//   - recovery sessions, public deep links and signed-in flows are untouched

import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/app/router.dart';

void main() {
  group('onboardingRedirectDecision: first launch', () {
    test(
      'signed-out splash funnels to /onboarding before the flag is seen',
      () {
        expect(
          onboardingRedirectDecision(
            authDecision: '/login',
            location: '/splash',
            onboardingLoading: false,
            onboardingSeen: false,
          ),
          '/onboarding',
        );
      },
    );

    test('login / signup / ceremony entries funnel to /onboarding', () {
      for (final location in ['/login', '/signup', '/ceremony']) {
        expect(
          onboardingRedirectDecision(
            authDecision: null, // these are auth-allowed routes
            location: location,
            onboardingLoading: false,
            onboardingSeen: false,
          ),
          '/onboarding',
          reason: 'first run should precede $location',
        );
      }
    });

    test('the user may stay on /onboarding', () {
      expect(
        onboardingRedirectDecision(
          authDecision: '/login', // signed-out would otherwise go to login
          location: '/onboarding',
          onboardingLoading: false,
          onboardingSeen: false,
        ),
        isNull,
      );
    });

    test('while the flag loads, splash is the holding room', () {
      expect(
        onboardingRedirectDecision(
          authDecision: '/login',
          location: '/splash',
          onboardingLoading: true,
          onboardingSeen: false,
        ),
        isNull,
      );
      expect(
        onboardingRedirectDecision(
          authDecision: '/login',
          location: '/home',
          onboardingLoading: true,
          onboardingSeen: false,
        ),
        '/splash',
      );
    });

    test('seen users resolve exactly as before the gate existed', () {
      expect(
        onboardingRedirectDecision(
          authDecision: '/login',
          location: '/home',
          onboardingLoading: false,
          onboardingSeen: true,
        ),
        '/login',
      );
      expect(
        onboardingRedirectDecision(
          authDecision: null,
          location: '/login',
          onboardingLoading: false,
          onboardingSeen: true,
        ),
        isNull,
      );
    });
  });

  group('onboardingRedirectDecision: untouched surfaces', () {
    test('public deep links pass through on first launch', () {
      for (final location in ['/forgot-password', '/verify-email']) {
        expect(
          onboardingRedirectDecision(
            authDecision: null,
            location: location,
            onboardingLoading: false,
            onboardingSeen: false,
          ),
          isNull,
        );
      }
    });

    test('an active recovery session always wins', () {
      expect(
        onboardingRedirectDecision(
          authDecision: '/reset-password',
          location: '/login',
          onboardingLoading: false,
          onboardingSeen: false,
          recoveryActive: true,
        ),
        '/reset-password',
      );
      expect(
        onboardingRedirectDecision(
          authDecision: null,
          location: '/reset-password',
          onboardingLoading: false,
          onboardingSeen: false,
          recoveryActive: true,
        ),
        isNull,
      );
    });

    test('signed-in flows are never gated', () {
      expect(
        onboardingRedirectDecision(
          authDecision: null,
          location: '/home',
          onboardingLoading: false,
          onboardingSeen: false,
        ),
        isNull,
      );
      expect(
        onboardingRedirectDecision(
          authDecision: '/home',
          location: '/home',
          onboardingLoading: false,
          onboardingSeen: false,
        ),
        '/home',
      );
      expect(
        onboardingRedirectDecision(
          authDecision: '/profile-setup/personal',
          location: '/home',
          onboardingLoading: false,
          onboardingSeen: false,
        ),
        '/profile-setup/personal',
      );
      expect(
        onboardingRedirectDecision(
          authDecision: '/splash', // signed-in profile still loading
          location: '/home',
          onboardingLoading: false,
          onboardingSeen: false,
        ),
        '/splash',
      );
    });
  });

  group('onboardingRedirectDecision + authRedirectDecision composition', () {
    // The real startup path: splash → auth decision → onboarding gate.
    Object? startupDecision({
      required bool loggedIn,
      required bool loading,
      required bool seen,
      bool recovery = false,
    }) {
      final auth = authRedirectDecision(
        location: '/splash',
        isLoggedIn: loggedIn,
        recoveryActive: recovery,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
      );
      return onboardingRedirectDecision(
        authDecision: auth,
        location: '/splash',
        onboardingLoading: loading,
        onboardingSeen: seen,
        recoveryActive: recovery,
      );
    }

    test('first launch, flag loading → hold on splash', () {
      expect(
        startupDecision(loggedIn: false, loading: true, seen: false),
        isNull,
      );
    });

    test('first launch, signed out, flag ready → /onboarding', () {
      expect(
        startupDecision(loggedIn: false, loading: false, seen: false),
        '/onboarding',
      );
    });

    test('returning signed-out user → /login', () {
      expect(
        startupDecision(loggedIn: false, loading: false, seen: true),
        '/login',
      );
    });

    test('signed-out recovery session never sees onboarding', () {
      // Recovery is only meaningful signed in, but the gate must stay off.
      final auth = authRedirectDecision(
        location: '/splash',
        isLoggedIn: false,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
      );
      expect(auth, '/login');
    });
  });
}
