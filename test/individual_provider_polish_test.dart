import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/dev/provider_preview/main.dart' as preview;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('review shortcut opens the combined awaiting review filter', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(preview.buildApp(individualPreview: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review applications'));
    await tester.pumpAndSettle();
    final chip = tester.widget<ChoiceChip>(find.ancestor(of: find.textContaining('Awaiting review').last, matching: find.byType(ChoiceChip)).first);
    expect(chip.selected, isTrue);
    expect(find.text('Sofia Cruz'), findsOneWidget);
  });
  testWidgets('individual account actions sit at the bottom of the desktop sidebar', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(preview.buildApp(individualPreview: true));
    await tester.pumpAndSettle();
    final signOut = tester.getRect(find.text('Sign out'));
    expect(signOut.bottom, greaterThan(800));
    expect(signOut.bottom, lessThanOrEqualTo(900));
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 1280.0]) {
    testWidgets(
      'individual review, scholarships and profile remain usable at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(preview.buildApp(individualPreview: true));
        await tester.pumpAndSettle();
        expect(find.text('Hi, Elena — a little support. A new beginning.'), findsOneWidget);
        await tester.tap(find.text('Applications').first);
        await tester.pumpAndSettle();
        expect(find.text('Your support summary'), findsOneWidget);
        expect(find.text('Approved award value'), findsNothing);
        expect(find.byType(ChoiceChip), findsWidgets);
        expect(find.text('Sofia Cruz'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.text(width < 900 ? 'Scholarships' : 'My scholarships').first,
        );
        await tester.pumpAndSettle();
        expect(find.text('My scholarships'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.text(width < 900 ? 'Profile' : 'Profile & settings').first,
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Personal statement (not available yet)'),
          findsOneWidget,
        );
        expect(find.text('Console View Mode'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'individual preview can decide without organization endorsement',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(preview.buildApp(individualPreview: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Applications').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Review Application & Decide'));
      await tester.tap(find.text('Review Application & Decide'));
      await tester.pumpAndSettle();
      expect(
        find.text('Awaiting a separate reviewer endorsement.'),
        findsNothing,
      );
      expect(find.textContaining('Approve'), findsWidgets);
      expect(find.text('Provider notes'), findsOneWidget);
      expect(find.text('Candidate Evaluation'), findsNothing);
      expect(find.textContaining('COHORT'), findsNothing);
      expect(find.text('Decline application'), findsOneWidget);
    },
  );
}
