// test/student_signup_mobile_regression_test.dart
//
// Regression tests for student-only mobile signup and the required signup sequence:
// account details → email-code verification → profile setup → dashboard.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/auth/presentation/signup_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Student-Only Mobile Signup UI', () {
    testWidgets('does not render Student/Provider selector on mobile signup', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(440, 956));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Student brand indicators are present
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('ISKOLAR NG BAYAN'), findsOneWidget);
      expect(find.text('Free Forever For Students'), findsOneWidget);

      // Student/Provider role selector is completely removed from mobile signup
      expect(find.text('I am joining as:'), findsNothing);
      expect(find.text('Provider'), findsNothing);
      expect(find.text('Mobile number (optional)'), findsOneWidget);
    });

    testWidgets(
      'submitting mobile signup sends role=student metadata and routes to /verify-email',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(440, 956));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        Map<String, dynamic>? capturedBody;

        final client = GoTrueClient(
          url: 'https://example.com/auth/v1',
          autoRefreshToken: false,
          flowType: AuthFlowType.implicit,
          httpClient: MockClient((request) async {
            expect(request.url.path, '/auth/v1/signup');
            capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'id': 'student-uuid-123',
                'aud': 'authenticated',
                'email': 'student@up.edu.ph',
                'created_at': '2026-10-22T00:00:00Z',
                'user_metadata': capturedBody?['data'] ?? {},
              }),
              200,
            );
          }),
        );
        addTearDown(client.dispose);

        final router = GoRouter(
          initialLocation: '/signup',
          routes: [
            GoRoute(
              path: '/signup',
              builder: (_, _) => SignupScreen(client: client),
            ),
            GoRoute(
              path: '/verify-email',
              builder: (context, state) => Scaffold(
                body: Text(
                  'VerifyEmail: ${state.uri.queryParameters['email']}',
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Fill form fields
        final fields = find.byType(TextFormField);
        // Field 0: Full Name
        await tester.enterText(fields.at(0), 'Maya Santos Dela Cruz');
        // Field 1: Email
        await tester.enterText(fields.at(1), 'student@up.edu.ph');
        // Field 2: Password
        await tester.enterText(fields.at(2), 'Passw0rd!Secure');
        // Field 3: Confirm Password
        await tester.enterText(fields.at(3), 'Passw0rd!Secure');

        // Aux text field for school (matches hint text)
        final schoolFinder = find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText?.contains('UP Diliman') == true,
        );
        if (schoolFinder.evaluate().isNotEmpty) {
          await tester.enterText(schoolFinder, 'UP Diliman');
        }

        final signUpBtn = find.widgetWithText(ElevatedButton, 'Sign up');
        await tester.ensureVisible(signUpBtn);
        await tester.tap(signUpBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600)); // Success overlay
        await tester.pumpAndSettle();

        // Verify sent metadata explicitly includes role: 'student'
        expect(capturedBody, isNotNull);
        final data = capturedBody!['data'] as Map<String, dynamic>;
        expect(data['role'], 'student');
        expect(data['full_name'], 'Maya Santos Dela Cruz');
        expect(data.containsKey('phone'), isFalse);

        // Verify direct routing to /verify-email with encoded email query parameter
        expect(
          find.text('VerifyEmail: student@up.edu.ph'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'submitting mobile signup with valid mobile number normalizes and includes phone metadata',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(440, 956));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        Map<String, dynamic>? capturedBody;

        final client = GoTrueClient(
          url: 'https://example.com/auth/v1',
          autoRefreshToken: false,
          flowType: AuthFlowType.implicit,
          httpClient: MockClient((request) async {
            capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'id': 'student-uuid-456',
                'aud': 'authenticated',
                'email': 'student2@up.edu.ph',
                'created_at': '2026-10-22T00:00:00Z',
                'user_metadata': capturedBody?['data'] ?? {},
              }),
              200,
            );
          }),
        );
        addTearDown(client.dispose);

        final router = GoRouter(
          initialLocation: '/signup',
          routes: [
            GoRoute(
              path: '/signup',
              builder: (_, _) => SignupScreen(client: client),
            ),
            GoRoute(
              path: '/verify-email',
              builder: (context, state) => Scaffold(
                body: Text(
                  'VerifyEmail: ${state.uri.queryParameters['email']}',
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Juan Dela Cruz');
        await tester.enterText(fields.at(1), 'student2@up.edu.ph');
        await tester.enterText(fields.at(2), 'Passw0rd!Secure');
        await tester.enterText(fields.at(3), 'Passw0rd!Secure');

        final phoneFinder = find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText?.contains('917 890 1234') == true,
        );
        expect(phoneFinder, findsOneWidget);
        await tester.enterText(phoneFinder, '0917 890 1234');

        final signUpBtn = find.widgetWithText(ElevatedButton, 'Sign up');
        await tester.ensureVisible(signUpBtn);
        await tester.tap(signUpBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(capturedBody, isNotNull);
        final data = capturedBody!['data'] as Map<String, dynamic>;
        expect(data['role'], 'student');
        expect(data['phone'], '+639178901234');
      },
    );

    testWidgets(
      'submitting mobile signup with invalid mobile number halts submission and shows SnackBar error',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(440, 956));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        var signUpCalled = false;
        final client = GoTrueClient(
          url: 'https://example.com/auth/v1',
          autoRefreshToken: false,
          flowType: AuthFlowType.implicit,
          httpClient: MockClient((request) async {
            signUpCalled = true;
            return http.Response('{}', 200);
          }),
        );
        addTearDown(client.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: SignupScreen(client: client),
          ),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Juan Dela Cruz');
        await tester.enterText(fields.at(1), 'student3@up.edu.ph');
        await tester.enterText(fields.at(2), 'Passw0rd!Secure');
        await tester.enterText(fields.at(3), 'Passw0rd!Secure');

        final phoneFinder = find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText?.contains('917 890 1234') == true,
        );
        await tester.enterText(phoneFinder, '12345');

        final signUpBtn = find.widgetWithText(ElevatedButton, 'Sign up');
        await tester.ensureVisible(signUpBtn);
        await tester.tap(signUpBtn);
        await tester.pump();

        expect(signUpCalled, isFalse);
        expect(
          find.text('Enter a valid 10-digit mobile number or leave blank.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Signup Order: account details → email-code verification → profile setup → dashboard', () {
    test('authRedirectDecision routes incomplete profile from verify-email to profile setup after code verification establishes session', () {
      // 1. Prior to verification: unauthenticated user on /verify-email is allowed to stay
      final signedOutDecision = authRedirectDecision(
        location: '/verify-email',
        isLoggedIn: false,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
        onVerifyRoute: true,
      );
      expect(signedOutDecision, isNull);

      // 2. Once verifyOTP verifies the code, user is logged in but profile is incomplete
      // authRedirectDecision directs them directly to personal profile setup (Step 1)
      final afterCodeVerifiedDecision = authRedirectDecision(
        location: '/verify-email',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
        onVerifyRoute: true,
        profileSetupStep: 1,
      );
      expect(afterCodeVerifiedDecision, ProfileSetupRoute.personal);

      // 3. User completing profile setup lands on Dashboard (/home)
      final completedProfileDecision = authRedirectDecision(
        location: '/profile-setup/personal',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: false,
        onSetupRoute: true,
        profileLoading: false,
        profileComplete: true,
      );
      expect(completedProfileDecision, '/home');
    });
  });
}
