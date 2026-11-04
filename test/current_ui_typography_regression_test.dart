import 'package:scholaris/features/provider/presentation/provider_review_screen.dart';
import 'package:scholaris/features/applications/presentation/submission_confirmation_receipt_screen.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholaris/features/onboarding/presentation/onboarding_screen.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

void main() {
  testWidgets(
    'typography keeps the current welcome rather than legacy onboarding',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: scholarisTheme(),
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your next chapter starts here.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('intro-get-started-button')),
        findsOneWidget,
      );
      expect(find.text('GRANT ENGINE'), findsNothing);
    },
  );
  testWidgets(
    'receipt distinguishes scholarship title, grant amount and metadata',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final scholarship = Scholarship.fromJson({
        'id': 'receipt-style',
        'title': 'Precision Scholarship',
        'provider': 'Foundation',
        'min_gpa': 2.0,
        'amount': 50000,
        'is_active': true,
        'deadline': '2099-12-18',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentProfileProvider.overrideWith((ref) async => null)],
          child: MaterialApp(
            theme: scholarisTheme(),
            home: SubmissionConfirmationReceiptScreen(
              scholarship: scholarship,
              receiptId: 'TEST-123',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final title = tester.widget<Text>(find.text('Precision Scholarship'));
      final amount = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && w.data?.contains('Monthly Stipend') == true,
        ),
      );
      expect(title.style!.fontWeight, FontWeight.w600);
      expect(title.style!.fontSize, 13);
      expect(amount.style!.fontWeight, FontWeight.w700);
      expect(amount.style!.fontSize, 13);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'provider review preserves inherited tracking for title and action',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: scholarisTheme(),
          home: const ProviderReviewScreen(),
        ),
      );
      final title = tester.widget<Text>(find.text('Application Under Review'));
      final action = tester.widget<Text>(find.text('Back to Provider Sign In'));
      expect(title.style!.fontSize, 20);
      expect(title.style!.letterSpacing, -.15);
      expect(action.style!.fontWeight, FontWeight.w600);
      expect(action.style!.letterSpacing, -.4);
      expect(tester.takeException(), isNull);
    },
  );
}
