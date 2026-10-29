import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/admin/screens/reports_safety_screen.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/features/safety/presentation/student_safety_report.dart';
import 'package:scholaris/features/provider/presentation/widgets/org_workspace_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_analytics_tab.dart';
import 'admin_applicants_tab.dart';
import 'admin_audit_logs_tab.dart';
import 'admin_dashboard_tab.dart';
import 'admin_providers_tab.dart';
import 'admin_scholarships_tab.dart';
import 'admin_theme.dart';
import 'admin_users_tab.dart';

import 'package:scholaris/admin/screens/admin_settings_screen.dart';
import 'package:scholaris/admin/screens/disbursements_oversight_screen.dart';

class AdminTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) => state = index;
}

final adminTabIndexProvider = NotifierProvider<AdminTabIndexNotifier, int>(
  AdminTabIndexNotifier.new,
);

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({
    super.key,
    this.initialTab,
    this.inspectApproved = false,
  });

  final int? initialTab;
  final bool inspectApproved;

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  List<Widget> _buildTabs() => [
    AdminDashboardTab(
      onProviders: () => ref.read(adminTabIndexProvider.notifier).selectTab(2),
      onReports: () => ref.read(adminTabIndexProvider.notifier).selectTab(9),
    ),
    const AdminScholarshipsTab(),
    const AdminProvidersTab(),
    AdminApplicantsTab(initialInspectApproved: widget.inspectApproved),
    const DisbursementsOversightScreen(),
    const AdminUsersTab(),
    const AdminAnalyticsTab(),
    const AdminAuditLogsTab(),
    const AdminSettingsScreen(),
    const ReportsSafetyScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminTabIndexProvider.notifier).selectTab(widget.initialTab!);
      });
    }
  }

  @override
  void didUpdateWidget(AdminHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null &&
        widget.initialTab != oldWidget.initialTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminTabIndexProvider.notifier).selectTab(widget.initialTab!);
      });
    }
  }

  static Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (confirmed) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      if (context.mounted) {
        context.go('/admin-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(adminTabIndexProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Theme(
      data: Theme.of(context).copyWith(
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          shadowColor: Color(0x06000000),
          shape: RoundedRectangleBorder(
            borderRadius: kAdminCardRadius,
            side: BorderSide(color: kAdminHairline),
          ),
        ),
      ),
      child: FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: isDesktop
          ? Scaffold(
              backgroundColor: kAdminSurface,
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Persistent Left Sidebar on Desktop (>= 768px, 256px wide Apple design)
                  SizedBox(
                    width: 256,
                    child: _buildSidebar(context, ref, tabIndex, isDrawer: false),
                  ),
                  // Main Work Surface with Apple Top Bar
                  Expanded(
                    child: Column(
                      children: [
                        _buildTopBar(context, ref),
                        Expanded(
                          child: OrgWorkspaceTransition(
                            activeKey: ValueKey<int>(tabIndex),
                            child: _buildTabs()[tabIndex],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Scaffold(
              backgroundColor: kAdminSurface,
              appBar: AppBar(
        backgroundColor: kAdminSidebarBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: kAdminHairline, width: 1),
        ),
        leading: Builder(
          builder: (drawerContext) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: kAdminNavyTrust),
            tooltip: 'Open navigation drawer',
            onPressed: () => Scaffold.of(drawerContext).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ScholarisLogo(
              compact: true,
              showWordmark: false,
              badgeSize: 28,
            ),
            const SizedBox(width: 8),
            Flexible(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, size: 20),
            tooltip: 'Live safety report dialog',
            onPressed: () {
              showDialog<bool>(
                animationStyle:
                    isReducedMotion(context) ? AnimationStyle.noAnimation : null,
                context: context,
                builder: (ctx) => const StudentSafetyReportDialog(
                  scholarshipId: 'individual-program',
                  scholarshipTitle: 'Bright Futures Scholarship',
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: kAdminCoralConnect,
              size: 20,
            ),
            tooltip: 'Sign out',
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: kAdminSidebarBackground,
        child: SafeArea(
          child: _buildSidebar(context, ref, tabIndex, isDrawer: true),
        ),
      ),
      body: OrgWorkspaceTransition(
        activeKey: ValueKey<int>(tabIndex),
        child: _buildTabs()[tabIndex],
      ),
    ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kAdminHairline, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Platform administration',
              style: geist(
                fontSize: 13,
                color: kAdminTextSecondary,
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF93000A)),
            label: const Text('Live safety report dialog', style: TextStyle(fontSize: 12, color: Color(0xFF93000A))),
            onPressed: () {
              showDialog<bool>(
                animationStyle:
                    isReducedMotion(context) ? AnimationStyle.noAnimation : null,
                context: context,
                builder: (ctx) => const StudentSafetyReportDialog(
                  scholarshipId: 'individual-program',
                  scholarshipTitle: 'Bright Futures Scholarship',
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // User avatar
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: kAdminBridgeGreen,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.admin_panel_settings_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    WidgetRef ref,
    int tabIndex, {
    required bool isDrawer,
  }) {
    void select(int index) {
      ref.read(adminTabIndexProvider.notifier).selectTab(index);
      if (isDrawer) Navigator.of(context).pop();
    }

    Widget link(String label, IconData icon, int index) => _SidebarNavItem(
      label: label,
      icon: icon,
      selectedIcon: icon,
      isSelected: tabIndex == index,
      onTap: () => select(index),
    );
    return Container(
      decoration: BoxDecoration(
        color: kAdminSidebarBackground,
        border: isDrawer
            ? null
            : const Border(right: BorderSide(color: kAdminHairline)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const ScholarisLogo(
                    compact: true,
                    showWordmark: false,
                    badgeSize: 30,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scholaris Admin',
                      style: adminHeaderStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isDrawer)
                    IconButton(
                      tooltip: 'Close navigation',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'SUPER ADMIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kAdminBridgeGreen,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _sectionHeader('Review & oversight'),
            link('Overview', Icons.dashboard_outlined, 0),
            link('Provider approvals', Icons.verified_user_outlined, 2),
            link('Reports & safety', Icons.flag_outlined, 9),
            _sectionHeader('Platform records'),
            link('Scholarships', Icons.school_outlined, 1),
            link('Student applications', Icons.people_outline_rounded, 3),
            link('Payment records', Icons.payments_outlined, 4),
            link('Users', Icons.manage_accounts_outlined, 5),
            _sectionHeader('Activity & settings'),
            link('Analytics', Icons.insights_outlined, 6),
            link('Audit Logs', Icons.fact_check_outlined, 7),
            link('Settings', Icons.settings_outlined, 8),
            const Divider(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Platform administration',
                style: TextStyle(fontSize: 12, color: kAdminTextSecondary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton.icon(
                onPressed: () => _handleSignOut(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        title,
        style: geist(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: kSeqOutline,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Semantics(
        selected: isSelected,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            backgroundColor: isSelected
                ? kAdminBridgeGreen
                : Colors.transparent,
            foregroundColor: isSelected ? Colors.white : kAdminInactiveNavText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Row(
            children: [
              Icon(isSelected ? selectedIcon : icon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: geist(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
