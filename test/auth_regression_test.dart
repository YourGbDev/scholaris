// Regression tests for Day 2 authentication screens. These exercise the
// client-side validation and rendering of the login/signup flows without
// touching the network (validation short-circuits before any Supabase call).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/auth/presentation/signup_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('LoginScreen', () {
    testWidgets('renders email/password form', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('rejects an invalid email before calling the API',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
    });

    testWidgets('rejects an empty password', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'student@example.com',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your password.'), findsOneWidget);
    });
  });

  group('SignupScreen', () {
    testWidgets('renders the account creation form', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('validates required fields locally', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your full name.'), findsOneWidget);
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter a password.'), findsOneWidget);
      expect(find.text('Confirm your password.'), findsOneWidget);
    });

    testWidgets('validates email format, password length and matching confirm',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Maria Santos');
      await tester.enterText(fields.at(1), 'bad-email');
      await tester.enterText(fields.at(2), 'short');
      await tester.enterText(fields.at(3), 'different');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(
        find.text('Password must be at least 8 characters.'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('links to the login screen', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

      expect(find.text('Log in'), findsOneWidget);
    });
  });
}
