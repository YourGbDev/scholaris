import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/widgets/student_application_guide.dart';

void main() {
  Future<ScrollController> mount(
    WidgetTester tester, {
    double height = 3200,
    bool reduced = false,
    VoidCallback? onExit,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            disableAnimations: reduced,
          ),
          child: Scaffold(
            body: Stack(
              children: [
                ListView(
                  controller: scroll,
                  children: [SizedBox(height: height)],
                ),
                Positioned.fill(
                  child: StudentApplicationGuide(
                    initialStep: 6,
                    discoverScroll: scroll,
                    onExit: onExit ?? () {},
                    onFinish: () {},
                    onSelectTab: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return scroll;
  }

  Future<void> wheel(WidgetTester tester, double delta) async {
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: const Offset(40, 300),
        scrollDelta: Offset(0, delta),
      ),
    );
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pumpAndSettle();
  }

  double opacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(find.byKey(const ValueKey('guide-presentation')))
      .opacity;

  testWidgets('up/down jiggles do not accumulate browse credit', (
    tester,
  ) async {
    await mount(tester);
    for (var i = 0; i < 4; i++) {
      await wheel(tester, 120);
      await wheel(tester, -120);
    }
    await settle(tester);
    expect(find.text('Tap anywhere to continue'), findsNothing);
    await wheel(tester, 420);
    await settle(tester);
    expect(find.text('Tap anywhere to continue'), findsOneWidget);
    expect(find.text('Browse at your own pace'), findsOneWidget);
  });
  testWidgets(
    'fling clears presentation until idle and never opens a scholarship',
    (tester) async {
      final scroll = await mount(tester);
      await tester.flingFrom(
        const Offset(40, 400),
        const Offset(0, -320),
        1400,
      );
      await tester.pump(const Duration(milliseconds: 160));
      expect(opacity(tester), 0);
      expect(scroll.offset, greaterThan(0));
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byTooltip('Skip guide'), findsOneWidget);
      await tester.pumpAndSettle();
      await settle(tester);
      expect(opacity(tester), 1);
      expect(find.text('Browse at your own pace'), findsOneWidget);
    },
  );
  testWidgets('Back during debounce cancels the pending browse lesson', (
    tester,
  ) async {
    await mount(tester);
    await wheel(tester, 450);
    expect(opacity(tester), 0);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.text('I’m back!'), findsOneWidget);
    expect(find.text('Open one scholarship'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('short non-scrollable catalog has an explicit continue path', (
    tester,
  ) async {
    await mount(tester, height: 200);
    expect(find.text('Tap anywhere to continue'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guide-advance')));
    await tester.pumpAndSettle();
    expect(find.text('Open one scholarship'), findsOneWidget);
    expect(find.textContaining('No scholarship is available'), findsOneWidget);
  });
  testWidgets(
    'reduced motion hides immediately and Skip works while notes are hidden',
    (tester) async {
      var exited = false;
      await mount(tester, reduced: true, onExit: () => exited = true);
      await wheel(tester, 100);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('guide-presentation')),
            )
            .duration,
        Duration.zero,
      );
      expect(opacity(tester), 0);
      await tester.tap(find.byTooltip('Skip guide'));
      expect(exited, isTrue);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
      expect(tester.takeException(), isNull);
    },
  );
}
