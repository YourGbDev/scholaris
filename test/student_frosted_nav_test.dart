import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/home/presentation/widgets/student_selection_indicator.dart';
import 'package:scholaris/features/home/presentation/widgets/liquid_glass_pill.dart';

void main() {
  testWidgets(
    'dock and plus diffuse text with the same milky Gaussian glass and single rim',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentBottomNav(
              tabIndex: 0,
              onSelectTab: (_) {},
              onQuickAction: () {},
            ),
          ),
        ),
      );
      final surfaces = tester
          .widgetList<LiquidGlassPill>(find.byType(LiquidGlassPill))
          .toList();
      expect(surfaces, hasLength(2));
      for (final glass in surfaces) {
        expect(glass.coreBlur, 6.5);
        expect(glass.tintOpacity, .44);
      }
      final filters = find.descendant(
        of: find.byType(LiquidGlassPill),
        matching: find.byType(BackdropFilter),
      );
      expect(filters, findsNWidgets(4));
      for (final filter in filters.evaluate()) {
        expect(
          find.ancestor(
            of: find.byWidget(filter.widget),
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
          reason: 'Rim and core must not compound Gaussian blur.',
        );
      }
      final outlines = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(LiquidGlassPill),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((w) => w.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border != null);
      expect(outlines, hasLength(2));
      for (final outline in outlines) {
        expect(outline.border!.top.width, .8);
        expect(outline.border!.top.color, const Color(0xA6FFFFFF));
      }
      final label = tester.widget<Text>(find.text('Home'));
      expect(label.style!.fontSize, 11);
      expect(label.style!.fontWeight, FontWeight.w600);
      expect(label.style!.letterSpacing, -.2);
      final plus = tester.widget<Icon>(find.byIcon(Icons.add_rounded));
      expect(plus.size, 24);
      expect(plus.shadows, hasLength(4));
      expect(plus.color, const Color(0xFF141414));
      final selection = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('student-nav-moving-indicator')),
      );
      final lens = selection.decoration as BoxDecoration;
      expect(lens.gradient, isNull);
      expect(lens.color, const Color(0x1C1E4D2B));
      expect(lens.border, isNull);
      expect(lens.borderRadius, BorderRadius.circular(999));
    },
  );

  testWidgets(
    'selection leads in each direction, bulges 12px and redirects without jumping',
    (tester) async {
      Widget host(int index) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 320,
            height: 58,
            child: StudentSelectionIndicator(
              index: index,
              duration: const Duration(milliseconds: 400),
            ),
          ),
        ),
      );
      final marker = find.byKey(const ValueKey('student-nav-moving-indicator'));
      await tester.pumpWidget(host(0));
      final first = tester.getRect(marker);
      await tester.pumpWidget(host(3));
      await tester.pump(const Duration(milliseconds: 100));
      final stretched = tester.getRect(marker);
      expect(
        stretched.right - first.right,
        greaterThan(stretched.left - first.left),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final rightward = tester.getRect(marker);
      expect(rightward.height, closeTo(first.height + 12, .1));
      final dock = tester.getRect(find.byType(StudentSelectionIndicator));
      expect(rightward.top, closeTo(dock.top - 2, .1));
      await tester.pumpWidget(host(0));
      expect(tester.getRect(marker).left, closeTo(rightward.left, .1));
      expect(tester.getRect(marker).right, closeTo(rightward.right, .1));
      expect(tester.getRect(marker).height, closeTo(rightward.height, .1));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(3));
      await tester.pumpAndSettle();
      final last = tester.getRect(marker);
      await tester.pumpWidget(host(0));
      await tester.pump(const Duration(milliseconds: 100));
      final leftward = tester.getRect(marker);
      expect(
        last.left - leftward.left,
        greaterThan(last.right - leftward.right),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(marker), first);
    },
  );

  testWidgets(
    'active tab content magnifies briefly and returns to its anchored size',
    (tester) async {
      Widget host(int index, {bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(440, 900),
            disableAnimations: reduced,
          ),
          child: Scaffold(
            body: StudentBottomNav(
              tabIndex: index,
              onSelectTab: (_) {},
              onQuickAction: () {},
            ),
          ),
        ),
      );
      await tester.pumpWidget(host(0));
      await tester.pumpWidget(host(1));
      await tester.pump(const Duration(milliseconds: 200));
      double magnification() => tester
          .widgetList<Transform>(
            find.ancestor(
              of: find.text('Discover'),
              matching: find.byType(Transform),
            ),
          )
          .map((w) => w.transform.entry(0, 0))
          .reduce((a, b) => a > b ? a : b);
      expect(magnification(), closeTo(1.06, .001));
      await tester.pumpAndSettle();
      expect(magnification(), 1);
      await tester.pumpWidget(host(0, reduced: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
}
