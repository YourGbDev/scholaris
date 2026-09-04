// Focused widget tests for the Verify Email screen (Day 13).
//
// The screen is rendered offline through a tiny GoRouter harness so that
// "Back to login" navigation can be exercised without a real router, and the
// resend button is verified as disabled when no email is present. The resend
// action itself calls Supabase, which is not reachable in tests, so its
// behavior is intentionally not exercised here.
//
// No network is involved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/auth/presentation/verify_email_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget harness({String? email}) {
    final query =
        email == null ? '' : '?email=${Uri.encodeQueryComponent(email)}';
    final router = GoRouter(
      initialLocation: '/verify-email$query',
      routes: [
        GoRoute(
          path: '/verify-email',
          builder: (context, state) =>
              VerifyEmailScreen(email: state.uri.queryParameters['email']),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('renders heading, email, resend, and back-to-login',
      (tester) async {
    await tester.pumpWidget(harness(email: 'a@b.com'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('a@b.com'), findsOneWidget);
    expect(find.text('Resend email'), findsOneWidget);
    expect(find.text('Back to login'), findsOneWidget);
  });

  testWidgets('resend email is disabled when email is null', (tester) async {
    await tester.pumpWidget(harness(email: null));
    await tester.pumpAndSettle();

    final resendButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Resend email'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(resendButton.onPressed, isNull);
  });

  testWidgets('back to login navigates to the login screen', (tester) async {
    await tester.pumpWidget(harness(email: 'a@b.com'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
