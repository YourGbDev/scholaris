import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/dev/admin_preview/main.dart' as preview;
import 'package:scholaris/admin/screens/platform_overview_screen.dart';
import 'package:scholaris/admin/screens/reports_safety_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final size in [
    const Size(360, 800),
    const Size(440, 956),
    const Size(1280, 800),
    const Size(1280, 420),
  ]) {
    testWidgets(
      'owner workspace navigation at ${size.width}x${size.height} with large text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(preview.buildAdminPreview());
        await tester.pumpAndSettle();
        final scroll = find
            .descendant(
              of: find.byType(PlatformOverviewScreen),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('Review providers'),
          200,
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        expect(find.text('2 pending provider applications'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Review safety reports'),
          200,
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Review safety reports'));
        await tester.pumpAndSettle();
        expect(find.text('Reports & safety'), findsWidgets);
        await tester.scrollUntilVisible(
          find.text('Bright Futures Scholarship'),
          200,
          scrollable: find
              .descendant(
                of: find.byType(ReportsSafetyScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Bright Futures Scholarship'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'expanded platform statistics support 200 percent text on mobile',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(preview.buildAdminPreview());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Platform statistics'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(PlatformOverviewScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Platform statistics'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'student reporting demonstration records a fictional friend report only',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(preview.buildAdminPreview());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preview student report'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Nothing is submitted to Scholaris'),
        findsOneWidget,
      );
      await tester.tap(find.text('It happened to me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Someone told me').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'What happened?'),
        'Fictional example: a friend described an unsafe private meeting request.',
      );
      await tester.tap(find.text('Add fictional report'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('2 urgent reports need review'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
