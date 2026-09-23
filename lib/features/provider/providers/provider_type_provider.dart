// lib/features/provider/providers/provider_type_provider.dart
//
// Manages the distinction between Individual Providers and Organization Providers
// (backed by Supabase column profiles.provider_type added in migration 0012).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../profile/providers/profile_setup_provider.dart';

/// Fetches the live `provider_type` column from `public.profiles` for the current user.
/// Returns 'organization' or 'individual' (defaults to 'organization').
final currentProviderTypeProvider = FutureProvider<String>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 'organization';

  try {
    final client = Supabase.instance.client;
    final row = await client
        .from('profiles')
        .select('provider_type')
        .eq('id', userId)
        .maybeSingle();
    final type = row?['provider_type'] as String?;
    if (type == 'individual' || type == 'organization') {
      return type!;
    }
  } catch (_) {
    // Fallback if offline, mock or column empty
  }
  return 'organization';
});

/// Optional runtime override so evaluators/testers can toggle between
/// Org Console (Desktop/Institutional) and Individual Provider (Mobile/Benefactor)
/// without having to re-seed the Supabase database.
final providerTypeOverrideProvider = StateProvider<String?>((ref) => null);

/// Resolved provider type ('organization' or 'individual').
final activeProviderTypeProvider = Provider<String>((ref) {
  final override = ref.watch(providerTypeOverrideProvider);
  if (override != null) return override;
  return ref.watch(currentProviderTypeProvider).valueOrNull ?? 'organization';
});

/// Helper to persist a provider type change to Supabase.
Future<void> setProviderType(WidgetRef ref, String newType) async {
  final userId = ref.read(currentUserIdProvider);
  ref.read(providerTypeOverrideProvider.notifier).state = newType;

  if (userId != null) {
    try {
      final client = Supabase.instance.client;
      await client.from('profiles').update({'provider_type': newType}).eq('id', userId);
      ref.invalidate(currentProviderTypeProvider);
      ref.invalidate(currentProfileProvider);
    } catch (_) {}
  }
}
