// lib/features/home/presentation/home_screen.dart
//
// The main app shell. A Material 3 NavigationBar with three tabs:
//   Discover  — personalized matches + full catalog
//   Saved     — bookmarked scholarships
//   Profile   — profile summary
//
// Uses IndexedStack so tab state (scroll position, loaded data) is preserved
// when the user switches tabs.

import 'package:flutter/material.dart';

import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/features/scholarships/screens/discover_screen.dart';
import 'package:scholaris/features/scholarships/screens/saved_screen.dart';
import 'package:scholaris/features/profile/presentation/profile_tab_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  static const _tabs = <Widget>[
    DiscoverScreen(),
    SavedScreen(),
    ProfileTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
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
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: kPrimary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}