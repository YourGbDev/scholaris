import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

  group('authRedirectDecision: non-admin protection on /admin-home', () {
    test('signed-in student with complete profile attempting /admin-home is redirected to /home', () {
      final redirect = authRedirectDecision(
        location: AdminRoute.home,
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

    test('signed-in student with incomplete profile attempting /admin-home is redirected to setup', () {
      final redirect = authRedirectDecision(
        location: AdminRoute.home,
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
        role: 'student',
      );
      expect(redirect, ProfileSetupRoute.personal);
    });

    test('signed-in provider attempting /admin-home is redirected to /provider-home', () {
      final redirect = authRedirectDecision(
        location: AdminRoute.home,
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
        role: 'provider',
      );
      expect(redirect, ProviderRoute.home);
    });

    test('signed-in non-admin attempting /admin-home fails closed during profileLoading', () {
      final redirect = authRedirectDecision(
        location: AdminRoute.home,
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: true,
        profileComplete: true,
        role: 'student',
      );
      expect(redirect, '/home');
    });

    test('signed-in user with arbitrary unknown role attempting /admin-home is redirected to /home', () {
      final redirect = authRedirectDecision(
        location: AdminRoute.home,
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: true,
        role: 'guest',
      );
      expect(redirect, '/home');
    });
  });

  group('GoRouter context.go("/admin-home") unauthorized redirection', () {
    Widget buildRouterApp({
      required String role,
      required bool profileComplete,
    }) {
      final router = GoRouter(
        initialLocation: role == 'provider' ? '/provider-home' : '/home',
        redirect: (context, state) => authRedirectDecision(
          location: state.matchedLocation,
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: false,
          onVerifyRoute: false,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: profileComplete,
          role: role,
        ),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.go('/admin-home'),
                  child: const Text('Student Navigate Admin'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/provider-home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.go('/admin-home'),
                  child: const Text('Provider Navigate Admin'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/admin-home',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Admin Dashboard Screen')),
            ),
          ),
        ],
      );

      return MaterialApp.router(routerConfig: router);
    }

    testWidgets('student calling context.go("/admin-home") is redirected away to /home', (tester) async {
      await tester.pumpWidget(buildRouterApp(role: 'student', profileComplete: true));
      await tester.pumpAndSettle();

      expect(find.text('Student Navigate Admin'), findsOneWidget);
      expect(find.text('Admin Dashboard Screen'), findsNothing);

      // Attempt navigation to /admin-home
      await tester.tap(find.text('Student Navigate Admin'));
      await tester.pumpAndSettle();

      // Verified: Redirected away from /admin-home back to /home
      expect(find.text('Admin Dashboard Screen'), findsNothing);
      expect(find.text('Student Navigate Admin'), findsOneWidget);
    });

    testWidgets('provider calling context.go("/admin-home") is redirected away to /provider-home', (tester) async {
      await tester.pumpWidget(buildRouterApp(role: 'provider', profileComplete: false));
      await tester.pumpAndSettle();

      expect(find.text('Provider Navigate Admin'), findsOneWidget);
      expect(find.text('Admin Dashboard Screen'), findsNothing);

      // Attempt navigation to /admin-home
      await tester.tap(find.text('Provider Navigate Admin'));
      await tester.pumpAndSettle();

      // Verified: Redirected away from /admin-home back to /provider-home
      expect(find.text('Admin Dashboard Screen'), findsNothing);
      expect(find.text('Provider Navigate Admin'), findsOneWidget);
    });
  });
}
