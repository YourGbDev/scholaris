import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/widgets/student_application_guide.dart';
import 'package:scholaris/shared/theme/app_motion.dart';

void main() {
  group('Ari Tour Build 489 Desync Regressions', () {
    testWidgets('Issue A: Step 3 (Recommended for you) does not trap user in manual scroll', (tester) async {
      final homeScroll = ScrollController();
      addTearDown(homeScroll.dispose);
      final homeTargets = List.generate(4, (_) => GlobalKey());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ListView(
                  controller: homeScroll,
                  children: [
                    SizedBox(key: homeTargets[0], height: 100),
                    SizedBox(key: homeTargets[1], height: 100),
                    SizedBox(key: homeTargets[2], height: 50),
                    SizedBox(key: homeTargets[3], height: 250), // Card target
                    const SizedBox(height: 1200),
                  ],
                ),
                Positioned.fill(
                  child: StudentApplicationGuide(
                    initialStep: 3,
                    homeTargets: homeTargets,
                    homeScroll: homeScroll,
                    onExit: () {},
                    onFinish: () {},
                    onSelectTab: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 3 displays immediately as "Tap anywhere to continue" without manual scrolling
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('Tap anywhere to continue'), findsOneWidget);
      expect(find.text('Swipe up to explore'), findsNothing);
    });

    testWidgets('Issue B: Step 6 (Browse at your own pace) does not require scrolling to absolute catalog end', (tester) async {
      final discoverScroll = ScrollController();
      addTearDown(discoverScroll.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ListView(
                  controller: discoverScroll,
                  children: const [
                    SizedBox(height: 3000), // Long 20+ item catalog
                  ],
                ),
                Positioned.fill(
                  child: StudentApplicationGuide(
                    initialStep: 6,
                    discoverScroll: discoverScroll,
                    onExit: () {},
                    onFinish: () {},
                    onSelectTab: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Browse at your own pace'), findsOneWidget);
      expect(find.text('Swipe up to explore'), findsOneWidget);

      // Scroll 420px (user progress threshold), not the full 3000px
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(40, 300),
          scrollDelta: Offset(0, 420),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Should unlock "Tap anywhere to continue" without hitting maxScrollExtent
      expect(discoverScroll.position.extentAfter, greaterThan(1000));
      expect(find.text('Tap anywhere to continue'), findsOneWidget);
    });

    testWidgets('Issue D: CountUpAnimation with immediate: true renders 50000 on frame 0 without hitch', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CountUpAnimation(
              targetValue: 50000,
              prefix: '₱',
              immediate: true,
            ),
          ),
        ),
      );

      // Must render ₱50,000 immediately without starting at 0 or emitting intermediate spring value (9,237)
      expect(find.text('₱50,000'), findsOneWidget);
      expect(find.text('₱9,237'), findsNothing);
      expect(find.text('₱0'), findsNothing);

      // Advance frames and confirm stability
      await tester.pump(const Duration(milliseconds: 48));
      expect(find.text('₱50,000'), findsOneWidget);
      expect(find.text('₱9,237'), findsNothing);
    });

    testWidgets('Issue E: Profile Tab steps have scroll: false and auto-ensure visibility without swipe cues', (tester) async {
      final profileScroll = ScrollController();
      addTearDown(profileScroll.dispose);
      final profileTargets = List.generate(3, (_) => GlobalKey());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ListView(
                  controller: profileScroll,
                  children: [
                    const SizedBox(height: 200),
                    SizedBox(key: profileTargets[0], height: 200),
                    SizedBox(key: profileTargets[1], height: 200),
                    SizedBox(key: profileTargets[2], height: 200),
                    const SizedBox(height: 500),
                  ],
                ),
                Positioned.fill(
                  child: StudentApplicationGuide(
                    initialStep: 17, // Academic Information
                    profileTargets: profileTargets,
                    profileScroll: profileScroll,
                    onExit: () {},
                    onFinish: () {},
                    onSelectTab: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Academic information'), findsOneWidget);
      expect(find.text('Tap anywhere to continue'), findsOneWidget);
      expect(find.text('Swipe up to explore'), findsNothing);
    });
  });
}
