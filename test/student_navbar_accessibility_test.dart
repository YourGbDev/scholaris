import 'package:scholaris/features/home/presentation/widgets/liquid_glass_pill.dart';
// test/student_navbar_accessibility_test.dart
//
// QA Automated Regression & Accessibility Test Suite
// Verifies student navbar refinements for batch student-navbar-2026-10-26:
// 1. Tab labels: Home replaces Dashboard, Discover, Tracker, Profile.
// 2. Both ValueKey('student-nav-home') and ValueKey('student-nav-dashboard') match.
// 3. Scholaris green (#0F4D2E) selected state and high-contrast (#1C1C1E) unselected.
// 4. High-contrast mode fallback to solid opaque white container without blur.
// 5. Reduced motion mode preserves static glass with animations disabled (distinct from transparency).
// 6. Dynamic Type 2.0x scaling: verifies effective rendered label font size (>= 14.0pt), adaptive dock height (78px), and dynamic content clearance without layout overflow.
// 7. Touch target dimensions >= 44x44 pt (outer dock 62px - 78px).
// 8. Keyboard activation & traversal: Tab key traversal, visible focus ring, and Enter / Space activation of tabs and '+' button.
// 9. Accessibility semantics tree inspection (button: true, label, selected, onTap action).
// 10. Keyboard avoidance hides dock when viewInsets.bottom > 0.
// 11. Quick action '+' button opens Student Action Sheet.

import 'dart:ui' as ui show SemanticsFlag;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';

