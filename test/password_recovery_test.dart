// Focused tests for Day 7 — Password Reset / Account Recovery.
//
// Covers:
//   * password-recovery auth-state handling (recovery flag set by the session
//     boundary and exposed through passwordRecoveryProvider)
//   * recovery-mode clearing after a successful password update and on
//     sign-out
//   * forgot-password screen rendering and local validation
//   * reset-password screen rendering and local validation
//   * router redirect behavior during recovery (pure decision function)
//   * login screen wiring the "Forgot password?" action to the request screen
//
// All tests run without a network or a real Supabase instance: screens validate
// locally before any API call, and the redirect decision is a pure function.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/app/recovery_redirect.dart';
import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/auth/presentation/forgot_password_screen.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/auth/presentation/reset_password_screen.dart';

/// A controllable [AuthSessionNotifier]: starts signed out and lets the test
/// drive sign-in / recovery / password-update / sign-out like the real session
/// boundary would after observing Supabase auth events.
class _TestAuthNotifier extends AuthSessionNotifier {
  @override
  AuthSession? build() => null;

  void signInAs(String userId) => state = AuthSession(userId: userId);
  void enterRecovery(String userId) =>
      state = AuthSession(userId: userId, passwordRecovery: true);
  void completePasswordUpdate() => state = AuthSession(
        userId: state!.userId,
        passwordRecovery: false,
      );
  void signOut() => state = null;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('password recovery — auth state handling', () {
    test('a recovery session sets passwordRecoveryProvider and the user id',
        () {
      final auth = _TestAuthNotifier();
      final container = ProviderContainer(
        overrides: [authSessionProvider.overrideWith(() => auth)],
      );
      addTearDown(container.dispose);
      // Force the auth provider element to exist so the controllable notifier
      // is bound to the container before any test drives state.
      container.read(authSessionProvider);

      expect(container.read(passwordRecoveryProvider), isFalse);
      expect(container.read(currentUserIdProvider), isNull);

      auth.enterRecovery('user-a');

      expect(container.read(passwordRecoveryProvider), isTrue);
      expect(container.read(currentUserIdProvider), 'user-a');
      expect(container.read(authSessionProvider)!.passwordRecovery, isTrue);
    });

    test('a normal sign-in does not enter recovery mode', () {
      final auth = _TestAuthNotifier();
      final container = ProviderContainer(
        overrides: [authSessionProvider.overrideWith(() => auth)],
      );
      addTearDown(container.dispose);
      container.read(authSessionProvider);

      auth.signInAs('user-a');

      expect(container.read(passwordRecoveryProvider), isFalse);
      expect(container.read(currentUserIdProvider), 'user-a');
    });

    test('a successful password update clears recovery but keeps the session',
        () {
      final auth = _TestAuthNotifier();
      final container = ProviderContainer(
        overrides: [authSessionProvider.overrideWith(() => auth)],
      );
      addTearDown(container.dispose);
      container.read(authSessionProvider);

      auth.enterRecovery('user-a');
      expect(container.read(passwordRecoveryProvider), isTrue);

      // Supabase emits userUpdated after updateUser; the boundary must mirror
      // that by keeping the user signed in but leaving recovery mode.
      auth.completePasswordUpdate();

      expect(container.read(passwordRecoveryProvider), isFalse);
      expect(container.read(currentUserIdProvider), 'user-a');
    });

    test('sign-out clears recovery mode', () {
      final auth = _TestAuthNotifier();
      final container = ProviderContainer(
        overrides: [authSessionProvider.overrideWith(() => auth)],
      );
      addTearDown(container.dispose);
      container.read(authSessionProvider);

      auth.enterRecovery('user-a');
      expect(container.read(passwordRecoveryProvider), isTrue);

      auth.signOut();

      expect(container.read(passwordRecoveryProvider), isFalse);
      expect(container.read(currentUserIdProvider), isNull);
      expect(container.read(authSessionProvider), isNull);
    });
  });

  group('forgot-password screen', () {
    testWidgets('renders the request form and back-to-login link',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ForgotPasswordScreen()),
      );

      expect(find.text('Scholaris'), findsOneWidget);
      expect(find.text('Reset your password'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('rejects an invalid email before any API call',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ForgotPasswordScreen()),
      );

      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
    });

