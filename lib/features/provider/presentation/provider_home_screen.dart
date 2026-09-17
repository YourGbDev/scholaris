// lib/features/provider/presentation/provider_home_screen.dart
//
// Persistent landing surface for signed-in users whose profiles.role is 'provider'.
// Hosts the Provider Console shell with tabs for Applications and My Scholarships.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';

import 'provider_incoming_applications.dart';
import 'provider_scholarships_tab.dart';

class ProviderTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) => state = index;
}

final providerTabIndexProvider =
    NotifierProvider<ProviderTabIndexNotifier, int>(
  ProviderTabIndexNotifier.new,
);

class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  static const _tabs = <Widget>[
    ProviderIncomingApplications(),
    ProviderScholarshipsTab(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(providerTabIndexProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Provider Console',
                      style: poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kNavyTrust,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'PROVIDER',
                        style: poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  tabIndex == 0 ? 'Applications Console' : 'Scholarship Portfolios',
                  style: openSans(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.black.withValues(alpha: 0.06),
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications.')),
              );
            },
          ),
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: kPrimarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Text(
              'DO',
              style: poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: kError),
            tooltip: 'Sign out',
            onPressed: () async {
              final confirmed = await showLogoutConfirmationDialog(context);
              if (confirmed) {
                try {
                  await Supabase.instance.client.auth.signOut();
                } catch (_) {}
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: tabIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: kPrimarySoft,
        onDestinationSelected: (i) =>
            ref.read(providerTabIndexProvider.notifier).selectTab(i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox_rounded, color: kPrimary),
            label: 'Applications',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded, color: kPrimary),
            label: 'Scholarships',
          ),
        ],
      ),
    );
  }
}