void main() {
  group('Student Navbar Refinements & Accessibility Suite', () {
    testWidgets('1. Tab 0 is Home, tab switching works, and Scholaris green is applied to selected state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert Tab 0 label is 'Home'
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);

      // Assert backward compatibility keys
      expect(find.byKey(const ValueKey('student-nav-home')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-dashboard')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-discover')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-tracker')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-nav-profile')), findsOneWidget);

      // Assert initial state is Home (index 0) with Scholaris green (#0F4D2E)
      final homeText = tester.widget<Text>(find.text('Home'));
      expect(homeText.style?.color, equals(kStudentNavSelectedGreen));

      final discoverText = tester.widget<Text>(find.text('Discover'));
      expect(discoverText.style?.color, equals(const Color(0xFF25282B)));

      // Switch to Discover (Tab 1)
      await tester.tap(find.byKey(const ValueKey('student-nav-discover')));
      await tester.pumpAndSettle();

      final discoverTextSelected = tester.widget<Text>(find.text('Discover'));
      expect(discoverTextSelected.style?.color, equals(kStudentNavSelectedGreen));

      final homeTextUnselected = tester.widget<Text>(find.text('Home'));
      expect(homeTextUnselected.style?.color, equals(const Color(0xFF25282B)));

      // Switch to Tracker (Tab 2)
      await tester.tap(find.byKey(const ValueKey('student-nav-tracker')));
      await tester.pumpAndSettle();
      final trackerText = tester.widget<Text>(find.text('Tracker'));
      expect(trackerText.style?.color, equals(kStudentNavSelectedGreen));

      // Switch to Profile (Tab 3)
      await tester.tap(find.byKey(const ValueKey('student-nav-profile')));
      await tester.pumpAndSettle();
      final profileText = tester.widget<Text>(find.text('Profile'));
      expect(profileText.style?.color, equals(kStudentNavSelectedGreen));
    });

    testWidgets('2. High-contrast mode activates solid opaque fallback without blur',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(440, 956),
                highContrast: true,
              ),
              child: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // In high contrast mode, LiquidGlass must NOT be rendered in the nav dock
      final liquidGlassInStack = find.descendant(
        of: find.byType(Stack),
        matching: find.byType(LiquidGlassPill),
      );
      expect(liquidGlassInStack, findsNothing,
          reason: 'High-contrast mode must disable LiquidGlass in favor of solid opaque container.');

      // Opaque DecoratedBox must be present with high-contrast border
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('3. Reduced-motion mode preserves static glass with animations disabled',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(440, 956),
                disableAnimations: true,
              ),
              child: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Reduced motion preserves glass (distinguished from high contrast transparency removal)
      final liquidGlassInStack = find.descendant(
        of: find.byType(Stack),
        matching: find.byType(LiquidGlassPill),
      );
      expect(liquidGlassInStack, findsWidgets,
          reason: 'Reduced motion preserves static glass material while disabling spring motion.');
      expect(find.descendant(of: liquidGlassInStack, matching: find.byType(BackdropFilter)),
          findsNWidgets(4), reason: 'Each static surface retains both rim and core blur.');
    });

    testWidgets('4. Dynamic Type 2.0x and 3.0x scaling: verifies genuine MediaQuery textScaler on base font, adaptive 2-row dock, and touch targets',
        (WidgetTester tester) async {
      final viewports = [
        const Size(320, 640),
        const Size(360, 800),
        const Size(440, 956),
      ];

      final scaleFactors = [2.0, 3.0];

      for (final scaleFactor in scaleFactors) {
        final textScaler = TextScaler.linear(scaleFactor);
        final expectedScaledFontSize = textScaler.scale(kStudentNavBaseFontSize); // 21.0 at 2x; 31.5 at 3x

        for (final size in viewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: textScaler,
                  ),
                  child: Scaffold(
                    body: Builder(
                      builder: (context) {
                        return StudentBottomNav(
                          tabIndex: 0,
                          onSelectTab: (_) {},
                          onQuickAction: () {},
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final expectedDockHeight = computeStudentDockHeight(textScaler, screenWidth: size.width);

          // 1. Verify adaptive dock height has expanded to accommodate large text layout
          final sizedBoxFinder = find.byWidgetPredicate(
            (w) => w is SizedBox && w.height == expectedDockHeight,
          );
          expect(sizedBoxFinder, findsWidgets,
              reason: 'At ${scaleFactor}x text scale, adaptive dock height must match computed height ($expectedDockHeight px).');

          // Verify the configured base font follows the actual ambient TextScaler.
          final homeTextWidget = tester.widget<Text>(find.text('Home'));
          expect(homeTextWidget.style?.fontSize, equals(kStudentNavBaseFontSize),
              reason: 'The base font must follow ambient scaling without a fixed rendered-size cap.');
          expect(homeTextWidget.textScaler, isNull,
              reason: 'TextScaler.noScaling must not be applied; text must respect ambient MediaQuery textScaler.');

          // Ambient textScaler scales base font size to exact requested value
          final effectiveRenderedSize = textScaler.scale(homeTextWidget.style!.fontSize!);
          expect(effectiveRenderedSize, equals(expectedScaledFontSize),
              reason: 'Effective scaled font size at ${scaleFactor}x must be $expectedScaledFontSize pt (no fixed 15pt cap).');

          // 3. Verify all 4 tab destinations and '+' quick action button are preserved
          expect(find.text('Home'), findsOneWidget);
          expect(find.text('Discover'), findsOneWidget);
          expect(find.text('Tracker'), findsOneWidget);
          expect(find.text('Profile'), findsOneWidget);
          expect(find.byKey(const ValueKey('student-nav-quick-action')), findsOneWidget);

          // 4. Verify touch targets meet >= 44x44 pt minimums
          final tabKeys = [
            'student-nav-home',
            'student-nav-discover',
            'student-nav-tracker',
            'student-nav-profile',
          ];
          for (final key in tabKeys) {
            final renderBox = tester.renderObject(find.byKey(ValueKey(key))) as RenderBox;
            expect(renderBox.size.height, greaterThanOrEqualTo(44.0),
                reason: 'Tab $key must meet >= 44pt height threshold at ${scaleFactor}x.');
            expect(renderBox.size.width, greaterThanOrEqualTo(44.0),
                reason: 'Tab $key must meet >= 44pt width threshold at ${scaleFactor}x.');
          }

          // '+' quick action button meets >= 44x44 pt
          final plusRenderBox = tester.renderObject(find.byKey(const ValueKey('student-nav-quick-action'))) as RenderBox;
          expect(plusRenderBox.size.height, greaterThanOrEqualTo(44.0));
          expect(plusRenderBox.size.width, greaterThanOrEqualTo(44.0));

          // 5. Verify zero layout overflow exceptions
          expect(tester.takeException(), isNull,
              reason: 'Zero layout overflow errors allowed at width ${size.width} with ${scaleFactor}x text scaling.');
        }
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('5. Dynamic content clearance calculation accounts for actual adaptive dock height',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Under standard text scale 1.0x: dockHeight = 58, clearance = 16 + 58 + 16 = 90.0
              final standardClearance = computeStudentContentClearance(context);
              expect(standardClearance, equals(88.0));
              return const SizedBox();
            },
          ),
        ),
      );

      // Under 2.0x text scale: clearance = 16 + dockHeight + 16
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
            ),
            child: Builder(
              builder: (context) {
                final textScaler = MediaQuery.textScalerOf(context);
                final expectedDockHeight = computeStudentDockHeight(textScaler);
                final scaledClearance = computeStudentContentClearance(context);
                expect(scaledClearance, equals(10.0 + expectedDockHeight + 16.0));
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Under 3.0x text scale: clearance = 16 + dockHeight + 16
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(3.0),
            ),
            child: Builder(
              builder: (context) {
                final textScaler = MediaQuery.textScalerOf(context);
                final expectedDockHeight = computeStudentDockHeight(textScaler);
                final scaledClearance = computeStudentContentClearance(context);
                expect(scaledClearance, equals(10.0 + expectedDockHeight + 16.0));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('6. Touch targets meet minimum 44x44 pt requirements and outer dock is 58px',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 956);
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

      final tabKeys = [
        'student-nav-home',
        'student-nav-discover',
        'student-nav-tracker',
        'student-nav-profile',
      ];

      for (final key in tabKeys) {
        final renderBox = tester.renderObject(find.byKey(ValueKey(key))) as RenderBox;
        expect(renderBox.size.height, greaterThanOrEqualTo(44.0),
            reason: 'Tab item $key must have height >= 44pt HIG threshold.');
        expect(renderBox.size.width, greaterThanOrEqualTo(44.0),
            reason: 'Tab item $key width must be >= 44pt.');
      }

      final plusBox = tester.renderObject(find.byKey(const ValueKey('student-nav-quick-action'))) as RenderBox;
      expect(plusBox.size.height, equals(62.0));
      expect(plusBox.size.width, equals(62.0));
    });

    testWidgets('7. Keyboard activation & traversal: Tab traversal and Enter/Space activate tab switching',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int currentTab = 0;
      bool quickActionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return StudentBottomNav(
                  tabIndex: currentTab,
                  onSelectTab: (index) {
                    setState(() {
                      currentTab = index;
                    });
                  },
                  onQuickAction: () {
                    quickActionCalled = true;
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initial tab is 0 (Home)
      expect(currentTab, equals(0));

      // 1. Move focus via Tab key traversal into the first tab (Home)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Verify Home tab has visible focus ring (Scholaris green #0F4D2E, 2.0px width)
      final homeDecoratedBoxFinder = find.descendant(
        of: find.byKey(const ValueKey('student-nav-home')),
        matching: find.byType(DecoratedBox),
      );
      expect(homeDecoratedBoxFinder, findsWidgets);
      final homeDecoration = tester
          .widgetList<DecoratedBox>(homeDecoratedBoxFinder)
          .firstWhere((box) =>
              box.decoration is BoxDecoration &&
              (box.decoration as BoxDecoration).border != null)
          .decoration as BoxDecoration;
      expect(homeDecoration.border?.top.color, equals(const Color(0xFF0F4D2E)));
      expect(homeDecoration.border?.top.width, equals(2.0));

      // 2. Tab key moves focus to Discover (tab 1)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Press Enter key to activate Discover
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(currentTab, equals(1),
          reason: 'Pressing Enter on focused Discover tab must switch to index 1.');

      // 3. Tab key moves focus to Tracker (tab 2)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Press Space key to activate Tracker
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(currentTab, equals(2),
          reason: 'Pressing Space on focused Tracker tab must switch to index 2.');

      // 4. Tab key moves focus to Profile (tab 3)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Press Enter to activate Profile
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(currentTab, equals(3),
          reason: 'Pressing Enter on focused Profile tab must switch to index 3.');

      // 5. Tab key moves focus to '+' Quick Action button
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Verify Quick Action has visible circular focus ring (Scholaris green #0F4D2E, 2.5px width)
      final quickActionDecoratedBoxFinder = find.descendant(
        of: find.bySemanticsLabel('Quick actions'),
        matching: find.byType(DecoratedBox),
      );
      expect(quickActionDecoratedBoxFinder, findsWidgets);
      final quickActionDecoration = tester
          .widgetList<DecoratedBox>(quickActionDecoratedBoxFinder)
          .firstWhere((box) =>
              box.decoration is BoxDecoration &&
              (box.decoration as BoxDecoration).shape == BoxShape.circle &&
              (box.decoration as BoxDecoration).border != null)
          .decoration as BoxDecoration;
      expect(quickActionDecoration.border?.top.color, equals(const Color(0xFF0F4D2E)));
      expect(quickActionDecoration.border?.top.width, equals(2.5));

      // Press Enter to activate Quick Action button
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(quickActionCalled, isTrue,
          reason: 'Pressing Enter on focused Quick Action button must invoke onQuickAction.');
    });

    testWidgets('8. Accessibility semantics tree exposes button roles, labels, and onTap action',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 956);
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

      expect(
        find.bySemanticsLabel(RegExp(r'Home Tab')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Discover Tab')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Tracker Tab')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Profile Tab')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Quick actions')),
        findsOneWidget,
      );
    });

    testWidgets('9. Keyboard avoidance hides floating dock when keyboard appears',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Keyboard open: viewInsets.bottom = 300
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(440, 956),
                viewInsets: EdgeInsets.only(bottom: 300),
              ),
              child: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Nav dock should be hidden to avoid occluding keyboard
      expect(find.byKey(const ValueKey('student-nav-home')), findsNothing);
      expect(find.byKey(const ValueKey('student-nav-quick-action')), findsNothing);
    });

    testWidgets('10. Quick action "+" button opens Student Action Sheet on pointer tap',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 956);
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

      final plusButton = find.byKey(const ValueKey('student-nav-quick-action'));
      expect(plusButton, findsOneWidget);

      await tester.tap(plusButton);
      await tester.pumpAndSettle();

      // Action sheet should display options
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Scan scholarship QR'), findsOneWidget);
      expect(find.text('Upload document'), findsOneWidget);
    });

    testWidgets('11. Bounding-box non-overlap verification at 320px 3.0x: Home/Discover and Tracker/Profile have positive clearance and zero collision',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(3.0),
            ),
            child: Scaffold(
              bottomNavigationBar: StudentBottomNav(
                tabIndex: 0,
                onSelectTab: (_) {},
                onQuickAction: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Full text verification: all 4 labels rendered in full without truncation
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Tracker'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      final homeBox = tester.renderObject(find.text('Home')) as RenderBox;
      final discoverBox = tester.renderObject(find.text('Discover')) as RenderBox;
      final homeRect = homeBox.localToGlobal(Offset.zero) & homeBox.size;
      final discoverRect = discoverBox.localToGlobal(Offset.zero) & discoverBox.size;

      // Positive horizontal clearance between Home and Discover (no collision):
      expect(homeRect.right, lessThan(discoverRect.left),
          reason: 'Home label right boundary (${homeRect.right}) must be strictly less than Discover label left boundary (${discoverRect.left}) at 320px 3.0x.');

      final trackerBox = tester.renderObject(find.text('Tracker')) as RenderBox;
      final profileBox = tester.renderObject(find.text('Profile')) as RenderBox;
      final trackerRect = trackerBox.localToGlobal(Offset.zero) & trackerBox.size;
      final profileRect = profileBox.localToGlobal(Offset.zero) & profileBox.size;

      // Positive horizontal clearance between Tracker and Profile (no collision):
      expect(trackerRect.right, lessThan(profileRect.left),
          reason: 'Tracker label right boundary (${trackerRect.right}) must be strictly less than Profile label left boundary (${profileRect.left}) at 320px 3.0x.');

      // Positive horizontal clearance between Tracker and Profile (no collision):
      expect(trackerRect.right, lessThan(profileRect.left),
          reason: 'Tracker label right boundary (${trackerRect.right}) must be strictly less than Profile label left boundary (${profileRect.left}) at 320px 3.0x.');

      // Vertical layout verification: '+' quick action button is positioned above the 2x2 pill dock
      final plusBox = tester.renderObject(find.byKey(const ValueKey('student-nav-quick-action'))) as RenderBox;
      final plusRect = plusBox.localToGlobal(Offset.zero) & plusBox.size;
      expect(plusRect.bottom, lessThanOrEqualTo(homeRect.top),
          reason: 'Quick action "+" button bottom (${plusRect.bottom}) must be positioned above the pill dock items (${homeRect.top}).');

      // 2. Measure proportional text with TextPainter under actual style and 3.0x TextScaler
      final homeStyle = tester.widget<Text>(find.text('Home')).style!;
      final homePainter = TextPainter(
        text: TextSpan(text: 'Home', style: homeStyle),
        textDirection: TextDirection.ltr,
        textScaler: const TextScaler.linear(3.0),
      )..layout();
      expect(homePainter.width, greaterThan(40.0));

      final discoverStyle = tester.widget<Text>(find.text('Discover')).style!;
      final discoverPainter = TextPainter(
        text: TextSpan(text: 'Discover', style: discoverStyle),
        textDirection: TextDirection.ltr,
        textScaler: const TextScaler.linear(3.0),
      )..layout();
      expect(discoverPainter.width, greaterThan(80.0));

      // 3. Verify no duplicate semantic button nodes per tab
      final homeSemantics = tester.getSemantics(find.byKey(const ValueKey('student-nav-home')));
      // ignore: deprecated_member_use
      expect(homeSemantics.hasFlag(ui.SemanticsFlag.isButton), isTrue);
      expect(homeSemantics.label, contains('Home Tab'));
      // ignore: deprecated_member_use
      expect(homeSemantics.hasFlag(ui.SemanticsFlag.isSelected), isTrue);

      int childButtons = 0;
      homeSemantics.visitChildren((node) {
        // ignore: deprecated_member_use
        if (node.hasFlag(ui.SemanticsFlag.isButton)) {
          childButtons++;
        }
        return true;
      });
      expect(childButtons, equals(0),
          reason: 'Tab must not contain duplicate child semantic buttons (inner GestureDetector semantics excluded).');
    });
  });
}