    testWidgets('rejects an empty email', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ForgotPasswordScreen()),
      );

      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email.'), findsOneWidget);
    });
  });

  group('reset-password screen', () {
    testWidgets('renders the set-new-password form and sign-out link',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));

      expect(find.text('Scholaris'), findsOneWidget);
      expect(find.text('Set new password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Update password'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('rejects empty, short and mismatched passwords locally',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));

      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a new password.'), findsOneWidget);
      expect(find.text('Confirm your new password.'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'short');
      await tester.enterText(fields.at(1), 'different');
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters.'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });

  group('router redirect during recovery', () {
    test('a recovery session forces /reset-password from any other location',
        () {
      for (final location in ['/home', '/login', '/splash', '/profile-setup']) {
        expect(
          authRedirectDecision(
            location: location,
            isLoggedIn: true,
            recoveryActive: true,
            onAuthRoute: location == '/login' || location == '/signup',
            onSetupRoute: location.startsWith('/profile-setup'),
            profileLoading: false,
            profileComplete: true,
          ),
          '/reset-password',
          reason: 'from $location recovery must win',
        );
      }
    });

    test('recovery mode lets the user stay on /reset-password', () {
      expect(
        authRedirectDecision(
          location: '/reset-password',
          isLoggedIn: true,
          recoveryActive: true,
          onAuthRoute: false,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: true,
        ),
        isNull,
      );
    });

    test('recovery branch is decided without profile state', () {
      // Even if the profile were reported complete, recovery must still win —
      // proving the decision is taken before any profile-based routing.
      expect(
        authRedirectDecision(
          location: '/home',
          isLoggedIn: true,
          recoveryActive: true,
          onAuthRoute: false,
          onSetupRoute: false,
          profileLoading: true,
          profileComplete: false,
        ),
        '/reset-password',
      );
    });

    test('/reset-password is protected without a recovery session', () {
      expect(
        authRedirectDecision(
          location: '/reset-password',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: false,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: true,
        ),
        '/login',
      );
    });

    test('/forgot-password is always reachable', () {
      // Signed out, no recovery: still allowed.
      expect(
        authRedirectDecision(
          location: '/forgot-password',
          isLoggedIn: false,
          recoveryActive: false,
          onAuthRoute: false,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: false,
        ),
        isNull,
      );
      // Signed in with a complete profile: still allowed.
      expect(
        authRedirectDecision(
          location: '/forgot-password',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: false,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: true,
        ),
        isNull,
      );
    });

    test('normal signed-out routing is unchanged', () {
      expect(
        authRedirectDecision(
          location: '/login',
          isLoggedIn: false,
          recoveryActive: false,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: false,
        ),
        isNull,
      );
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

    test('normal signed-in routing is unchanged', () {
      expect(
        authRedirectDecision(
          location: '/home',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: false,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: true,
        ),
        isNull,
      );
      expect(
        authRedirectDecision(
          location: '/login',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: true,
        ),
        '/home',
      );
      expect(
        authRedirectDecision(
          location: '/home',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: false,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: false,
        ),
        '/profile-setup/personal',
      );
    });
  });

  group('password recovery — deep-link redirect target', () {
    test('resetPasswordRedirect is the single source of truth', () {
      // The value resetPasswordRedirect is the constant that the
      // forgot-password screen passes as redirectTo, that the Android
      // manifest declares as an intent-filter, and that the iOS Info.plist
      // registers as a URL scheme. All three must match this exact string.
      // On non-web (tests run on the Dart VM) the getter must return the
      // mobile custom scheme unchanged.
      expect(resetPasswordRedirect, 'scholaris://reset-password');

      final uri = Uri.parse(resetPasswordRedirect);
      expect(uri.scheme, 'scholaris');
      expect(uri.host, 'reset-password');
      expect(uri.hasQuery, isFalse);
    });

    test('web redirect targets the /reset-password route on the app origin', () {
      // Browsers cannot open the scholaris:// custom scheme, so on web the
      // recovery link must return to the HTTP(S) origin serving the app with
      // the reset-password route. The origin is read from the requesting page
      // at runtime; these cases mirror a local `flutter run` server and a
      // page already on the forgot-password screen.
      expect(
        webResetPasswordRedirectFrom(
          Uri.parse('http://localhost:8080/'),
        ),
        'http://localhost:8080/reset-password',
      );
      expect(
        webResetPasswordRedirectFrom(
          Uri.parse('http://localhost:8080/forgot-password'),
        ),
        'http://localhost:8080/reset-password',
      );
      // Query and fragment on the requesting page must not leak into the
      // recovery redirect.
      expect(
        webResetPasswordRedirectFrom(
          Uri.parse('http://localhost:8080/?utm_source=test'),
        ),
        'http://localhost:8080/reset-password',
      );
    });
  });

  group('login screen wiring', () {
    testWidgets('"Forgot password?" navigates to the request screen',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset your password'), findsOneWidget);
    });
  });
}
