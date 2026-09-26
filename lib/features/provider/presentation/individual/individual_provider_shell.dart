// lib/features/provider/presentation/individual/individual_provider_shell.dart
//
// Mobile-first shell for Individual Benefactors.
// Features a compact Scholaris AppBar, 3-destination bottom navigation bar,
// and smooth state-preserving IndexedStack.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import '../org/org_provider_theme.dart';
import '../widgets/provider_verification_banner.dart';
import 'individual_applications_tab.dart';
import 'individual_grant_tab.dart';
import 'individual_settings_tab.dart';
import '../../../../core/auth/landing_redirect.dart';

class IndividualProviderShell extends ConsumerStatefulWidget {
  const IndividualProviderShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<IndividualProviderShell> createState() =>
      _IndividualProviderShellState();
}

class _IndividualProviderShellState
    extends ConsumerState<IndividualProviderShell> {
  late int _currentIndex;

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
    return Scaffold(
      backgroundColor: kOrgCanvas,
      appBar: AppBar(
        backgroundColor: kOrgSidebarLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: kOrgHairline, width: 1),
        ),
        title: Row(
          children: [
            const ScholarisLogo(
              badgeSize: 28,
              fontSize: 18,
              compact: true,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
            child: IndexedStack(
              index: _currentIndex,
              children: _tabs,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: kOrgSurfaceWhite,
        indicatorColor: kOrgPrimary.withValues(alpha: 0.12),
        elevation: 4,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined, color: kOrgTextMuted),
            selectedIcon:
                Icon(Icons.description_rounded, color: kOrgPrimary),
            label: 'Candidates',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined, color: kOrgTextMuted),
            selectedIcon: Icon(Icons.school_rounded, color: kOrgPrimary),
            label: 'My Grant',
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
