import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class AdminTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) => state = index;
}

final adminTabIndexProvider = NotifierProvider<AdminTabIndexNotifier, int>(
  AdminTabIndexNotifier.new,
);

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key, this.initialTab});

  final int? initialTab;

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
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
    if (widget.initialTab != null && widget.initialTab != oldWidget.initialTab) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(adminTabIndexProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: kAdminSurface,
        body: Row(
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
                    child: IndexedStack(
                      index: tabIndex,
                      children: _tabs,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet Drawer Layout (< 768px)
    return Scaffold(
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
            const ScholarisLogo(compact: true, showWordmark: false, badgeSize: 28),
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
      body: IndexedStack(
        index: tabIndex,
        children: _tabs,
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: kAdminHairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Search box
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kAdminHairline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 18, color: kAdminTextSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⌘K Search scholars, grants, audits...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: kAdminTextSecondary.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Academic Year badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: kAdminBridgeGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'AY 2024–2025 • Semester 1',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kAdminTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
    return Container(
      decoration: BoxDecoration(
        color: kAdminSidebarBackground,
        border: isDrawer
            ? null
            : const Border(
                right: BorderSide(color: kAdminHairline, width: 1),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Header with real Scholaris Logo (strictly NO window-chrome dots)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const ScholarisLogo(
                  badgeSize: 30,
                  iconSize: 18,
                  fontSize: 18,
                  compact: true,
                  showWordmark: false,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scholaris Admin',
                    style: adminHeaderStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: kAdminNavyTrust,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E2E7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'OPS',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFF404942),
                    ),
                  ),
                ),
                if (isDrawer) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: kAdminTextSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: kAdminHairline),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
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
                    onTap: () {
                      ref.read(adminTabIndexProvider.notifier).selectTab(0);
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                  _SidebarNavItem(
                    label: 'Scholarships',
                    icon: Icons.school_outlined,
                    selectedIcon: Icons.school_rounded,
                    isSelected: tabIndex == 1,
                    onTap: () {
                      ref.read(adminTabIndexProvider.notifier).selectTab(1);
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                  _SidebarNavItem(
                    label: 'Providers',
                    icon: Icons.verified_user_outlined,
                    selectedIcon: Icons.verified_user_rounded,
                    isSelected: tabIndex == 2,
                    onTap: () {
                      ref.read(adminTabIndexProvider.notifier).selectTab(2);
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 6),
                  // Management Section
                  _sectionHeader('Management'),
                  _SidebarNavItem(
                    label: 'Applicants',
                    icon: Icons.people_outline_rounded,
                    selectedIcon: Icons.people_rounded,
                    isSelected: tabIndex == 3,
                    onTap: () {
                      ref.read(adminTabIndexProvider.notifier).selectTab(3);
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                  _SidebarNavItem(
                    label: 'Users',
                    icon: Icons.manage_accounts_outlined,
                    selectedIcon: Icons.manage_accounts_rounded,
                    isSelected: tabIndex == 4,
                    onTap: () {
                      ref.read(adminTabIndexProvider.notifier).selectTab(4);
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 6),
                  // Intelligence Section
                  _sectionHeader('Intelligence'),
                  _SidebarNavItem(
                    label: 'Analytics',
                    icon: Icons.insights_outlined,
                    selectedIcon: Icons.insights_rounded,
                    isSelected: tabIndex == 5,
                    onTap: () {
                      ref.read(adminTabIndexProvider.notifier).selectTab(5);
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                  _SidebarNavItem(
                    label: 'Audit Logs',
                    icon: Icons.fact_check_outlined,
                    selectedIcon: Icons.fact_check_rounded,
                    isSelected: tabIndex == 6,
                    onTap: () {
                      ref.read(adminTabIndexProvider.notifier).selectTab(6);
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Consistent Apple-style profile / sign-out footer block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: kAdminHairline, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: kAdminBridgeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Console active',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: kAdminTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: kAdminBridgeGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Admin Console',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kAdminTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'CHED Officer',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: kAdminTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: kAdminHairline),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          // Switch to audit logs / settings tab
                          ref.read(adminTabIndexProvider.notifier).selectTab(6);
                          if (isDrawer) Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tune_rounded, size: 14, color: kAdminTextSecondary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Settings',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: kAdminTextSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFE53935)),
                      tooltip: 'Sign out',
                      onPressed: () => _handleSignOut(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: const Color(0xFF707971),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isSelected ? kAdminActiveNavBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: isSelected ? null : const Color(0xFFE9E7ED),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: Color(0x1F0F4D2E),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 19,
                  color: isSelected ? kAdminActiveNavText : const Color(0xFF5E6D66),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? kAdminActiveNavText : kAdminInactiveNavText,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
