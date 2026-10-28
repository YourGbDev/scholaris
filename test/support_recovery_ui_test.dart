import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/dev/provider_preview/fake_support_repository.dart';
import 'package:scholaris/dev/provider_preview/fake_support_concerns.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/provider/repositories/support_repository.dart';
import 'package:scholaris/features/provider/repositories/support_concern_repository.dart';
import 'package:scholaris/features/provider/presentation/widgets/support_payment_correction.dart';
import 'package:scholaris/features/applications/presentation/student_support_concerns.dart';
import 'package:scholaris/admin/screens/support_concerns_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
    'correction preserves original row and requires explicit reason',
    (tester) async {
      final repo = PreviewSupportRepository();
      repo.commitments.add({
        'application_id': 'a',
        'scholarship_id': 's',
        'amount_cents': 10000,
      });
      repo.payments.add({
        'id': 'p',
        'application_id': 'a',
        'amount_cents': 10000,
        'reference': 'REF',
        'method': 'bank',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supportRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: SupportPaymentCorrection(payment: repo.payments.first),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Correct record'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark entered in error'));
      await tester.pumpAndSettle();
      expect(
        find.text('Explain the correction in at least 5 characters'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextFormField),
        'Wrong amount entered',
      );
      await tester.tap(find.text('Mark entered in error'));
      await tester.pumpAndSettle();
      expect(repo.payments.length, 1);
      expect((await repo.load()).sent('a'), 0);
      expect(find.textContaining('Entered in error:'), findsOneWidget);
    },
  );
  for (final width in [360.0, 1280.0]) {
    testWidgets(
      'student private reporting validates and shows status at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = PreviewSupportConcerns();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWithValue('student'),
              supportConcernRepositoryProvider.overrideWithValue(repo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: StudentSupportConcerns(applicationId: 'a'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Report a problem'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Submit private report'));
        await tester.pumpAndSettle();
        expect(
          find.text('Please include at least 10 characters'),
          findsOneWidget,
        );
        await tester.enterText(
          find.byType(TextFormField),
          'I have checked my account but the payment has not arrived.',
        );
        await tester.tap(find.text('Submit private report'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Payment not received · open'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'admin gives student a review update without changing provider access',
    (tester) async {
      final repo = PreviewSupportConcerns();
      await repo.report(
        'a',
        'unsafe_request',
        'Unsafe private meeting request from provider.',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('admin'),
            supportConcernRepositoryProvider.overrideWithValue(repo),
            supportRepositoryProvider.overrideWithValue(
              PreviewSupportRepository(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SupportConcernsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unsafe or inappropriate request'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start review'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'We are reviewing the records you submitted.',
      );
      await tester.tap(find.text('Save update'));
      await tester.pumpAndSettle();
      expect(find.text('under review'), findsOneWidget);
      expect(
        find.textContaining('Latest update: We are reviewing'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'confirmed payment offers scoped platform review without changing receipt',
    (tester) async {
      final repo = PreviewSupportRepository();
      final payment = <String, dynamic>{
        'id': 'p',
        'received_at': '2026-10-23T00:00:00Z',
      };
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supportRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(body: SupportPaymentCorrection(payment: payment)),
          ),
        ),
      );
      await tester.tap(find.text('Request platform review'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Reference needs administrative correction.',
      );
      await tester.tap(find.text('Submit review request'));
      await tester.pumpAndSettle();
      expect(
        repo.reviewRequests['p'],
        'Reference needs administrative correction.',
      );
      expect(payment['received_at'], '2026-10-23T00:00:00Z');
      expect(find.text('Correct record'), findsNothing);
    },
  );
  testWidgets(
    'admin sees exact provider-requested payment and correct update audience',
    (tester) async {
      final concerns = PreviewSupportConcerns();
      concerns.rows.add({
        'id': 'request',
        'application_id': 'a',
        'reporter_id': 'provider',
        'category': 'payment_record_correction',
        'description': 'Please correct this payment reference.',
        'status': 'open',
        'payment_id': 'payment-target',
      });
      final support = PreviewSupportRepository();
      support.payments.addAll([
        {
          'id': 'payment-target',
          'application_id': 'a',
          'amount_cents': 10000,
          'reference': 'TARGET',
          'received_at': '2026-10-23T00:00:00Z',
          'sent_at': '2026-10-22T00:00:00Z',
        },
        {
          'id': 'other',
          'application_id': 'a',
          'amount_cents': 20000,
          'reference': 'OTHER',
        },
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('admin'),
            supportConcernRepositoryProvider.overrideWithValue(concerns),
            supportRepositoryProvider.overrideWithValue(support),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SupportConcernsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Provider payment correction request'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Payment ID: payment-target'), findsOneWidget);
      expect(find.textContaining('OTHER'), findsNothing);
      expect(find.textContaining('Recorded sent:'), findsOneWidget);
      await tester.ensureVisible(find.text('Start review'));
      await tester.tap(find.text('Start review'));
      await tester.pumpAndSettle();
      expect(find.text('Update for provider'), findsOneWidget);
      expect(find.textContaining('visible to the provider'), findsOneWidget);
    },
  );
}
