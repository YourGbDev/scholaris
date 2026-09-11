import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_dashboard_tab.dart';
import 'admin_providers_tab.dart';
import 'admin_scholarships_tab.dart';
import 'admin_theme.dart';

class AdminTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) => state = index;
}

final adminTabIndexProvider = NotifierProvider<AdminTabIndexNotifier, int>(
  AdminTabIndexNotifier.new,
);

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  static const _tabs = <Widget>[
    AdminDashboardTab(),
    AdminScholarshipsTab(),
    AdminProvidersTab(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(adminTabIndexProvider);

    return Scaffold(
      backgroundColor: kAdminSurface,
      body: Row(
        children: [
          // Persistent Left Sidebar
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: kAdminSidebarBackground,
              border: Border(
                right: BorderSide(color: kAdminHairline, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kAdminBridgeGreen.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: kAdminBridgeGreen.withValues(alpha: 0.20),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: kAdminBridgeGreen,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Scholaris Admin',
                          style: adminHeaderStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kAdminNavyTrust,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: kAdminHairline),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Operations',
                    style: adminLabelStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kAdminTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  label: 'Overview',
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  isSelected: tabIndex == 0,
                  onTap: () => ref.read(adminTabIndexProvider.notifier).selectTab(0),
                ),
                _SidebarNavItem(
                  label: 'Scholarships',
                  icon: Icons.school_outlined,
                  selectedIcon: Icons.school_rounded,
                  isSelected: tabIndex == 1,
                  onTap: () => ref.read(adminTabIndexProvider.notifier).selectTab(1),
                ),
                _SidebarNavItem(
                  label: 'Providers',
                  icon: Icons.verified_user_outlined,
                  selectedIcon: Icons.verified_user_rounded,
                  isSelected: tabIndex == 2,
                  onTap: () => ref.read(adminTabIndexProvider.notifier).selectTab(2),
                ),
                const Spacer(),
                const Divider(height: 1, color: kAdminHairline),
                // Footer: Ops info & Sign out
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: kAdminBridgeGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Console Active',
                          style: adminLabelStyle(fontSize: 11),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: kAdminCoralConnect,
                          size: 18,
                        ),
                        tooltip: 'Sign out',
                        onPressed: () => Supabase.instance.client.auth.signOut(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Work Surface
          Expanded(
            child: IndexedStack(
              index: tabIndex,
              children: _tabs,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? kAdminBridgeGreen.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(
                      color: kAdminBridgeGreen.withValues(alpha: 0.20),
                      width: 1,
                    )
                  : Border.all(color: Colors.transparent, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 18,
                  color: isSelected ? kAdminBridgeGreen : kAdminTextSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: adminLabelStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? kAdminBridgeGreen : kAdminNavyTrust,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
