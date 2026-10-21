// lib/features/provider/providers/provider_verification_provider.dart
//
// Riverpod state management for Provider Verification & Admin inspection.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';

import '../data/provider_verification_repository.dart';
import '../models/provider_verification.dart';

final providerVerificationRepositoryProvider =
    Provider<ProviderVerificationRepository>((ref) {
  return ProviderVerificationRepository();
});

/// Watches the verification record for the currently signed-in user.
/// Reacts to [currentUserIdProvider] so auth transitions, sign-outs, and account switches
/// automatically invalidate and refetch state without converting failures into a "no user" state.
final currentUserVerificationProvider =
    FutureProvider<ProviderVerification?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final repo = ref.watch(providerVerificationRepositoryProvider);
  return repo.fetchVerificationForUser(userId);
});

/// StateNotifier/AsyncNotifier for Admin Verification management
final adminProviderVerificationsProvider = AsyncNotifierProvider<
    AdminProviderVerificationsNotifier, List<ProviderVerification>>(
  AdminProviderVerificationsNotifier.new,
);

class AdminProviderVerificationsNotifier
    extends AsyncNotifier<List<ProviderVerification>> {
  @override
  Future<List<ProviderVerification>> build() async {
    final repo = ref.watch(providerVerificationRepositoryProvider);
    return repo.fetchAllVerifications();
  }

  Future<void> approveVerification({
    required String userId,
    required String adminId,
    String? note,
  }) async {
    final repo = ref.read(providerVerificationRepositoryProvider);
    await repo.updateVerificationStatus(
      userId: userId,
      status: 'approved',
      adminId: adminId,
      reviewNote: note,
    );
    ref.invalidateSelf();
    ref.invalidate(currentUserVerificationProvider);
  }

  Future<void> rejectVerification({
    required String userId,
    required String adminId,
    required String note,
  }) async {
    final repo = ref.read(providerVerificationRepositoryProvider);
    await repo.updateVerificationStatus(
      userId: userId,
      status: 'rejected',
      adminId: adminId,
      reviewNote: note,
    );
    ref.invalidateSelf();
    ref.invalidate(currentUserVerificationProvider);
  }
}
