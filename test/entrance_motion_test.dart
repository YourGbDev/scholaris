// Day 16-17 entrance motion tests: StaggeredEntrance widget, the shared
// entrance motion toolkit, and the default stagger timing.
//
// All animation is native Flutter (AnimationController + intervals), so tests
// can pump the virtual clock deterministically.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/shared/widgets/entrance.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void useReducedMotion(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  group('StaggeredEntrance', () {
    testWidgets('staggered items all settle at full opacity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredEntrance(
              children: const [Text('first'), Text('second'), Text('third')],
            ),
          ),
        ),
      );

      await tester.pump(
        EntranceMotion.total + const Duration(milliseconds: 100),
      );

      final fades = tester.widgetList<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fades, isNotEmpty);
      for (final fade in fades) {
        expect(fade.opacity.value, 1.0);
      }
      expect(find.text('first'), findsOneWidget);
      expect(find.text('third'), findsOneWidget);
    });

    testWidgets('reduced motion renders the settled state on the first frame', (
      tester,
    ) async {
      useReducedMotion(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredEntrance(
              children: const [Text('first'), Text('second')],
            ),
          ),
        ),
      );
      await tester.pump();

      final fades = tester.widgetList<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fades, isNotEmpty);
      for (final fade in fades) {
        expect(fade.opacity.value, 1.0);
      }
    });
  });
}