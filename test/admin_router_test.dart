import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/app/router.dart';

void main() {
  group('authRedirectDecision: role=admin', () {
    test('signed-in admin outside /admin-home redirects to /admin-home', () {
      final redirect = authRedirectDecision(
        location: '/login',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: true,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
        role: 'admin',
      );
      expect(redirect, AdminRoute.home);
    });

    test('signed-in admin on /admin-home stays there (returns null)', () {
      final redirect = authRedirectDecision(
        location: AdminRoute.home,
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
        role: 'admin',
      );
      expect(redirect, isNull);
    });

    test('signed-out user cannot access /admin-home and is bounced to /login', () {
      final redirect = authRedirectDecision(
        location: AdminRoute.home,
        isLoggedIn: false,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
        role: 'admin',
      );
      expect(redirect, '/login');
    });

    test('active recovery session takes precedence over role=admin', () {
      final redirect = authRedirectDecision(
        location: AdminRoute.home,
        isLoggedIn: true,
        recoveryActive: true,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
        role: 'admin',
      );
      expect(redirect, AuthRoute.resetPassword);
    });

    test('onboardingRedirectDecision treats /admin-home as a signed-in destination', () {
      final result = onboardingRedirectDecision(
        authDecision: AdminRoute.home,
        location: '/login',
        onboardingLoading: false,
        onboardingSeen: false,
      );
      expect(result, AdminRoute.home);
    });
  });
}
