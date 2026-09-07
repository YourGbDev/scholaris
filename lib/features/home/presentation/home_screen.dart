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
import 'package:scholaris/features/scholarships/screens/discover_screen.dart';
import 'package:scholaris/features/scholarships/screens/saved_screen.dart';
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
    DiscoverScreen(),
    SavedScreen(),
    ApplicationsScreen(embedded: true),
    ProfileTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: IndexedStack(index: tabIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) =>
            ref.read(homeTabIndexProvider.notifier).selectTab(i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.language_outlined),
            selectedIcon: Icon(Icons.language, color: kPrimary),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded, color: kPrimary),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.send_outlined),
            selectedIcon: Icon(Icons.send_rounded, color: kPrimary),
            label: 'Applications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: kPrimary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}