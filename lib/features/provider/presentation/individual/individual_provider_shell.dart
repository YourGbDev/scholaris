import 'individual_support_tab.dart';
// lib/features/provider/presentation/individual/individual_provider_shell.dart
//
// Responsive workspace for individual providers.
// Desktop sidebar and compact four-destination navigation share a
// shared navigation destinations and interruptible content transitions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import 'package:scholaris/shared/theme/app_motion.dart';

import '../org/org_provider_theme.dart';
import '../widgets/provider_verification_banner.dart';
import '../widgets/provider_overview_panel.dart';
import '../widgets/org_workspace_transition.dart';
import '../../providers/provider_sub_role_provider.dart';
import 'individual_applications_tab.dart';
import 'individual_grant_tab.dart';
import 'individual_settings_tab.dart';
import '../../../../core/auth/landing_redirect.dart';

class IndividualProviderShell extends ConsumerStatefulWidget {
  const IndividualProviderShell({super.key, this.initialIndex = 3});

  final int initialIndex;

  @override
  ConsumerState<IndividualProviderShell> createState() =>
      _IndividualProviderShellState();
}

class _IndividualProviderShellState
    extends ConsumerState<IndividualProviderShell> {
  late int _currentIndex;
  bool _showAwaitingReview = false;
  final _motionBucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const _tabs = <Widget>[
    IndividualApplicationsTab(),
    IndividualGrantTab(),
    IndividualSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(providerSubRoleProvider);
    final content = _currentIndex == 3
        ? ProviderOverview(
            individual: true,
            onSupport: () => setState(() => _currentIndex = 4),
            onApplications: () => setState(() { _showAwaitingReview = false; _currentIndex = 0; }),
            onPendingApplications: () => setState(() { _showAwaitingReview = true; _currentIndex = 0; }),
            onScholarships: () => setState(() => _currentIndex = 1),
          )
        : _currentIndex == 4
        ? const IndividualSupportTab()
        : _currentIndex == 0
        ? IndividualApplicationsTab(key: ValueKey(_showAwaitingReview), initialAwaitingReview: _showAwaitingReview)
        : _tabs[_currentIndex];
    if (MediaQuery.sizeOf(context).width >= 900) {
      return Scaffold(
        backgroundColor: kOrgCanvas,
        body: Row(
          children: [
            Container(
              width: 224,
              decoration: const BoxDecoration(
                color: kOrgSidebarLight,
                border: Border(right: BorderSide(color: kOrgBorder)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ScholarisLogo(
                              badgeSize: 30,
                              fontSize: 21,
                              compact: true,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Individual provider',
                              style: orgBody(
                                fontSize: 12,
                                color: kOrgTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 28),
                            for (final item in [
                              (3, 'Overview', Icons.home_outlined),
                              (1, 'My scholarships', Icons.school_outlined),
                              (0, 'Applications', Icons.description_outlined),
                              (
                                4,
                                'Budget & support',
                                Icons.account_balance_wallet_outlined,
                              ),
                              (
                                2,
                                'Profile & settings',
                                Icons.settings_outlined,
                              ),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                  child: AnimatedContainer(
                                    duration: isReducedMotion(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 160),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      color: _currentIndex == item.$1
                                          ? kOrgPrimary
                                          : kOrgPrimary.withValues(alpha: 0),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                      child: ListTile(
                                    dense: true,
                                    minTileHeight: 44,
                                    horizontalTitleGap: 12,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    selected: _currentIndex == item.$1,
                                    selectedTileColor: Colors.transparent,
                                    selectedColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    leading: Icon(
                                      item.$3,
                                      size: 20,
                                      color: _currentIndex == item.$1
                                          ? Colors.white
                                          : kOrgTextSecondary,
                                    ),
                                    title: Text(
                                      item.$2,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: orgBody(
                                        fontSize: 13,
                                        color: _currentIndex == item.$1
                                            ? Colors.white
                                            : kOrgTextPrimary,
                                        fontWeight: _currentIndex == item.$1
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                    onTap: () =>
                                        setState(() { _showAwaitingReview = false; _currentIndex = item.$1; }),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            const Divider(color: kOrgBorder),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: kOrgPrimary,
                                  child: Text(
                                    identity.initials,
                                    style: orgLabel(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        identity.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: orgLabel(fontSize: 12),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Individual provider',
                                        style: orgBody(
                                          fontSize: 11,
                                          color: kOrgTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(children: [
                            Expanded(child: TextButton.icon(
                              onPressed: () =>
                                  setState(() => _currentIndex = 2),
                              style: TextButton.styleFrom(
                                foregroundColor: kOrgTextSecondary,
                                padding: EdgeInsets.zero,
                                textStyle: orgLabel(fontSize: 11),
                              ),
                              icon: const Icon(
                                Icons.settings_outlined,
                                size: 14,
                              ),
                              label: const Text('Preferences', maxLines: 1, overflow: TextOverflow.ellipsis),
                            )),
                            Expanded(child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: kOrgError,
                                padding: EdgeInsets.zero,
                                textStyle: orgLabel(fontSize: 11),
                              ),
                              onPressed: () async {
                                if (await showLogoutConfirmationDialog(
                                  context,
                                )) {
                                  await handleProviderSignOut();
                                }
                              },
                              icon: const Icon(Icons.logout_rounded, size: 14),
                              label: const Text('Sign out', maxLines: 1, overflow: TextOverflow.ellipsis),
                            )),
                            ]),
                          ],
                        ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const ProviderVerificationBanner(),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: OrgWorkspaceTransition(
                          activeKey: ValueKey(_currentIndex),
                          child: PageStorage(
                            bucket: _motionBucket,
                            child: content,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: kOrgCanvas,
      appBar: AppBar(
        backgroundColor: kOrgSidebarLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: kOrgHairline, width: 1)),
        title: Row(
          children: [
            const ScholarisLogo(badgeSize: 28, fontSize: 18, compact: true),
            const SizedBox(width: 8),
            if (MediaQuery.sizeOf(context).width >= 440)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E2E7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'BENEFACTOR',
                  style: orgLabel(
                    color: const Color(0xFF404942),
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: kOrgError, size: 20),
            tooltip: 'Sign out',
            onPressed: () async {
              final confirmed = await showLogoutConfirmationDialog(context);
              if (confirmed) {
                await handleProviderSignOut();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const ProviderVerificationBanner(),
          Expanded(
            child: OrgWorkspaceTransition(
              activeKey: ValueKey<int>(_currentIndex),
              child: PageStorage(bucket: _motionBucket, child: content),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: const [3, 0, 1, 4, 2].indexOf(_currentIndex),
        onDestinationSelected: (index) =>
            setState(() { _showAwaitingReview = false; _currentIndex = const [3, 0, 1, 4, 2][index]; }),
        backgroundColor: kOrgSurfaceWhite,
        indicatorColor: kOrgPrimary.withValues(alpha: 0.12),
        elevation: 4,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined, color: kOrgTextMuted),
            selectedIcon: Icon(Icons.description_rounded, color: kOrgPrimary),
            label: 'Applications',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined, color: kOrgTextMuted),
            selectedIcon: Icon(Icons.school_rounded, color: kOrgPrimary),
            label: 'Scholarships',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Support',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: kOrgTextMuted),
            selectedIcon: Icon(Icons.person_rounded, color: kOrgPrimary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
