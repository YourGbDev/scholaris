import 'package:flutter_riverpod/flutter_riverpod.dart';
// Focused widget tests for the Verify Email screen (Day 13).
//
// The screen is rendered offline through a tiny GoRouter harness so that
// "Back to login" navigation can be exercised without a real router, and the
// resend button is verified as disabled when no email is present. The resend
// action itself calls Supabase, which is not reachable in tests, so its
// behavior is intentionally not exercised here.
//
// No network is involved.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/auth/presentation/verify_email_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget harness({String? email, GoTrueClient? client, bool recovery = false}) {
    final query = email == null
        ? ''
        : '?email=${Uri.encodeQueryComponent(email)}';
    final router = GoRouter(
      initialLocation: '/verify-email$query',
      routes: [
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => VerifyEmailScreen(
            email: state.uri.queryParameters['email'],
            client: client,
            recovery: recovery,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Verified home')),
        ),
        GoRoute(
          path: '/profile-setup/personal',
          builder: (_, _) => const Scaffold(body: Text('Profile setup step 1')),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (_, _) => const Scaffold(body: Text('Choose password')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('renders heading, email, resend, and back-to-login', (
    tester,
  ) async {
    await tester.pumpWidget(ProviderScope(child: harness(email: 'a@b.com')));
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('a@b.com'), findsOneWidget);
    expect(find.text('Resend email'), findsOneWidget);
    expect(find.text('Back to login'), findsOneWidget);
  });

  testWidgets('resend email is disabled when email is null', (tester) async {
    await tester.pumpWidget(ProviderScope(child: harness(email: null)));
    await tester.pumpAndSettle();

    final resendButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Resend email'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(resendButton.onPressed, isNull);
  });

  testWidgets('rejects an incomplete code before contacting Supabase', (
    tester,
  ) async {
    await tester.pumpWidget(ProviderScope(child: harness(email: 'a@b.com')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '123');
    await tester.ensureVisible(find.text('Verify code'));
    await tester.tap(find.text('Verify code'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter the 8-digit code from your email.'),
      findsOneWidget,
    );
  });

  for (final recovery in [false, true]) {
    testWidgets(
      'verified ${recovery ? 'recovery' : 'signup'} code creates the correct session',
      (tester) async {
        final client = GoTrueClient(
          url: 'https://example.com/auth/v1',
          autoRefreshToken: false,
          flowType: AuthFlowType.implicit,
          httpClient: MockClient(
            (request) async => http.Response(
              jsonEncode({
                'access_token': 'test-token',
                'refresh_token': 'refresh-token',
                'token_type': 'bearer',
                'expires_in': 3600,
                'user': {
                  'id': 'student-a',
                  'aud': 'authenticated',
                  'email': 'a@b.com',
                  'app_metadata': {},
                  'user_metadata': {},
                  'created_at': '2026-10-22T00:00:00Z',
                },
              }),
              200,
            ),
          ),
        );
        addTearDown(client.dispose);
        final events = <AuthChangeEvent>[];
        final subscription = client.onAuthStateChange.listen(
          (event) => events.add(event.event),
        );
        addTearDown(subscription.cancel);
        await tester.pumpWidget(
          ProviderScope(
            child: harness(
              email: 'a@b.com',
              client: client,
              recovery: recovery,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), '12345678');
        await tester.ensureVisible(find.text('Verify code'));
        await tester.tap(find.text('Verify code'));
        await tester.pumpAndSettle();
        expect(
          events,
          contains(
            recovery
                ? AuthChangeEvent.passwordRecovery
                : AuthChangeEvent.signedIn,
          ),
        );
        expect(client.currentSession?.user.id, 'student-a');
        expect(
          find.text(recovery ? 'Choose password' : 'Profile setup step 1'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'expired ${recovery ? 'recovery' : 'signup'} code stays on verification',
      (tester) async {
        Map<String, dynamic>? body;
        final client = GoTrueClient(
          url: 'https://example.com/auth/v1',
          autoRefreshToken: false,
          flowType: AuthFlowType.implicit,
          httpClient: MockClient((request) async {
            expect(request.url.path, '/auth/v1/verify');
            body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'msg': 'Token has expired or is invalid',
                'code': 'otp_expired',
              }),
              403,
            );
          }),
        );
        addTearDown(client.dispose);
        await tester.pumpWidget(
          ProviderScope(
            child: harness(
              email: 'a@b.com',
              client: client,
              recovery: recovery,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), '12345678');
        await tester.ensureVisible(find.text('Verify code'));
        await tester.tap(find.text('Verify code'));
        await tester.pumpAndSettle();
        expect(body?['email'], 'a@b.com');
        expect(body?['token'], '12345678');
        expect(body?['type'], recovery ? 'recovery' : 'email');
        expect(
          find.text(
            'That code is invalid or has expired. Try again or request a new code.',
          ),
          findsOneWidget,
        );
        expect(find.text('Choose password'), findsNothing);
        expect(find.text('Verified home'), findsNothing);
      },
    );
  }

  testWidgets(
    'successful resend prevents repeated requests for sixty seconds',
    (tester) async {
      var requests = 0;
      final client = GoTrueClient(
        url: 'https://example.com/auth/v1',
        autoRefreshToken: false,
        flowType: AuthFlowType.implicit,
        httpClient: MockClient((request) async {
          requests++;
          expect(request.url.path, '/auth/v1/resend');
          return http.Response('{}', 200);
        }),
      );
      addTearDown(client.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: harness(email: 'a@b.com', client: client),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Resend email'));
      await tester.tap(find.text('Resend email'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.text('Resend in 60s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      expect(find.text('Resend email'), findsOneWidget);
    },
  );

  testWidgets('back to login navigates to the login screen', (tester) async {
    await tester.pumpWidget(ProviderScope(child: harness(email: 'a@b.com')));
    await tester.pumpAndSettle();

    // The back link sits below the fold on the default test viewport (the V1
    // hero takes the top band); scroll it into view before tapping.
    await tester.ensureVisible(find.text('Back to login'));
    await tester.tap(find.text('Back to login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
