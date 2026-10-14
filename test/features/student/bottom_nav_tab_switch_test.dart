// test/features/student/bottom_nav_tab_switch_test.dart
//
// QA Verification Test: Student Bottom Navigation Instant Tab Switching
// Verifies that:
// 1. IndexedStack preserves all 4 tabs (Dashboard, Discover, Tracker, Profile) alive in memory.
// 2. Tab switches happen immediately with zero white/blank flash or unmounting.
// 3. TabContentCrossFade is completely absent from the shell body.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/applications/presentation/applications_screen.dart';
import 'package:scholaris/features/dashboard/presentation/student_dashboard_screen.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/presentation/profile_tab_screen.dart';
import 'package:scholaris/features/scholarships/screens/discover_screen.dart';
import 'package:scholaris/shared/theme/app_motion.dart';

void main() {
  group('Student Bottom Navigation Tab Switch (QA Suite)', () {
    testWidgets('Tapping across all 4 tabs switches IndexedStack instantly without white flash',
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

      // 1. Assert IndexedStack is present as the primary tab container
      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget,
          reason: 'HomeScreen body must use IndexedStack to eliminate white flash.');

      // Assert TabContentCrossFade is completely removed
      expect(find.byType(TabContentCrossFade), findsNothing,
          reason: 'TabContentCrossFade must not be present in the student shell.');

      // 2. Assert initial tab is Dashboard (index 0)
      IndexedStack indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(0));
      expect(indexedStack.children.length, equals(4));
      expect(indexedStack.children[0], isA<StudentDashboardScreen>());
      expect(indexedStack.children[1], isA<DiscoverScreen>());
      expect(indexedStack.children[2], isA<ApplicationsScreen>());
      expect(indexedStack.children[3], isA<ProfileTabScreen>());

      // All 4 tabs are kept alive in memory simultaneously
      expect(find.byType(StudentDashboardScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(DiscoverScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(ApplicationsScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(ProfileTabScreen, skipOffstage: false), findsOneWidget);

      // 3. Switch to Tab 1: Discover
      final discoverNavFinder = find.byKey(const ValueKey('student-nav-discover'));
      expect(discoverNavFinder, findsOneWidget);
      await tester.tap(discoverNavFinder);
      await tester.pump();

      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(1),
          reason: 'Tapping Discover must switch IndexedStack index to 1 immediately.');
      expect(find.byType(DiscoverScreen), findsOneWidget,
          reason: 'DiscoverScreen must be active and visible on stage.');

      // 4. Switch to Tab 2: Tracker
      final trackerNavFinder = find.byKey(const ValueKey('student-nav-tracker'));
      expect(trackerNavFinder, findsOneWidget);
      await tester.tap(trackerNavFinder);
      await tester.pump();

      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(2),
          reason: 'Tapping Tracker must switch IndexedStack index to 2 immediately.');
      expect(find.byType(ApplicationsScreen), findsOneWidget,
          reason: 'ApplicationsScreen must be active and visible on stage.');

      // 5. Switch to Tab 3: Profile
      final profileNavFinder = find.byKey(const ValueKey('student-nav-profile'));
      expect(profileNavFinder, findsOneWidget);
      await tester.tap(profileNavFinder);
      await tester.pump();

      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(3),
          reason: 'Tapping Profile must switch IndexedStack index to 3 immediately.');
      expect(find.byType(ProfileTabScreen), findsOneWidget,
          reason: 'ProfileTabScreen must be active and visible on stage.');

      // 6. Switch back to Tab 0: Dashboard
      final dashboardNavFinder = find.byKey(const ValueKey('student-nav-dashboard'));
      expect(dashboardNavFinder, findsOneWidget);
      await tester.tap(dashboardNavFinder);
      await tester.pump();

      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(0),
          reason: 'Tapping Dashboard must return to index 0 with state preserved.');
      expect(find.byType(StudentDashboardScreen), findsOneWidget,
          reason: 'StudentDashboardScreen must be active and visible on stage.');

      // 7. Verify all 4 tabs remain alive in the element tree (zero disposal)
      expect(find.byType(StudentDashboardScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(DiscoverScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(ApplicationsScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(ProfileTabScreen, skipOffstage: false), findsOneWidget);
    });
  });
}
