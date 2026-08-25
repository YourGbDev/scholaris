// lib/features/scholarships/providers/scholarships_provider.dart
//
// Data + derived-state providers for the scholarship discovery experience.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/providers/profile_setup_provider.dart';
import '../models/scholarship.dart';
import '../repositories/scholarship_repository.dart';
import '../services/matching_engine.dart';

final scholarshipRepositoryProvider = Provider<ScholarshipRepository>(
  (ref) => ScholarshipRepository(),
);

/// All active scholarships, ordered by soonest deadline.
final scholarshipsProvider = FutureProvider<List<Scholarship>>(
  (ref) => ref.watch(scholarshipRepositoryProvider).fetchActive(),
);

/// A single scholarship by id (used by the detail screen).
final scholarshipByIdProvider = FutureProvider.autoDispose
    .family<Scholarship?, String>((ref, id) async {
  final all = await ref.watch(scholarshipsProvider.future);
  for (final scholarship in all) {
    if (scholarship.id == id) return scholarship;
  }
  return null;
});

/// The personalized result — a ranked list of scholarships the signed-in
/// student is eligible for, produced by the deterministic [MatchingEngine].
final matchesProvider = FutureProvider.autoDispose<List<Scholarship>>(
  (ref) async {
    final profile = await ref.watch(currentProfileProvider.future);
    if (profile == null) return const [];
    final all = await ref.watch(scholarshipsProvider.future);
    return MatchingEngine().rank(
      MatchingEngine().getEligible(profile, all),
      profile,
    );
  },
);
