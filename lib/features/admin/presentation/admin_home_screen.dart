import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_analytics_tab.dart';
import 'admin_applicants_tab.dart';
import 'admin_audit_logs_tab.dart';
import 'admin_dashboard_tab.dart';
import 'admin_providers_tab.dart';
import 'admin_scholarships_tab.dart';
import 'admin_theme.dart';
import 'admin_users_tab.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';

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
    AdminApplicantsTab(),
    AdminUsersTab(),
    AdminAnalyticsTab(),
    AdminAuditLogsTab(),
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
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kAdminBridgeGreen.withValues(alpha: 0.10),
                          borderRadius: kAdminChromeRadius,
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Operations Section
                        _sectionHeader('Operations'),
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
                        const SizedBox(height: 12),
                        // Management Section
                        _sectionHeader('Management'),
                        _SidebarNavItem(
                          label: 'Applicants',
                          icon: Icons.people_outline_rounded,
                          selectedIcon: Icons.people_rounded,
                          isSelected: tabIndex == 3,
                          onTap: () => ref.read(adminTabIndexProvider.notifier).selectTab(3),
                        ),
                        _SidebarNavItem(
                          label: 'Users',
                          icon: Icons.manage_accounts_outlined,
                          selectedIcon: Icons.manage_accounts_rounded,
                          isSelected: tabIndex == 4,
                          onTap: () => ref.read(adminTabIndexProvider.notifier).selectTab(4),
                        ),
                        const SizedBox(height: 12),
                        // Intelligence Section
                        _sectionHeader('Intelligence'),
                        _SidebarNavItem(
                          label: 'Analytics',
                          icon: Icons.insights_outlined,
                          selectedIcon: Icons.insights_rounded,
                          isSelected: tabIndex == 5,
                          onTap: () => ref.read(adminTabIndexProvider.notifier).selectTab(5),
                        ),
                        _SidebarNavItem(
                          label: 'Audit Logs',
                          icon: Icons.fact_check_outlined,
                          selectedIcon: Icons.fact_check_rounded,
                          isSelected: tabIndex == 6,
                          onTap: () => ref.read(adminTabIndexProvider.notifier).selectTab(6),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: kAdminHairline),
                // Footer: Ops info & Sign out
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          'Console active',
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
                        onPressed: () async {
                          final confirmed =
                              await showLogoutConfirmationDialog(context);
                          if (confirmed) {
                            try {
                              await Supabase.instance.client.auth.signOut();
                            } catch (_) {}
                          }
                        },
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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Text(
        title,
        style: adminLabelStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: kAdminTextSecondary,
        ),
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
        borderRadius: kAdminChromeRadius,
        child: InkWell(
          borderRadius: kAdminChromeRadius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: kAdminChromeRadius,
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
