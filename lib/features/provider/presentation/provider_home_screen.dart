// lib/features/provider/presentation/provider_home_screen.dart
//
// Persistent landing surface for signed-in users whose profiles.role is 'provider'.
// Hosts the Provider Console shell with tabs for Applications and My Scholarships.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/shared/theme/app_theme.dart';

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
        title: Text(
          'Provider Console',
          style: poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: kPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: kError),
            tooltip: 'Sign out',
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
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
