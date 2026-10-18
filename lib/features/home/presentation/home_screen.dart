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
            child: IndexedStack(
              index: tabIndex,
              children: _tabs,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.sizeOf(context).width;
                final horizontalPad = screenWidth < 360 ? 8.0 : 16.0;
                // Align snugly near the bottom edge while respecting the safe area / home indicator
                final safeBottom = MediaQuery.paddingOf(context).bottom;
                final bottomPad = safeBottom > 0 ? (safeBottom * 0.35).clamp(4.0, 10.0) : 8.0;

                return Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, bottomPad),
                  child: Center(
                    heightFactor: 1.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: SizedBox(
                        height: 62,
                        // Unified Frosted Glass Dock (Pill + Quick Action Button)
                        child: LiquidGlass(
                          borderRadius: 31,
                          blur: 24.0,
                          saturation: 1.8,
                          tintOpacity: 0.68,
                          showLightEdge: true,
                          lightEdgeColor: const Color(0x66FFFFFF),
                          child: SizedBox.expand(
                            child: Row(
                              children: [
                                // 4 Student Navigation Tabs
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: _StudentNavItem(
                                          key: const ValueKey('student-nav-dashboard'),
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
                                          key: const ValueKey('student-nav-discover'),
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
                                          key: const ValueKey('student-nav-tracker'),
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
                                          key: const ValueKey('student-nav-profile'),
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
                                // Subtle vertical hairline divider
                                Container(
                                  width: 1,
                                  height: 28,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  color: const Color(0x1F000000),
                                ),
                                // Quick Action '+' Button integrated into frosted dock
                                PressableScale(
                                  scale: 0.92,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    showStudentActionSheet(context);
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    margin: const EdgeInsets.only(right: 6, left: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF0F4D2E),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0F4D2E).withValues(alpha: 0.28),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 26,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentNavItem extends StatelessWidget {
  const _StudentNavItem({
    super.key,
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
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width < 360 ? 6.0 : 12.0,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFDCF3E5) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              selected ? selectedIcon : icon,
              size: 20,
              color: selected
                  ? const Color(0xFF0F4D2E)
                  : const Color(0xFF1C1C1E), // Bold high-contrast black
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: outfit(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected
                    ? const Color(0xFF0F4D2E)
                    : const Color(0xFF1C1C1E), // Bold high-contrast black per review
              ),
            ),
          ),
        ],
      ),
    );
  }
}