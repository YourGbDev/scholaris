import 'package:flutter/cupertino.dart' show CupertinoIcons;
// test/student_scroll_dock_test.dart
//
// Verification & Regression Suite for Student Scroll-Collapsible Navigation Dock
// Batch: student-scroll-dock-2026-10-26
//
// Verifies:
// 1. Scroll down > 24px collapses dock into active tab compact control at left.
// 2. Scroll down < 20px does not collapse dock (hysteresis verification).
// 3. Scroll up > 16px restores all 4 tabs.
// 4. Tapping compact control restores all 4 tabs.
// 5. Scroll to top (pixels <= 12.0) restores all 4 tabs.
// 6. Tab change restores all 4 tabs and updates compact active tab icon/label.
// 7. Horizontal scroll does not trigger collapse.
// 8. Quick action '+' button remains at right in both collapsed and expanded states.
// 9. Content clearance is 100% constant and stable between states.
// 10. Keyboard focus / traversal restores all 4 tabs.
// 11. accessibleNavigation: true completely disables collapse.
// 12. Large dynamic type (isStudentNavAccessible: true) completely disables collapse.
// 13. Reduced motion sets transition duration to Duration.zero.
// 14. Programmatic scroll rejection: animateTo() or jumpTo() does not trigger dock collapse.
// 15. Inactive tab isolation: scrolling inactive tab in IndexedStack does not trigger collapse or expansion on active tab.
// 16. Small-increment upward accumulation: multiple small upward scrolls accumulate in signed accumulator and expand dock once reaching 16px threshold.
// 17. Nav focus lock: when any expanded tab or '+' has keyboard focus, concurrent downward scroll does not collapse dock.
// 18. Quick action tap from collapsed: tapping '+' while dock is collapsed expands dock and opens action sheet.
// 19. PointerScrollEvent (wheel) >= 24px collapses dock.
// 20. PointerScrollEvent (wheel) <= -16px expands dock.
// 21. Multi-notch small wheel accumulation: 3x 10px accumulates across pulses and collapses dock.
// 22. Out-of-order ScrollUpdateNotification before UserScrollNotification is buffered and rescued upon UserScrollNotification.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/home/presentation/widgets/student_action_sheet.dart';

