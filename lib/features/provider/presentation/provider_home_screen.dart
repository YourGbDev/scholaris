// lib/features/provider/presentation/provider_home_screen.dart
//
// Landing surface for role='provider' users. Dynamically routes between:
// - OrgProviderShell: Institutional desktop-first provider console
// - IndividualProviderShell: Mobile-first personal benefactor portal
//
// Governed by `activeProviderTypeProvider` (backed by Supabase profiles.provider_type).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/provider_type_provider.dart';
import 'individual/individual_provider_shell.dart';
import 'org/org_provider_shell.dart';

class ProviderHomeScreen extends ConsumerWidget {
  final int initialTab;
  final bool autoOpenDrawer;
  const ProviderHomeScreen({
    super.key,
    this.initialTab = 0,
    this.autoOpenDrawer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerType = ref.watch(activeProviderTypeProvider);

    if (providerType == 'individual') {
      return const IndividualProviderShell();
    }

    return OrgProviderShell(
      initialTab: initialTab,
      autoOpenDrawer: autoOpenDrawer,
    );
  }
}
