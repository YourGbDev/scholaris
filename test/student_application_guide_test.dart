import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/applications/presentation/submit_application_review_dialog.dart';

import 'student_detail_tour_test.dart' as fixture;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/home/presentation/widgets/student_application_guide.dart';
import 'package:scholaris/features/home/presentation/widgets/student_swipe_cue.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Geist')
          ..addFont(rootBundle.load('assets/fonts/geist/Geist-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/geist/Geist-SemiBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/geist/Geist-Bold.ttf')))
        .load();
  });
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  testWidgets(
    'one actual detail waits for bottom then Back to top before Apply',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        fixture.wrap(
          Scaffold(
            body: StudentApplicationGuide(
              initialStep: 8,
              exampleScholarship: fixture.scholarship,
              onExit: () {},
              onFinish: () {},
              onSelectTab: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ScholarshipDetailScreen), findsOneWidget);
      expect(find.text('Actual grant title'), findsOneWidget);
      final detail = tester.widget<ScholarshipDetailScreen>(
        find.byType(ScholarshipDetailScreen),
      );
      final scroll = detail.tour!.scrollController;
      detail.tour!.onApply();
      await tester.pumpAndSettle();
      expect(find.text('Review the scholarship'), findsOneWidget);
      expect(scroll.offset, 0);
      await tester.tap(find.byKey(const ValueKey('guide-advance')));
      await tester.pumpAndSettle();
      expect(find.text('Review the scholarship'), findsOneWidget);
      scroll.jumpTo(100);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('guide-advance')));
      await tester.pumpAndSettle();
      expect(find.text('Review the scholarship'), findsOneWidget);
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('guide-advance')));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Guide action: Back to top'),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel('Guide action: Back to top'));
      await tester.tap(find.bySemanticsLabel('Guide action: Back to top'));
      await tester.pumpAndSettle();
      expect(find.text('Ready to apply?'), findsOneWidget);
      expect(find.byType(ScholarshipDetailScreen), findsOneWidget);
      await tester.tap(
        find.bySemanticsLabel('Guide action: Start Application'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ScholarshipDetailScreen), findsNothing);
      expect(find.byType(SubmitApplicationReviewDialog), findsOneWidget);
      expect(find.text('Review & submit demo'), findsOneWidget);
      final review = tester.widget<SubmitApplicationReviewDialog>(
        find.byType(SubmitApplicationReviewDialog),
      );
      review.tour!.scrollController.jumpTo(
        review.tour!.scrollController.position.maxScrollExtent,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel('Guide action: Submit Application (Final)'),
      );
      await tester.pumpAndSettle();
      expect(find.text('You did it!'), findsOneWidget);
      expect(find.byType(SubmitApplicationReviewDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'readable note has exterior instruction and whole note advances',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StudentApplicationGuide(
                initialStep: 1,
                onExit: () {},
                onFinish: () {},
                onSelectTab: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('guide-note'));
      final hint = find.text('Tap anywhere to continue');
      expect(find.descendant(of: card, matching: hint), findsNothing);
      expect(
        tester.getTopLeft(hint).dy,
        greaterThan(tester.getBottomLeft(card).dy),
      );
      expect(
        tester
            .widget<Text>(find.text('View saved scholarships'))
            .style
            ?.fontFamily,
        'Geist',
      );
      await tester.tap(find.text('View saved scholarships'));
      await tester.pumpAndSettle();
      expect(find.text('Keep your applications moving'), findsOneWidget);
    },
  );
  testWidgets('notes and controls fit 320px at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StudentApplicationGuide(
              initialStep: 1,
              onExit: () {},
              onFinish: () {},
              onSelectTab: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guide-advance')));
    await tester.pumpAndSettle();
    expect(find.text('Keep your applications moving'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'side hand demonstrates an upward swipe and respects reduced motion',
    (tester) async {
      Future<double> position(double progress, bool reduced) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StudentSwipeCue(progress: progress, reducedMotion: reduced),
            ),
          ),
        );
        return tester.getTopLeft(find.byKey(const ValueKey('swipe-hand'))).dy;
      }

      final start = await position(0, false);
      expect(await position(.4, false), lessThan(start - 40));
      final still = await position(0, true);
      expect(await position(.4, true), still);
    },
  );
}