void main() {
  group('Student Scroll Dock Suite (student-scroll-dock-2026-10-26)', () {
    testWidgets('1. Scroll down > 24px collapses dock into active tab compact control at left',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initial state: expanded 4-tab row present, compact control absent
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);

      // Drag scrollable down > 24px (scrolling down: delta > 0, drag offset negative)
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -60));
      await tester.pumpAndSettle();

      // Dock collapsed: compact control present at left, expanded row absent
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsNothing);

      // Verify compact control displays active tab icon (CupertinoIcons.house_alt) without visible text
      final compactFinder = find.byKey(const ValueKey('student-nav-compact-control'));
      expect(find.descendant(
        of: compactFinder,
        matching: find.byIcon(CupertinoIcons.house_alt),
      ), findsOneWidget);
      expect(find.descendant(
        of: compactFinder,
        matching: find.byType(Text),
      ), findsNothing);
      expect(tester.getSemantics(compactFinder).label, contains('Home'));
    });

    testWidgets('2. Scroll down < 20px does not collapse dock (hysteresis verification)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initial state: expanded
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);

      // Drag scrollable down 15px (below 24px threshold)
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -15));
      await tester.pumpAndSettle();

      // Remains expanded
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);
    });

    testWidgets('3. Scroll up > 16px restores all 4 tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Collapse dock first
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);

      // Scroll up > 16px (drag offset positive)
      // Leave room for Flutter's touch slop: the delivered scroll must exceed 16px.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 50));
      await tester.pumpAndSettle();

      // Restored to expanded
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);
    });

    testWidgets('4. Tapping compact control restores all 4 tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Collapse dock
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);

      // Tap compact control
      await tester.tap(find.byKey(const ValueKey('student-nav-compact-control')));
      await tester.pumpAndSettle();

      // Restored
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);
    });

    testWidgets('5. Scroll to top (pixels <= 12.0) restores all 4 tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Collapse dock
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);

      // Scroll all the way back to top
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
      await tester.pumpAndSettle();

      // Restored
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
    });

    testWidgets('6. Tab change restores all 4 tabs and updates compact active tab icon/label',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                capturedRef = ref;
                return const HomeScreen();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Collapse dock
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);

      // Switch tab to Discover (tab index 1)
      capturedRef.read(homeTabIndexProvider.notifier).selectTab(1);
      await tester.pumpAndSettle();

      // Expanded dock restored
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);

      // Collapse again on Discover tab
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();

      // Compact control now reflects Discover icon without visible text
      final compactFinder = find.byKey(const ValueKey('student-nav-compact-control'));
      expect(find.descendant(
        of: compactFinder,
        matching: find.byIcon(CupertinoIcons.compass),
      ), findsOneWidget);
      expect(find.descendant(
        of: compactFinder,
        matching: find.byType(Text),
      ), findsNothing);
      expect(tester.getSemantics(compactFinder).label, contains('Discover'));
    });

    testWidgets('7. Horizontal scroll does not trigger collapse',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initial expanded
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);

      // Dispatch a horizontal scroll notification
      final scrollableElement = tester.element(find.byType(Scrollable).first);
      ScrollUpdateNotification(
        metrics: FixedScrollMetrics(
          minScrollExtent: 0.0,
          maxScrollExtent: 500.0,
          pixels: 50.0,
          viewportDimension: 360.0,
          axisDirection: AxisDirection.right,
          devicePixelRatio: 1.0,
        ),
        scrollDelta: 50.0,
        context: scrollableElement,
      ).dispatch(scrollableElement);

      await tester.pumpAndSettle();

      // Still expanded
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);
    });

    testWidgets('8. Quick action "+" button remains at right in both collapsed and expanded states',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final plusFinder = find.byKey(const ValueKey('student-nav-quick-action'));
      expect(plusFinder, findsOneWidget);

      final expandedPlusRect = tester.getRect(plusFinder);

      // Collapse dock
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();

      final collapsedPlusRect = tester.getRect(plusFinder);

      // The visible circle shrinks inside its fixed right-hand touch slot.
      expect(collapsedPlusRect.center, equals(expandedPlusRect.center));
      expect(collapsedPlusRect.width, equals(48));
      expect(collapsedPlusRect.height, equals(48));
    });

    testWidgets('9. Content clearance is 100% constant and stable between states',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final clearanceExpanded = computeStudentContentClearance(tester.element(find.byType(HomeScreen)));

      // Collapse dock
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();

      final clearanceCollapsed = computeStudentContentClearance(tester.element(find.byType(HomeScreen)));

      // Clearance must be identical, preventing layout jumping or oscillation
      expect(clearanceCollapsed, equals(clearanceExpanded));
      expect(clearanceExpanded, equals(16.0 + 58.0 + 16.0)); // 90.0px
    });

    testWidgets('10. Keyboard focus / traversal restores all 4 tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Collapse dock
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);

      // Focus compact control directly
      final focusDetectorFinder = find.descendant(
        of: find.byKey(const ValueKey('student-nav-compact-control')),
        matching: find.byType(FocusableActionDetector),
      );
      expect(focusDetectorFinder, findsOneWidget);

      final detectorWidget = tester.widget<FocusableActionDetector>(focusDetectorFinder);
      detectorWidget.onFocusChange?.call(true);
      await tester.pumpAndSettle();

      // Restored
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
    });

    testWidgets('11. accessibleNavigation: true completely disables collapse',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MediaQuery(
            data: MediaQueryData(
              accessibleNavigation: true,
              size: Size(360, 800),
            ),
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Drag scrollable down > 100px
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
      await tester.pumpAndSettle();

      // Collapse is disabled: expanded row remains, compact control is never shown
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);
    });

    testWidgets('12. Large dynamic type (isStudentNavAccessible: true) completely disables collapse',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              size: Size(360, 800),
            ),
            child: MaterialApp(
              home: Scaffold(
                bottomNavigationBar: StudentBottomNav(
                  tabIndex: 0,
                  onSelectTab: (_) {},
                  onQuickAction: () {},
                  isCollapsed: true, // Even when requested to collapse
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // All 4 tabs remain visible in accessible 2-row layout, compact control never shown
      expect(find.byKey(const ValueKey('student-nav-home')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-discover')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-tracker')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-profile')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);
    });

    testWidgets('13. Reduced motion sets transition duration to Duration.zero',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MediaQuery(
            data: MediaQueryData(
              disableAnimations: true,
              size: Size(360, 800),
            ),
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // In StudentBottomNav, check AnimatedContainer duration
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.byKey(const ValueKey('student-nav-expanded-row')),
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      expect(animatedContainer.duration, equals(Duration.zero));
    });

    testWidgets('14. Programmatic scroll rejection: animateTo() or jumpTo() does not trigger dock collapse',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);

      final scrollableState = tester.state<ScrollableState>(find.byType(Scrollable).first);
      scrollableState.position.jumpTo(100.0);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);

      scrollableState.position.animateTo(
        250.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);
    });

    testWidgets('15. Inactive tab isolation: scrolling inactive tab in IndexedStack does not trigger collapse on active tab',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Active tab is Tab 0 (Home). Dock starts expanded.
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);

      // Find retained tab listeners, including offstage destinations.
      final tabListeners = find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byWidgetPredicate((w) => w is NotificationListener<ScrollNotification> &&
            w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('student-tab-scroll-'),
            skipOffstage: false),
        skipOffstage: false,
      );
      expect(tabListeners, findsNWidgets(4));

      // 1. Dispatch downward scroll from inactive tab (index 1)
      final inactiveTabElement = tester.element(tabListeners.at(1));
      ScrollUpdateNotification(
        metrics: FixedScrollMetrics(
          minScrollExtent: 0.0,
          maxScrollExtent: 1000.0,
          pixels: 150.0,
          viewportDimension: 800.0,
          axisDirection: AxisDirection.down,
          devicePixelRatio: 1.0,
        ),
        scrollDelta: 60.0,
        context: inactiveTabElement,
      ).dispatch(inactiveTabElement);
      await tester.pumpAndSettle();

      // Active Tab 0 dock must remain expanded (inactive tab cannot collapse dock)
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);

      // 2. Collapse dock via active tab scroll
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);

      // 3. Dispatch upward scroll from inactive tab (index 1)
      ScrollUpdateNotification(
        metrics: FixedScrollMetrics(
          minScrollExtent: 0.0,
          maxScrollExtent: 1000.0,
          pixels: 100.0,
          viewportDimension: 800.0,
          axisDirection: AxisDirection.down,
          devicePixelRatio: 1.0,
        ),
        scrollDelta: -40.0,
        context: inactiveTabElement,
      ).dispatch(inactiveTabElement);
      await tester.pumpAndSettle();

      // Dock remains collapsed (inactive tab cannot expand active dock)
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsNothing);
    });

    testWidgets('16. Small-increment upward accumulation: multiple small upward scrolls accumulate and expand dock at >=16px',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // First collapse the dock with downward scroll > 24px
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);

      // Dispatch exact content deltas so touch slop/ballistic motion cannot
      // turn the nominal 4px gestures into different amounts of scrolling.
      final source = tester.element(find.byType(Scrollable).first);
      final metrics = FixedScrollMetrics(minScrollExtent: 0, maxScrollExtent: 1000,
        pixels: 100, viewportDimension: 600, axisDirection: AxisDirection.down,
        devicePixelRatio: 1);
      UserScrollNotification(metrics: metrics, direction: ScrollDirection.forward,
        context: source).dispatch(source);
      Future<void> upwardPulse() async {
        ScrollUpdateNotification(metrics: metrics, scrollDelta: -4,
          context: source).dispatch(source);
        await tester.pump();
      }
      for (var i = 0; i < 3; i++) {
        await upwardPulse();
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await upwardPulse();
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);
    });

    testWidgets('17. Nav focus lock: when any tab or "+" has keyboard focus, downward scroll does not collapse dock',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);

      // Focus '+' button
      final plusFinder = find.byKey(const ValueKey('student-nav-quick-action'));
      expect(plusFinder, findsOneWidget);
      final plusDetector = tester.widget<FocusableActionDetector>(
        find.ancestor(of: plusFinder, matching: find.byType(FocusableActionDetector)).first,
      );
      plusDetector.onFocusChange?.call(true);
      await tester.pumpAndSettle();

      // Scroll downward > 24px while focused
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();

      // Must remain expanded while focused
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);
    });

    testWidgets('18. Quick action tap from collapsed: tapping "+" while collapsed expands dock and opens sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Collapse dock
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);

      // Tap '+' button while collapsed
      await tester.tap(find.byKey(const ValueKey('student-nav-quick-action')));
      await tester.pumpAndSettle();

      // Dock expands
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);

      // Action sheet opens
      expect(find.byType(StudentActionSheet), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('19. PointerScrollEvent (wheel) >= 24px collapses dock',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);

      final scrollableFinder = find.byType(Scrollable).first;
      final center = tester.getCenter(scrollableFinder);

      await tester.sendEventToBinding(PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, 30),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsNothing);
    });

    testWidgets('20. PointerScrollEvent (wheel) <= -16px expands dock',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final scrollableFinder = find.byType(Scrollable).first;
      final center = tester.getCenter(scrollableFinder);

      // Collapse dock with downward wheel scroll (scrollDelta: Offset(0, 80))
      await tester.sendEventToBinding(PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, 80),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);

      // From collapsed, send PointerScrollEvent (wheel) <= -16px (scrollDelta: Offset(0, -20))
      await tester.sendEventToBinding(PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, -20),
      ));
      await tester.pumpAndSettle();

      // Dock expands
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);
    });

    testWidgets('21. Multi-notch small wheel accumulation: 3x 10px accumulates across pulses and collapses dock',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);

      final scrollableFinder = find.byType(Scrollable).first;
      final center = tester.getCenter(scrollableFinder);

      // Pulse 1: 10px (cumulative: 10px < 24px)
      await tester.sendEventToBinding(PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, 10),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);

      // Pulse 2: 10px (cumulative: 20px < 24px)
      await tester.sendEventToBinding(PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, 10),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);

      // Pulse 3: 10px (cumulative: 30px >= 24px threshold -> collapses dock)
      await tester.sendEventToBinding(PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, 10),
      ));
      await tester.pumpAndSettle();

      // Proves ScrollEndNotification did not wipe accumulator prematurely between pulses
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsNothing);
    });

    testWidgets(
        '22. Out-of-order ScrollUpdateNotification before UserScrollNotification is buffered and rescued upon UserScrollNotification',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);

      final activeTabElement = tester.element(find.byType(Scrollable).first);
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0.0,
        maxScrollExtent: 1000.0,
        pixels: 50.0, // Above top threshold (12.0)
        viewportDimension: 800.0,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1.0,
      );

      // Step 1: Dispatch ScrollStartNotification with dragDetails: null (simulating non-drag start)
      ScrollStartNotification(
        metrics: metrics,
        context: activeTabElement,
        dragDetails: null,
      ).dispatch(activeTabElement);

      // Step 2: Dispatch ScrollUpdateNotification(scrollDelta: 28.0) BEFORE UserScrollNotification
      // Since hasIntent is false, this delta must be buffered in _pendingDelta, not applied immediately.
      ScrollUpdateNotification(
        metrics: metrics,
        context: activeTabElement,
        scrollDelta: 28.0,
      ).dispatch(activeTabElement);

      await tester.pump();
      // Dock should still be expanded because delta was buffered awaiting user intent
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsNothing);

      // Step 3: Dispatch out-of-order UserScrollNotification(direction: ScrollDirection.reverse)
      // Controller rescues buffered _pendingDelta (28.0 >= 24.0) and collapses dock.
      UserScrollNotification(
        metrics: metrics,
        context: activeTabElement,
        direction: ScrollDirection.reverse,
      ).dispatch(activeTabElement);

      await tester.pumpAndSettle();

      // Dock collapsed upon delta rescue
      expect(find.byKey(const ValueKey('student-nav-compact-control')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-expanded-row')), findsNothing);
    });
  });
}
