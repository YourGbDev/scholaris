// lib/features/provider/providers/provider_scholarships_provider.dart
//
// Provider-scoped state management for scholarship listings.
// Supports full CRUD: create, edit, toggle active/closed, and delete.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../applications/providers/applications_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/models/student_profile.dart';
import '../../profile/providers/profile_setup_provider.dart';
import '../../scholarships/models/scholarship.dart';
import '../../scholarships/providers/scholarships_provider.dart';

final providerScholarshipStatusFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all'); // 'all', 'active', 'closed'

final providerScholarshipSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// All scholarships owned by the currently signed-in provider.
/// Bound to [currentUserIdProvider] so session transitions automatically refetch.
final providerScholarshipsProvider =
    AsyncNotifierProvider<ProviderScholarshipsNotifier, List<Scholarship>>(
  ProviderScholarshipsNotifier.new,
);

class ProviderScholarshipsNotifier extends AsyncNotifier<List<Scholarship>> {
  @override
  Future<List<Scholarship>> build() async {
    final providerId = ref.watch(currentUserIdProvider);
    if (providerId == null) return const [];
    return ref.watch(scholarshipRepositoryProvider).fetchByProvider(providerId);
  }

  /// Reload provider's scholarships.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Creates a new scholarship listing and invalidates student catalog.
  Future<Scholarship> createScholarship(Map<String, dynamic> data) async {
    final providerId = ref.read(currentUserIdProvider);
    if (providerId == null) {
      throw StateError('Cannot create scholarship without signed-in provider.');
    }

    final payload = Map<String, dynamic>.of(data);
    payload['created_by'] = providerId;

    final created = await ref
        .read(scholarshipRepositoryProvider)
        .createScholarship(payload);

    // Invalidate student discovery catalog so new scholarship surfaces immediately
    ref.invalidate(scholarshipsProvider);
    ref.invalidateSelf();
    await future;
    return created;
  }

  /// Updates an existing scholarship listing and invalidates student catalog.
  Future<Scholarship> updateScholarship(
    String id,
    Map<String, dynamic> data,
  ) async {
    final updated = await ref
        .read(scholarshipRepositoryProvider)
        .updateScholarship(id, data);

    ref.invalidate(scholarshipsProvider);
    ref.invalidate(scholarshipByIdProvider(id));
    ref.invalidateSelf();
    await future;
    return updated;
  }

  /// Toggles active status (Active / Closed).
  Future<void> toggleActive(String id, bool isActive) async {
    await ref.read(scholarshipRepositoryProvider).toggleActive(id, isActive);

    ref.invalidate(scholarshipsProvider);
    ref.invalidate(scholarshipByIdProvider(id));
    ref.invalidateSelf();
    await future;
  }

  /// Deletes a scholarship listing.
  Future<void> deleteScholarship(String id) async {
    await ref.read(scholarshipRepositoryProvider).deleteScholarship(id);

    ref.invalidate(scholarshipsProvider);
    ref.invalidate(scholarshipByIdProvider(id));
    ref.invalidateSelf();
    await future;
  }
}

/// Filtered provider scholarships based on status and search query.
final filteredProviderScholarshipsProvider =
    Provider.autoDispose<AsyncValue<List<Scholarship>>>((ref) {
  final scholarshipsAsync = ref.watch(providerScholarshipsProvider);
  final statusFilter = ref.watch(providerScholarshipStatusFilterProvider);
  final query = ref.watch(providerScholarshipSearchQueryProvider).trim().toLowerCase();

  return scholarshipsAsync.whenData((list) {
    return list.where((s) {
      // 1. Status filter
      if (statusFilter == 'active' && !s.isActive) return false;
      if (statusFilter == 'closed' && s.isActive) return false;

      // 2. Search query filter
      if (query.isNotEmpty) {
        final matchTitle = s.title.toLowerCase().contains(query);
        final matchDesc = s.description?.toLowerCase().contains(query) ?? false;
        final matchProvider = s.provider?.toLowerCase().contains(query) ?? false;
        if (!matchTitle && !matchDesc && !matchProvider) return false;
      }

      return true;
    }).toList();
  });
});

/// Fetches student profiles for all applicant userIds present in incoming applications.
final providerApplicantProfilesProvider =
    FutureProvider<Map<String, StudentProfile>>((ref) async {
  final apps = await ref.watch(incomingApplicationsProvider.future);
  final userIds = apps.map((a) => a.userId).toSet();
  if (userIds.isEmpty) return {};
  final profileRepo = ref.watch(profileRepositoryProvider);
  final results = await Future.wait(
    userIds.map((id) => profileRepo.fetchProfileById(id)),
  );
  final map = <String, StudentProfile>{};
  for (final profile in results) {
    if (profile != null) {
      map[profile.id] = profile;
    }
  }

  // Gracefully fallback to student metadata in application notes if database RLS
  // isolates the profiles table
  for (final app in apps) {
    if (!map.containsKey(app.userId) && app.notes != null && app.notes!.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(app.notes!) as Map<String, dynamic>;
        map[app.userId] = StudentProfile(
          id: app.userId,
          fullName: decoded['full_name'] as String? ?? '',
          school: decoded['school'] as String?,
          course: decoded['course'] as String? ?? '',
          gpa: (decoded['gpa'] as num?)?.toDouble() ?? 1.5,
          yearLevel: (decoded['year_level'] as num?)?.toInt() ?? 1,
          region: decoded['region'] as String? ?? 'NCR',
          monthlyFamilyIncome: (decoded['monthly_family_income'] as num?)?.toDouble(),
        );
      } catch (_) {}
    }
  }

  return map;
});
