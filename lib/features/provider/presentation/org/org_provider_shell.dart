// lib/features/provider/presentation/org/org_provider_shell.dart
//
// Institutional / Organization Provider Console Shell
// Apple Design DNA pass: 256px light sidebar (#F5F5F7), active green fill (#0F4D2E)
// with pure white text, profile footer block, clean top bar, and real Scholaris branding.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import '../../providers/provider_scholarships_provider.dart';
import '../widgets/applicant_review_drawer.dart';
import '../widgets/provider_verification_banner.dart';
import 'org_analytics_tab.dart';
import 'org_disbursements_tab.dart';
import 'org_incoming_applications_tab.dart';
import 'org_provider_theme.dart';
import 'org_scholarships_tab.dart';
import 'org_settings_tab.dart';
import '../../../../core/auth/landing_redirect.dart';
import '../../../../shared/theme/app_motion.dart';

class OrgProviderShell extends ConsumerStatefulWidget {
  const OrgProviderShell({
    super.key,
    this.initialTab = 0,
    this.autoOpenDrawer = false,
  });

  final int initialTab;
  final bool autoOpenDrawer;

  @override
  ConsumerState<OrgProviderShell> createState() => _OrgProviderShellState();
}

class _OrgProviderShellState extends ConsumerState<OrgProviderShell> {
  late int _selectedTab;
  bool _drawerOpened = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    if (widget.autoOpenDrawer) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openDrawerOnce());
    }
  }

  void _openDrawerOnce() async {
    if (_drawerOpened || !mounted) return;
    _drawerOpened = true;
    final apps = await ref.read(incomingApplicationsProvider.future);
    if (apps.isEmpty || !mounted) return;
    final app = apps.first;
    final profiles = ref.read(providerApplicantProfilesProvider).valueOrNull ?? {};
    final scholarships = ref.read(providerScholarshipsProvider).valueOrNull ?? [];
    final scholarshipsMap = {for (final s in scholarships) s.id: s};
    if (!mounted) return;
    ApplicantReviewDrawer.show(
      context,
      application: app,
      scholarship: scholarshipsMap[app.scholarshipId],
      applicantProfile: profiles[app.userId],
      onStatusChanged: () {
        ref.read(incomingApplicationsProvider.notifier).refresh();
      },
    );
  }

  static Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (confirmed) {
      await handleProviderSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    final orgName = (profile?.fullName.trim().isNotEmpty == true)
        ? profile!.fullName.trim()
        : 'Ayala Foundation Partner';

    final initials = orgName.length >= 2
        ? orgName.substring(0, 2).toUpperCase()
        : 'AF';

    final tabs = [
      const OrgIncomingApplicationsTab(key: ValueKey('org_applications_tab')),
      const OrgIncomingApplicationsTab(
        key: ValueKey('org_decisioning_tab'),
        isDecisioningMode: true,
      ),
      OrgScholarshipsTab(
        key: const ValueKey('org_scholarships_tab'),
        onViewApplicationsForScholarship: (scholarshipId) {
          setState(() => _selectedTab = 0);
        },
      ),
      const OrgAnalyticsTab(key: ValueKey('org_analytics_tab')),
      const OrgDisbursementsTab(key: ValueKey('org_disbursements_tab')),
      const OrgSettingsTab(key: ValueKey('org_settings_tab')),
    ];

    if (isDesktop) {
      return Scaffold(
        backgroundColor: kOrgCanvas,
        body: Row(
          children: [
            // Persistent 256px Apple Light Sidebar
            SizedBox(
              width: 256,
              child: _buildSidebarContent(context, orgName, initials, isDrawer: false),
            ),

            // Main Workspace (Top Bar + Active Tab Surface)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(context, orgName, initials),
                  const ProviderVerificationBanner(),
                  Expanded(
                    child: TabContentCrossFade(
                      activeKey: ValueKey<int>(_selectedTab),
                      child: tabs[_selectedTab],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile Reflow Layout
      return Scaffold(
        backgroundColor: kOrgCanvas,
        appBar: AppBar(
          backgroundColor: kOrgSidebarLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const Border(
            bottom: BorderSide(color: kOrgHairline, width: 1),
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: kOrgTextPrimary),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ScholarisLogo(compact: true, showWordmark: false, badgeSize: 26),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Provider Console',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kOrgTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout_rounded, color: kOrgError, size: 20),
              onPressed: () => _handleSignOut(context),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: kOrgSidebarLight,
          child: SafeArea(
            child: _buildSidebarContent(context, orgName, initials, isDrawer: true),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProviderVerificationBanner(),
            Expanded(
              child: TabContentCrossFade(
                activeKey: ValueKey<int>(_selectedTab),
                child: tabs[_selectedTab],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTopBar(BuildContext context, String orgName, String initials) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: kOrgHairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Search box with Apple styling (NO window dots)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kOrgHairline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 18, color: kOrgTextSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⌘K Search applicants, grants...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          letterSpacing: 0.1,
                          color: kOrgTextSecondary.withValues(alpha: 0.8),
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
          const SizedBox(width: 12),
          // Academic Year badge
          if (screenWidth >= 960) ...[
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
                      color: kOrgPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AY 2024–2025 • Sem 1',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.15,
                      color: kOrgTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          // New Scholarship Grant Action Button
          if (screenWidth >= 880) ...[
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _selectedTab = 2);
              },
              icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
              label: Text(
                'New Grant',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrgPrimary,
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Sign out button
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded, size: 20, color: kOrgError),
            onPressed: () => _handleSignOut(context),
          ),
          const SizedBox(width: 8),
          // Profile initials avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: kOrgPrimary,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    String orgName,
    String initials, {
    required bool isDrawer,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kOrgSidebarLight,
        border: isDrawer
            ? null
            : const Border(
                right: BorderSide(color: kOrgHairline, width: 1),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header with real Scholaris Logo (NO window-chrome dots)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
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
                    'Provider Console',
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: kOrgTextPrimary,
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
                    'ORG',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: const Color(0xFF404942),
                    ),
                  ),
                ),
                if (isDrawer) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: kOrgTextSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: kOrgHairline),

          // Scrollable Nav Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Grants & Intake'),
                  _buildNavItem(
                    index: 0,
                    icon: Icons.inbox_outlined,
                    activeIcon: Icons.inbox_rounded,
                    label: 'Applications',
                    isDrawer: isDrawer,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.rate_review_outlined,
                    activeIcon: Icons.rate_review_rounded,
                    label: 'Decisioning',
                    isDrawer: isDrawer,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.folder_special_outlined,
                    activeIcon: Icons.folder_special_rounded,
                    label: 'My Scholarships',
                    isDrawer: isDrawer,
                  ),
                  const SizedBox(height: 12),
                  _sectionHeader('Operations'),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.insights_outlined,
                    activeIcon: Icons.insights_rounded,
                    label: 'Analytics & Impact',
                    isDrawer: isDrawer,
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.payments_outlined,
                    activeIcon: Icons.payments_rounded,
                    label: 'Disbursements',
                    isDrawer: isDrawer,
                  ),
                  const SizedBox(height: 12),
                  _sectionHeader('Account'),
                  _buildNavItem(
                    index: 5,
                    icon: Icons.manage_accounts_outlined,
                    activeIcon: Icons.manage_accounts_rounded,
                    label: 'Settings',
                    isDrawer: isDrawer,
                  ),
                ],
              ),
            ),
          ),

          // Profile / Sign-out footer block
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: kOrgHairline, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: kOrgPrimary,
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
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
                            orgName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              color: kOrgTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Lead Grant Administrator',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              letterSpacing: 0.2,
                              color: kOrgTextSecondary,
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
                const Divider(height: 1, color: kOrgHairline),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          setState(() => _selectedTab = 5);
                          if (isDrawer) Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.settings_outlined, size: 14, color: kOrgTextSecondary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Preferences',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                    color: kOrgTextSecondary,
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
                    Flexible(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _handleSignOut(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.logout_rounded, size: 14, color: kOrgError),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Sign Out',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                    color: kOrgError,
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: const Color(0xFF707971),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDrawer,
  }) {
    final isSelected = _selectedTab == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: PressableScale(
        scale: 0.98,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: isSelected ? Colors.transparent : const Color(0xFFE9E7ED),
            onTap: () {
              setState(() => _selectedTab = index);
              if (isDrawer) Navigator.of(context).pop();
            },
            child: AnimatedContainer(
              duration: kDurationStandard,
              curve: kEaseInOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                // Interpolates strictly in green channel alpha without ever touching transparent black
                color: isSelected
                    ? kOrgActiveNavBg
                    : kOrgActiveNavBg.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0x1F0F4D2E)
                        : const Color(0x000F4D2E),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  TweenAnimationBuilder<Color?>(
                    duration: kDurationStandard,
                    curve: kEaseInOut,
                    tween: ColorTween(
                      end: isSelected
                          ? kOrgActiveNavText
                          : const Color(0xFF5E6D66),
                    ),
                    builder: (context, color, _) {
                      return Icon(
                        isSelected ? activeIcon : icon,
                        size: 19,
                        color: color,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: kDurationStandard,
                      curve: kEaseInOut,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? kOrgActiveNavText
                            : kOrgInactiveNavText,
                        letterSpacing: 0,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
