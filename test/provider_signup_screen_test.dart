// test/provider_signup_screen_test.dart
// Tests the new multi-step Provider Signup flows for both Organization and Individual providers.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/provider/presentation/provider_signup_screen.dart';

void main() {
  group('ProviderSignupScreen Multi-step Flows', () {
    testWidgets('renders Organization provider Step 1 by default', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProviderSignupScreen(initialType: 'organization'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Organization Provider'), findsWidgets);
      expect(find.text('Individual Provider'), findsWidgets);
      expect(find.text('Organization Name'), findsOneWidget);
      expect(find.text('Organization Type'), findsOneWidget);
      expect(find.text('SEC / BIR Registration Number'), findsOneWidget);
      expect(find.text('Proceed to Representative Details'), findsOneWidget);
    });

    testWidgets('validates organization details on step 1 submission', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProviderSignupScreen(initialType: 'organization'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nextBtn = find.text('Proceed to Representative Details');
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('Enter your organization name.'), findsOneWidget);
      expect(find.text('Enter SEC or BIR registration number.'), findsOneWidget);
    });

    testWidgets('switches to Individual provider flow and renders Step 1', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProviderSignupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the Individual tab
      final indivTab = find.text('Individual Provider').first;
      await tester.ensureVisible(indivTab);
      await tester.tap(indivTab);
      await tester.pumpAndSettle();

      expect(find.text('Full Legal Name'), findsOneWidget);
      expect(find.text('Personal Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Philippine Mobile Number'), findsOneWidget);
      expect(find.text('Proceed to Identity & Verification'), findsOneWidget);
    });

    testWidgets('validates Individual Step 1 inputs: mobile number and advances to Step 2', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProviderSignupScreen(initialType: 'individual'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      // 0: Name, 1: Email, 2: Mobile, 3: Password, 4: Confirm Password
      await tester.enterText(fields.at(0), 'Juan Dela Cruz');
      await tester.enterText(fields.at(1), 'juan@example.ph');
      await tester.enterText(fields.at(2), '12345'); // Invalid PH number
      await tester.enterText(fields.at(3), 'Pass1234!');
      await tester.enterText(fields.at(4), 'Pass1234!');

      final nextBtn = find.text('Proceed to Identity & Verification');
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid PH mobile number (e.g. 09171234567 or +639171234567).'), findsOneWidget);

      // Now enter valid PH mobile number
      await tester.enterText(fields.at(2), '09171234567');
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Should advance to Step 2
      expect(find.text('Government ID Type'), findsOneWidget);
      expect(find.text('Government ID Number'), findsOneWidget);
      expect(find.text('Government ID Photo (Front)'), findsOneWidget);
      expect(find.text('Selfie with ID (Optional)'), findsOneWidget);
      expect(find.text('Source of Funds'), findsOneWidget);
      expect(find.text('Monthly Giving Budget Bracket'), findsOneWidget);
      expect(find.textContaining('I consent to the collection'), findsOneWidget);
    });
  });
}
