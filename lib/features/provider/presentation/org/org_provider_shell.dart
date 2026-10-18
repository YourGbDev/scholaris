// lib/features/provider/presentation/org/org_provider_shell.dart
//
// Institutional / Organization Provider Console Shell
// Apple Design DNA pass: 256px light sidebar (#F5F5F7), active green fill (#0F4D2E)
// with pure white text, profile footer block, clean top bar, and real Scholaris branding.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/profile/models/applicant_profile.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import '../../providers/provider_scholarships_provider.dart';
import '../../providers/provider_sub_role_provider.dart';
import '../scholarship_form_screen.dart';
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

  void _openCommandPalette(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x33000000),
      builder: (dialogCtx) {
        return _OrgCommandPaletteDialog(
          onSelectTab: (tabIndex) {
            setState(() => _selectedTab = tabIndex);
          },
          onOpenNewGrant: () {
            Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (_) => const ScholarshipFormScreen(),
              ),
            );
          },
          onSelectApplication: (app, scholarship, profile) {
            ApplicantReviewDrawer.show(
              context,
              application: app,
              scholarship: scholarship,
              applicantProfile: profile,
              onStatusChanged: () {
                ref.read(incomingApplicationsProvider.notifier).refresh();
              },
            );
          },
        );
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
    final identity = ref.watch(providerSubRoleProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    // RBAC tab enforcement:
    // Finance Officer only has access to Disbursements (4), Analytics (3), Settings (5).
    // Evaluator only has access to Applications (0), Decisioning (1), Scholarships (2), Settings (5).
    if (identity.isFinance && (_selectedTab < 3)) {
      _selectedTab = 4;
    } else if (identity.isEvaluator && (_selectedTab == 3 || _selectedTab == 4)) {
      _selectedTab = 0;
    }

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

    final shellScaffold = isDesktop
        ? Scaffold(
            backgroundColor: kOrgCanvas,
            body: Row(
              children: [
                // Persistent 256px Apple Light Sidebar
                SizedBox(
                  width: 256,
                  child: _buildSidebarContent(context, identity, isDrawer: false),
                ),

                // Main Workspace (Top Bar + Active Tab Surface)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(context, identity),
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
          )
        : Scaffold(
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
                      style: orgHeadline(
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
                  tooltip: 'Search (⌘K)',
                  icon: const Icon(Icons.search_rounded, color: kOrgTextPrimary, size: 20),
                  onPressed: () => _openCommandPalette(context),
                ),
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
                child: _buildSidebarContent(context, identity, isDrawer: true),
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

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyK &&
            (HardwareKeyboard.instance.isMetaPressed ||
                HardwareKeyboard.instance.isControlPressed)) {
          _openCommandPalette(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: shellScaffold,
    );
  }

  Widget _buildTopBar(BuildContext context, ProviderIdentityInfo identity) {
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
              child: PressableScale(
                scale: 0.985,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _openCommandPalette(context),
                    hoverColor: const Color(0xFFEBEAF0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
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
                              '⌘K Search applicants...',
                              style: orgBody(
                                fontSize: 13,
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
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Dynamic Top Header Eyebrow Tag (Evaluator vs Finance Desk)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: identity.isFinance
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF4F3F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: identity.isFinance
                    ? const Color(0xFFB3F1C6)
                    : kOrgHairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  identity.isFinance
                      ? Icons.account_balance_wallet_rounded
                      : Icons.verified_user_rounded,
                  size: 13,
                  color: identity.isFinance ? const Color(0xFF0F4D2E) : kOrgPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  identity.topEyebrow,
                  style: orgLabel(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: identity.isFinance ? const Color(0xFF0F4D2E) : kOrgTextPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action button depending on role
          if (identity.isEvaluator && screenWidth >= 980) ...[
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _selectedTab = 2);
              },
              icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
              label: Text(
                'New Grant',
                style: orgLabel(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrgPrimary,
                elevation: 0,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (identity.isFinance && screenWidth >= 980) ...[
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _selectedTab = 4);
              },
              icon: const Icon(Icons.payments_rounded, size: 16, color: Colors.white),
              label: Text(
                'Disbursements',
                style: orgLabel(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4D2E),
                elevation: 0,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              identity.initials,
              style: orgLabel(
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
    ProviderIdentityInfo identity, {
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
                    style: orgHeadline(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: kOrgTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: identity.isFinance
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFE3E2E7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: identity.isFinance
                          ? const Color(0xFFB3F1C6)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    identity.isFinance ? 'FINANCE' : 'EVALUATOR',
                    style: orgLabel(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: identity.isFinance
                          ? const Color(0xFF0F4D2E)
                          : const Color(0xFF404942),
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

          // Scrollable Nav Items (Strict RBAC Filtered)
          Expanded(
            child: SingleChildScrollView(
              physics: const AppleBouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (identity.isEvaluator) ...[
                    _sectionHeader('Academic & Intake'),
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
                  ] else ...[
                    _sectionHeader('Treasury & Operations'),
                    _buildNavItem(
                      index: 4,
                      icon: Icons.payments_outlined,
                      activeIcon: Icons.payments_rounded,
                      label: 'Disbursements',
                      isDrawer: isDrawer,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.insights_outlined,
                      activeIcon: Icons.insights_rounded,
                      label: 'Analytics & Impact',
                      isDrawer: isDrawer,
                    ),
                  ],
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
                        identity.initials,
                        style: orgLabel(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
                            identity.name,
                            style: orgHeadline(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kOrgTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            identity.roleSubtitle,
                            style: orgLabel(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
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
                                  style: orgLabel(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
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
                                  style: orgLabel(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
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
        style: orgLabel(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: kOrgTextMuted,
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
                      begin: isSelected ? const Color(0xFF5E6D66) : kOrgActiveNavText,
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
                      style: orgBody(
                        fontSize: 13.5,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? kOrgActiveNavText
                            : kOrgInactiveNavText,
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

class _OrgCommandPaletteDialog extends ConsumerStatefulWidget {
  const _OrgCommandPaletteDialog({
    required this.onSelectTab,
    required this.onOpenNewGrant,
    required this.onSelectApplication,
  });

  final void Function(int tabIndex) onSelectTab;
  final VoidCallback onOpenNewGrant;
  final void Function(
    Application app,
    Scholarship? scholarship,
    ApplicantProfile? profile,
  ) onSelectApplication;

  @override
  ConsumerState<_OrgCommandPaletteDialog> createState() =>
      _OrgCommandPaletteDialogState();
}

class _PaletteActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? trailingBadge;
  final String section;
  final VoidCallback onSelect;

  _PaletteActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailingBadge,
    required this.section,
    required this.onSelect,
  });
}

class _OrgCommandPaletteDialogState
    extends ConsumerState<_OrgCommandPaletteDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  int _highlightedIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scholarships =
        ref.watch(providerScholarshipsProvider).valueOrNull ?? [];
    final apps = ref.watch(incomingApplicationsProvider).valueOrNull ?? [];
    final profiles =
        ref.watch(providerApplicantProfilesProvider).valueOrNull ?? {};
    final scholarshipsMap = {for (final s in scholarships) s.id: s};

    final q = _query.trim().toLowerCase();

    // 1. Navigation items
    final allNavItems = [
      (
        title: 'Incoming Applications',
        subtitle: 'Review & triage applicant dossiers',
        icon: Icons.inbox_outlined,
        action: () => widget.onSelectTab(0)
      ),
      (
        title: 'Decisioning Pool',
        subtitle: 'Deliberate & finalize grant awards',
        icon: Icons.rate_review_outlined,
        action: () => widget.onSelectTab(1)
      ),
      (
        title: 'My Scholarships',
        subtitle: 'Portfolio of endowments and criteria',
        icon: Icons.folder_special_outlined,
        action: () => widget.onSelectTab(2)
      ),
      (
        title: 'Create New Grant',
        subtitle: 'Configure new scholarship endowment',
        icon: Icons.add_circle_outline_rounded,
        action: widget.onOpenNewGrant
      ),
      (
        title: 'Analytics & Impact',
        subtitle: 'Demographics, GWA and social mobility',
        icon: Icons.insights_outlined,
        action: () => widget.onSelectTab(3)
      ),
      (
        title: 'Disbursements',
        subtitle: 'CHED tranche payouts & liquidation ledger',
        icon: Icons.payments_outlined,
        action: () => widget.onSelectTab(4)
      ),
      (
        title: 'Settings & Profile',
        subtitle: 'Organization details & credentials',
        icon: Icons.manage_accounts_outlined,
        action: () => widget.onSelectTab(5)
      ),
    ];

    final matchingNav = q.isEmpty
        ? allNavItems
        : allNavItems
            .where((item) =>
                item.title.toLowerCase().contains(q) ||
                item.subtitle.toLowerCase().contains(q))
            .toList();

    // 2. Matching Scholarships
    final matchingScholarships = q.isEmpty
        ? <Scholarship>[]
        : scholarships
            .where((s) =>
                s.title.toLowerCase().contains(q) ||
                (s.description?.toLowerCase().contains(q) ?? false))
            .take(4)
            .toList();

    // 3. Matching Applications
    final matchingApps = q.isEmpty
        ? <Application>[]
        : apps.where((a) {
            final p = profiles[a.userId];
            final name = p?.fullName.toLowerCase() ?? '';
            final school = p?.school?.toLowerCase() ?? '';
            final course = p?.course.toLowerCase() ?? '';
            return name.contains(q) || school.contains(q) || course.contains(q);
          }).take(4).toList();

    // Assemble flattened action list for keyboard arrow navigation
    final flatItems = <_PaletteActionItem>[];

    // 1. Matching Applications
    for (final app in matchingApps) {
      final p = profiles[app.userId];
      final s = scholarshipsMap[app.scholarshipId];
      final name = p?.fullName.trim().isNotEmpty == true ? p!.fullName : 'Applicant';
      flatItems.add(_PaletteActionItem(
        title: name,
        subtitle: '${p?.course ?? "Undergraduate"} • ${p?.school ?? "Accredited University"}',
        icon: Icons.person_outline_rounded,
        trailingBadge: s?.title,
        section: 'APPLICANTS',
        onSelect: () => widget.onSelectApplication(app, s, p),
      ));
    }

    // 2. Matching Scholarships
    for (final s in matchingScholarships) {
      flatItems.add(_PaletteActionItem(
        title: s.title,
        subtitle: '₱${s.awardAmount} / scholar • ${s.slots != null ? "${s.slots} slots" : "Uncapped"}',
        icon: Icons.school_outlined,
        section: 'GRANT PROGRAMS',
        onSelect: () => widget.onSelectTab(2),
      ));
    }

    // 3. Navigation / Commands
    for (final item in matchingNav) {
      flatItems.add(_PaletteActionItem(
        title: item.title,
        subtitle: item.subtitle,
        icon: item.icon,
        section: q.isEmpty ? 'QUICK NAVIGATION' : 'COMMANDS',
        onSelect: item.action,
      ));
    }

    final safeHighlight = flatItems.isEmpty
        ? 0
        : _highlightedIndex.clamp(0, flatItems.length - 1);

    KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (flatItems.isNotEmpty) {
          setState(() {
            _highlightedIndex = (_highlightedIndex + 1) % flatItems.length;
          });
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (flatItems.isNotEmpty) {
          setState(() {
            _highlightedIndex =
                (_highlightedIndex - 1 + flatItems.length) % flatItems.length;
          });
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (flatItems.isNotEmpty && safeHighlight < flatItems.length) {
          Navigator.of(context).pop();
          flatItems[safeHighlight].onSelect();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: handleKeyEvent,
          child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kOrgHairline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: kOrgHairline)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 20, color: kOrgPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (val) => setState(() {
                          _query = val;
                          _highlightedIndex = 0;
                        }),
                        onSubmitted: (_) {
                          if (flatItems.isNotEmpty &&
                              safeHighlight < flatItems.length) {
                            Navigator.of(context).pop();
                            flatItems[safeHighlight].onSelect();
                          }
                        },
                        style: orgBody(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search grants, applicants, or jump to page...',
                          hintStyle: orgBody(fontSize: 14, color: kOrgTextMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: kOrgTextSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F3F8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kOrgHairline),
                      ),
                      child: Text(
                        'ESC',
                        style: orgLabel(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: kOrgTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Search Results
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (flatItems.isNotEmpty) ...[
                        Builder(builder: (ctx) {
                          String? currentSection;
                          final tiles = <Widget>[];
                          for (int i = 0; i < flatItems.length; i++) {
                            final item = flatItems[i];
                            if (item.section != currentSection) {
                              currentSection = item.section;
                              tiles.add(_buildSectionHeader(currentSection));
                            }
                            tiles.add(_buildResultTile(
                              title: item.title,
                              subtitle: item.subtitle,
                              icon: item.icon,
                              trailingBadge: item.trailingBadge,
                              isSelected: safeHighlight == i,
                              onHover: () {
                                if (_highlightedIndex != i) {
                                  setState(() => _highlightedIndex = i);
                                }
                              },
                              onTap: () {
                                Navigator.of(context).pop();
                                item.onSelect();
                              },
                            ));
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: tiles,
                          );
                        }),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 36, horizontal: 24),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.search_off_rounded,
                                    size: 36, color: kOrgTextSecondary),
                                const SizedBox(height: 8),
                                Text(
                                  'No results for "$_query"',
                                  style: orgHeadline(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kOrgTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try searching for applicant names, grant titles, or navigation tabs.',
                                  style: orgBody(
                                    fontSize: 12,
                                    color: kOrgTextSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Shortcut Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF9FD),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: kOrgHairline)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEDF3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('↑↓', style: orgLabel(fontSize: 10, fontWeight: FontWeight.w700, color: kOrgTextPrimary)),
                    ),
                    const SizedBox(width: 4),
                    Text('navigate', style: orgLabel(fontSize: 11, color: kOrgTextSecondary)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEDF3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('↵', style: orgLabel(fontSize: 10, fontWeight: FontWeight.w700, color: kOrgTextPrimary)),
                    ),
                    const SizedBox(width: 4),
                    Text('select', style: orgLabel(fontSize: 11, color: kOrgTextSecondary)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEDF3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('ESC', style: orgLabel(fontSize: 10, fontWeight: FontWeight.w700, color: kOrgTextSecondary)),
                    ),
                    const SizedBox(width: 4),
                    Text('dismiss', style: orgLabel(fontSize: 11, color: kOrgTextSecondary)),
                    const Spacer(),
                    Text(
                      'Provider Command Center',
                      style: orgLabel(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kOrgPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: orgLabel(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: kOrgTextMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildResultTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    String? trailingBadge,
    bool isSelected = false,
    VoidCallback? onHover,
  }) {
    return MouseRegion(
      onEnter: (_) => onHover?.call(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: isSelected
              ? kOrgPrimary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          hoverColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kOrgPrimary.withValues(alpha: 0.15)
                        : const Color(0xFFF4F3F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isSelected ? kOrgPrimary : kOrgTextSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: orgHeadline(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? kOrgPrimary : kOrgTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: orgBody(fontSize: 11.5, color: kOrgTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (trailingBadge != null) ...[
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEDF3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trailingBadge,
                        style: orgLabel(fontSize: 10, color: kOrgTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isSelected ? kOrgPrimary : const Color(0xFFC0C9C0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
