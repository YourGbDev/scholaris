import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/widgets/student_application_guide.dart';
import 'package:scholaris/features/scholarships/screens/discover_screen.dart';
import 'package:scholaris/features/scholarships/providers/discovery_provider.dart';

import 'student_detail_tour_test.dart' as fixture;

void main() {
  testWidgets('real Discover catalog has a real target when no matches exist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final details = GlobalKey(), end = GlobalKey();
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
                  endGuideKey: end,
                ),
                Positioned.fill(
                  child: StudentApplicationGuide(
                    initialStep: 6,
                    discoverScroll: scroll,
                    discoverDetails: details,
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
    for (var i = 0; i < 5; i++) {
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
    expect(end.currentContext, isNotNull);
    expect(find.text('Tap anywhere to continue'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guide-advance')));
    await tester.pumpAndSettle();
    expect(details.currentContext, isNotNull);
    expect(find.bySemanticsLabel('Guide action: View Details'), findsOneWidget);
    expect(find.byType(DiscoverScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Discover waits for the bottom, not time or a short swipe', (
    tester,
  ) async {
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
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Tap anywhere to continue'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guide-advance')));
    await tester.pumpAndSettle();
    expect(find.text('Open one scholarship'), findsOneWidget);
  });
}
