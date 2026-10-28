import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/dev/provider_preview/fake_support_repository.dart';
import 'package:scholaris/features/applications/presentation/student_support_receipts.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/provider/repositories/support_repository.dart';

class StudentLedger extends PreviewSupportRepository {
  @override
  Future<void> confirmReceipt(String id) async {
    payments.firstWhere((p) => p['id'] == id)['received_at'] =
        '2026-10-23T01:00:00Z';
  }
}

void main() {
  testWidgets(
    'student receipt requires explicit confirmation and can be declined',
    (tester) async {
      final repo = StudentLedger();
      repo.payments.add({
        'id': 'p',
        'application_id': 'a',
        'amount_cents': 1000000,
        'method': 'gcash',
        'reference': 'T-001',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('student'),
            supportRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(body: StudentSupportReceipts(applicationId: 'a')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Receipt is not confirmed'), findsOneWidget);
      await tester.tap(find.text('Confirm receipt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Receipt is not confirmed'), findsOneWidget);
      await tester.tap(find.text('Confirm receipt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, received'));
      await tester.pumpAndSettle();
      expect(
        find.text('You confirmed receipt. This is not bank verification.'),
        findsOneWidget,
      );
      expect(find.text('Confirm receipt'), findsNothing);
    },
  );
}
