// Provider signup screen: validation and submission behavior.
// Mirrors auth_regression_test.dart patterns.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/provider/presentation/provider_signup_screen.dart';

void main() {
  group('ProviderSignupScreen', () {
    testWidgets('renders form fields and submit button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProviderSignupScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Become a Scholarship Provider'), findsOneWidget);
      expect(find.text('Organization Name'), findsOneWidget);
      expect(find.text('Contact Person Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Apply to become a provider'), findsOneWidget);
    });

    testWidgets('validates required fields on empty submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProviderSignupScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Apply to become a provider'),
      );
      await tester.pump();

      expect(find.text('Enter your organization name.'), findsOneWidget);
      expect(
        find.text('Enter the contact person name.'),
        findsOneWidget,
      );
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter a password.'), findsOneWidget);
      expect(find.text('Confirm your password.'), findsOneWidget);
    });

    testWidgets('validates email format, password length, and matching confirm',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProviderSignupScreen()),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Acme Inc');
      await tester.enterText(fields.at(1), 'Jane Doe');
      await tester.enterText(fields.at(2), 'bad-email');
      await tester.enterText(fields.at(3), 'short');
      await tester.enterText(fields.at(4), 'different');

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Apply to become a provider'),
      );
      await tester.pump();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(
        find.text('Password must be at least 8 characters.'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });
}
