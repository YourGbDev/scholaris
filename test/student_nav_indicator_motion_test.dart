import 'package:scholaris/features/home/presentation/widgets/liquid_glass_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';

void main() {
  testWidgets(
    'tab tint eases from its current color and Reduced Motion snaps immediately',
    (tester) async {
      Widget host(int index, {bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 800),
            disableAnimations: reduced,
          ),
          child: StudentBottomNav(
            tabIndex: index,
            onSelectTab: (_) {},
            onQuickAction: () {},
          ),
        ),
      );
      await tester.pumpWidget(host(0));
      Color ink() => tester.widget<Text>(find.text('Discover')).style!.color!;
      const inactive = Color(0xFF1C1C1E);
      await tester.pumpWidget(host(1));
      await tester.pump(const Duration(milliseconds: 70));
      final midway = ink();
      expect(midway, isNot(inactive));
      expect(midway, isNot(kStudentNavSelectedGreen));
      await tester.pumpWidget(host(0));
      expect(ink(), midway);
      await tester.pumpAndSettle();
      expect(ink(), inactive);
      await tester.pumpWidget(host(1, reduced: true));
      await tester.pump();
      expect(ink(), kStudentNavSelectedGreen);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
  testWidgets(
    'all four selected pills remain centered and inset inside a constrained host',
    (tester) async {
      for (var index = 0; index < 4; index++) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(360, 800)),
              child: Center(
                child: SizedBox(
                  width: 354,
                  height: 100,
                  child: StudentBottomNav(
                    tabIndex: index,
                    onSelectTab: (_) {},
                    onQuickAction: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final selection = tester.getRect(
          find.byKey(const ValueKey('student-nav-moving-indicator')),
        );
        final glass = tester.getRect(find.byType(LiquidGlassPill).first);
        expect(selection.left, greaterThan(glass.left));
        expect(selection.right, lessThan(glass.right));
        expect(selection.width / selection.height, greaterThan(1));
        final name = ['home', 'discover', 'tracker', 'profile'][index];
        expect(
          selection.center.dx,
          closeTo(
            tester.getCenter(find.byKey(ValueKey('student-nav-$name'))).dx,
            .1,
          ),
        );
      }
    },
  );
  testWidgets(
    'large text keeps a solid readable navigation surface over dark content',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 800),
              textScaler: TextScaler.linear(3),
            ),
            child: Scaffold(
              backgroundColor: Colors.deepPurple,
              body: StudentBottomNav(
                tabIndex: 0,
                onSelectTab: (_) {},
                onQuickAction: () {},
              ),
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(StudentBottomNav),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color == Colors.white,
          ),
        ),
        findsWidgets,
      );
    },
  );
  testWidgets(
    'one indicator travels across the retained dock and snaps with reduced motion',
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
      final indicator = find.byKey(
        const ValueKey('student-nav-moving-indicator'),
      );
      expect(indicator, findsOneWidget);
      final fill =
          (tester.widget<DecoratedBox>(indicator).decoration as BoxDecoration)
              .color!;
      expect(
        fill.a,
        closeTo(.11, .005),
        reason: 'Selection transmits background colors without a hard ring.',
      );
      final first = tester.getTopLeft(indicator).dx;
      final restingWidth = tester.getSize(indicator).width;
      await tester.pumpWidget(host(3));
      await tester.pump(const Duration(milliseconds: 80));
      final middle = tester.getTopLeft(indicator).dx;
      expect(middle, greaterThan(first));
      expect(tester.getSize(indicator).width, greaterThan(restingWidth));
      expect(
        tester.getSize(indicator).height,
        greaterThan(50),
        reason: 'The travelling capsule should bulge beyond the resting bar.',
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(indicator).dx, greaterThan(middle));
      await tester.pumpWidget(host(0, reduced: true));
      await tester.pump();
      expect(
        tester.getCenter(indicator).dx,
        closeTo(
          tester.getCenter(find.byKey(const ValueKey('student-nav-home'))).dx,
          .01,
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
  testWidgets(
    'selected icon travels left during collapse, plus stays anchored, reversal is continuous',
    (tester) async {
      var restores = 0;
      Widget host(bool collapsed) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(440, 900)),
          child: Scaffold(
            body: StudentBottomNav(
              tabIndex: 2,
              isCollapsed: collapsed,
              onSelectTab: (_) {},
              onQuickAction: () {},
              onExpand: () => restores++,
            ),
          ),
        ),
      );
      await tester.pumpWidget(host(false));
      final icon = find.byIcon(CupertinoIcons.doc_text);
      final plus = find.byIcon(Icons.add_rounded);
      final start = tester.getCenter(icon).dx;
      final plusStart = tester.getCenter(plus);
      await tester.pumpWidget(host(true));
      await tester.pump(const Duration(milliseconds: 60));
      expect(icon, findsOneWidget);
      final mid = tester.getCenter(icon).dx;
      expect(mid, lessThan(start));
      expect(tester.getCenter(plus), plusStart);
      await tester.tapAt(tester.getCenter(icon));
      expect(restores, 1);
      await tester.pumpWidget(host(false));
      expect(tester.getCenter(icon).dx, closeTo(mid, .1));
      await tester.pumpAndSettle();
      expect(tester.getCenter(icon).dx, closeTo(start, .1));
      await tester.pumpWidget(host(true));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(const ValueKey('student-nav-quick-action')))
            .width,
        48,
      );
      expect(tester.getCenter(plus), plusStart);
      final compact = find.byKey(const ValueKey('student-nav-compact-control'));
      expect(tester.getSize(compact).width, greaterThanOrEqualTo(44));
      final opaqueDiscs = find.descendant(
        of: compact,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
              ((w.decoration! as BoxDecoration).color?.a ?? 0) == 1,
        ),
      );
      expect(opaqueDiscs, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
