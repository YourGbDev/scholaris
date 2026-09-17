// lib/features/home/presentation/home_screen.dart
//
// The main app shell. A Material 3 NavigationBar with four tabs:
//   Discover     — personalized matches + full catalog
//   Saved        — bookmarked scholarships
//   Applications — the student's status-aware tracking surface
//   Profile      — profile summary
//
// Uses IndexedStack so tab state (scroll position, loaded data) is preserved
// when the user switches tabs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/features/applications/presentation/applications_screen.dart';
import 'package:scholaris/features/dashboard/presentation/student_dashboard_screen.dart';
import 'package:scholaris/features/scholarships/screens/discover_screen.dart';
import 'package:scholaris/features/profile/presentation/profile_tab_screen.dart';

/// The selected bottom-navigation tab. Exposed so in-page actions (e.g. the
/// Discover "See all" link) can navigate without touching routing architecture.
/// Defaults to the Discover tab.
class HomeTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) => state = index;
}

final homeTabIndexProvider = NotifierProvider<HomeTabIndexNotifier, int>(
  HomeTabIndexNotifier.new,
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _tabs = <Widget>[
    StudentDashboardScreen(),
    DiscoverScreen(),
    ApplicationsScreen(embedded: true),
    ProfileTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: IndexedStack(index: tabIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: kBorderLight, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: tabIndex,
          onDestinationSelected: (i) =>
              ref.read(homeTabIndexProvider.notifier).selectTab(i),
          backgroundColor: Colors.white,
          indicatorColor: kPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          height: 64,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Colors.white),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded, color: Colors.white),
              label: 'Discover',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded, color: Colors.white),
              label: 'Tracker',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: Colors.white),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}