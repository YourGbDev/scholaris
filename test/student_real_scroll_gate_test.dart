import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/widgets/student_application_guide.dart';
import 'package:scholaris/features/scholarships/screens/discover_screen.dart';
import 'package:scholaris/features/scholarships/providers/discovery_provider.dart';

import 'student_detail_tour_test.dart' as fixture;

void main() {
  for (final scenario in [
    (const Size(320, 568), 2.0),
    (const Size(568, 320), 1.0),
  ]) {
    testWidgets(
      'real card tour keeps action usable at ${scenario.$1}',
      (tester) async {
        tester.view.physicalSize = scenario.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        final card = GlobalKey(), details = GlobalKey();
        await tester.pumpWidget(
          fixture.wrap(
            ProviderScope(
              overrides: [
                filteredMatchesProvider.overrideWith(
                  (ref) => AsyncData([fixture.scholarship]),
                ),
                filteredBrowseProvider.overrideWith(
                  (ref) => const AsyncData([]),
                ),
              ],
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scenario.$2)),
                  child: Scaffold(
                    body: Stack(
                      children: [
                        DiscoverScreen(
                          scrollController: scroll,
                          detailsGuideKey: details,
                          cardGuideKey: card,
                        ),
                        Positioned.fill(
                          child: StudentApplicationGuide(
                            initialStep: 7,
                            discoverScroll: scroll,
                            discoverDetails: details,
                            discoverCard: card,
                            exampleScholarship: fixture.scholarship,
                            onExit: () {},
                            onFinish: () {},
                            onSelectTab: (_) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(card.currentContext, isNotNull);
        expect(find.text('Open one scholarship'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (find
            .bySemanticsLabel('Guide action: View Details')
            .evaluate()
            .isEmpty) {
          for (
            var i = 0;
            i < 16 &&
                find
                    .bySemanticsLabel('Guide action: View Details')
                    .evaluate()
                    .isEmpty;
            i++
          ) {
            await tester.sendEventToBinding(
              const PointerScrollEvent(
                position: Offset(12, 150),
                scrollDelta: Offset(0, 160),
              ),
            );
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pumpAndSettle();
          }
        }
        await tester.tap(find.bySemanticsLabel('Guide action: View Details'));
        await tester.pumpAndSettle();
        expect(find.text('Review the scholarship'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('real Discover catalog has a real target when no matches exist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final details = GlobalKey(), end = GlobalKey(), card = GlobalKey();
    await tester.pumpWidget(
      fixture.wrap(
        ProviderScope(
          overrides: [
            filteredMatchesProvider.overrideWith((ref) => const AsyncData([])),
            filteredBrowseProvider.overrideWith(
              (ref) => AsyncData([fixture.scholarship]),
            ),
          ],
          child: Scaffold(
            body: Stack(
              children: [
                DiscoverScreen(
                  scrollController: scroll,
                  detailsGuideKey: details,
                  cardGuideKey: card,
                  endGuideKey: end,
                ),
                Positioned.fill(
                  child: StudentApplicationGuide(
                    initialStep: 6,
                    discoverScroll: scroll,
                    discoverDetails: details,
                    discoverCard: card,
                    discoverEnd: end,
                    exampleScholarship: fixture.scholarship,
                    onExit: () {},
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
    expect(find.text('Browse at your own pace'), findsOneWidget);
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(40, 300),
        scrollDelta: Offset(0, 600),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(end.currentContext, isNotNull);
    expect(find.text('Tap anywhere to continue'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guide-advance')));
    await tester.pumpAndSettle();
    expect(details.currentContext, isNotNull);
    final cardRect = tester.getRect(find.byKey(card));
    expect(cardRect.top, greaterThanOrEqualTo(63));
    expect(cardRect.bottom, lessThanOrEqualTo(744));
    await tester.tapAt(cardRect.topLeft + const Offset(30, 30));
    await tester.pumpAndSettle();
    expect(find.text('Open one scholarship'), findsOneWidget);
    expect(find.bySemanticsLabel('Guide action: View Details'), findsOneWidget);
    expect(find.byType(DiscoverScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Discover waits for settled user progress, not programmatic movement',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  ListView(
                    controller: scroll,
                    children: const [SizedBox(height: 3200)],
                  ),
                  Positioned.fill(
                    child: StudentApplicationGuide(
                      initialStep: 6,
                      discoverScroll: scroll,
                      onExit: () {},
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
      await tester.pump(const Duration(seconds: 20));
      await tester.tap(find.byKey(const ValueKey('guide-advance')));
      await tester.pumpAndSettle();
      expect(find.text('Browse at your own pace'), findsOneWidget);
      scroll.jumpTo(150);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('guide-advance')));
      await tester.pumpAndSettle();
      expect(find.text('Browse at your own pace'), findsOneWidget);
      scroll.jumpTo(800);
      await tester.pumpAndSettle();
      expect(find.text('Tap anywhere to continue'), findsNothing);
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(40, 300),
          scrollDelta: Offset(0, 240),
        ),
      );
      await tester.pump(const Duration(milliseconds: 160));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('guide-presentation')),
            )
            .opacity,
        0,
      );
      expect(find.byTooltip('Skip guide'), findsOneWidget);
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(40, 300),
          scrollDelta: Offset(0, 240),
        ),
      );
      await tester.pump(const Duration(milliseconds: 349));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('guide-presentation')),
            )
            .opacity,
        0,
      );
      await tester.pumpAndSettle();
      expect(find.text('Browse at your own pace'), findsOneWidget);
      expect(scroll.position.extentAfter, greaterThan(1000));
      expect(find.text('Tap anywhere to continue'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('guide-advance')));
      await tester.pumpAndSettle();
      expect(find.text('Open one scholarship'), findsOneWidget);
    },
  );
}
