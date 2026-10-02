// lib/features/home/presentation/home_screen.dart
//
// The main app shell. A Material 3 NavigationBar with four tabs and a center
// "+" action button that opens the Student Action Sheet (QR Scan + Document Upload):
//   Dashboard    — student overview, stats & recommendations
//   Discover     — personalized matches + full catalog
//   [+] Action   — opens Quick Actions bottom sheet (QR Scan + Document Upload)
//   Tracker      — the student's status-aware tracking surface
//   Profile      — profile summary & credentials
//
// Uses TabContentCrossFade so tab switches are smooth and responsive.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/features/applications/presentation/applications_screen.dart';
import 'package:scholaris/features/dashboard/presentation/student_dashboard_screen.dart';
import 'package:scholaris/features/scholarships/screens/discover_screen.dart';
import 'package:scholaris/features/profile/presentation/profile_tab_screen.dart';
import 'widgets/student_action_sheet.dart';

/// The selected bottom-navigation tab. Exposed so in-page actions (e.g. the
/// Discover "See all" link) can navigate without touching routing architecture.
/// Defaults to the Discover tab.
class HomeTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) {
    if (state != index) {
      HapticFeedback.selectionClick();
      state = index;
    }
  }
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
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: TabContentCrossFade(
              activeKey: ValueKey<int>(tabIndex),
              child: _tabs[tabIndex],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Center(
                  heightFactor: 1.0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SizedBox(
                      height: 64,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 4-Tab Frosted Glass Pill
                          Expanded(
                            child: SizedBox(
                              height: 64,
                              child: LiquidGlass(
                                borderRadius: 32,
                                blur: 20.0,
                                saturation: 1.8,
                                tintOpacity: 0.78,
                                showLightEdge: true,
                                lightEdgeColor: const Color(0x66FFFFFF),
                                child: SizedBox.expand(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _StudentNavItem(
                                      icon: Icons.home_outlined,
                                      selectedIcon: Icons.home_rounded,
                                      label: 'Dashboard',
                                      selected: tabIndex == 0,
                                      onTap: () => ref
                                          .read(homeTabIndexProvider.notifier)
                                          .selectTab(0),
                                    ),
                                  ),
                                  Expanded(
                                    child: _StudentNavItem(
                                      icon: Icons.explore_outlined,
                                      selectedIcon: Icons.explore,
                                      label: 'Discover',
                                      selected: tabIndex == 1,
                                      onTap: () => ref
                                          .read(homeTabIndexProvider.notifier)
                                          .selectTab(1),
                                    ),
                                  ),
                                  Expanded(
                                    child: _StudentNavItem(
                                      icon: Icons.assignment_outlined,
                                      selectedIcon: Icons.assignment,
                                      label: 'Tracker',
                                      selected: tabIndex == 2,
                                      onTap: () => ref
                                          .read(homeTabIndexProvider.notifier)
                                          .selectTab(2),
                                    ),
                                  ),
                                  Expanded(
                                    child: _StudentNavItem(
                                      icon: Icons.person_outline_rounded,
                                      selectedIcon: Icons.person,
                                      label: 'Profile',
                                      selected: tabIndex == 3,
                                      onTap: () => ref
                                          .read(homeTabIndexProvider.notifier)
                                          .selectTab(3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                          // Separate Detached Floating '+' Frosted Glass Circle Button
                          PressableScale(
                            scale: 0.94,
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: LiquidGlass(
                                borderRadius: 32,
                                blur: 20.0,
                                saturation: 1.8,
                                tintOpacity: 0.78,
                                showLightEdge: true,
                                lightEdgeColor: const Color(0x66FFFFFF),
                                child: Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      showStudentActionSheet(context);
                                    },
                                    child: const Center(
                                      child: Icon(
                                        Icons.add_rounded,
                                        color: Color(0xFF0F4D2E),
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentNavItem extends StatelessWidget {
  const _StudentNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFDCF3E5) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                size: 20,
                color: selected
                    ? const Color(0xFF0F4D2E)
                    : const Color(0xFF5A625C),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: outfit(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? const Color(0xFF0F4D2E)
                    : const Color(0xFF5A625C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}