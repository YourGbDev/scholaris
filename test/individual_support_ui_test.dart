import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/dev/provider_preview/main.dart' as preview;
import 'package:scholaris/features/provider/repositories/support_repository.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [360.0, 1280.0]) {
    testWidgets('support budget edit and payout guidance at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(preview.buildApp(individualPreview: true));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(width < 900 ? 'Support' : 'Budget & support').first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Cycle budget'), findsOneWidget);
      expect(find.text('₱100,000'), findsWidgets);
      expect(
        find.textContaining('No support has been committed'),
        findsOneWidget,
      );
      await tester.tap(find.text('Edit budget'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cycle label'),
        'Semester 1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount in pesos'),
        '120000.50',
      );
      await tester.tap(find.text('Save record'));
      await tester.pumpAndSettle();
      expect(find.text('₱120,000.50'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'sent payment does not become student-confirmed in provider workspace',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(preview.buildApp(individualPreview: true));
      await tester.pumpAndSettle();
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(Navigator).first),
      );
      final repo = scope.read(supportRepositoryProvider);
      // Drive the actual review flow so the approved student appears in the ledger.
      await tester.tap(find.text('Applications').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Review Application & Decide'));
      await tester.tap(find.text('Review Application & Decide'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve Application'));
      await tester.pumpAndSettle();
      expect(find.textContaining('This approval commits'), findsOneWidget);
      await tester.tap(find.text('Approve Application').last);
      await tester.pumpAndSettle();
      await repo.recordPayment('app-1', 1000000, 'gcash', 'TEST-001');
      await repo.schedule('app-1', DateTime(2026, 11, 1));
      scope.invalidate(supportLedgerProvider);
      await tester.tap(find.text('Budget & support').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Student confirmed ₱0'), findsOneWidget);
      expect(find.textContaining('Recorded sent:'), findsOneWidget);
      await tester.ensureVisible(find.text('Clear planned date'));
      await tester.tap(find.text('Clear planned date'));
      await tester.pumpAndSettle();
      expect((await repo.load()).commitment('app-1')!['next_due_on'], isNull);
      await tester.ensureVisible(find.text('Record payment sent'));
      await tester.tap(find.text('Record payment sent'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount in pesos'),
        '999999',
      );
      await tester.tap(find.text('Confirm record'));
      await tester.pumpAndSettle();
      expect(find.text('Amount exceeds remaining support'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await repo.recordPayment('app-1', 4000000, 'bank', 'TEST-002');
      await repo.schedule('app-1', DateTime(2026, 11, 1));
      scope.invalidate(supportLedgerProvider);
      await tester.pumpAndSettle();
      expect(find.textContaining('Support fully marked sent'), findsOneWidget);
      expect(find.textContaining('Planned payment date:'), findsNothing);
    },
  );
}
