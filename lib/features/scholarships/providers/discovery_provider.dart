// lib/features/scholarships/providers/discovery_provider.dart
//
// Reactive discovery state: the immutable [DiscoveryFilterState] notifier plus
// derived providers that narrow the existing match/browse results. Filtering is
// display-level narrowing only — it never changes MatchingEngine eligibility.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../profile/providers/profile_setup_provider.dart';
import '../models/scholarship.dart';
import '../services/application_readiness.dart';
import '../services/discovery_filters.dart';
import '../services/match_reasons.dart';
import 'scholarships_provider.dart';

/// The single discovery search/filter/sort state. Auto-disposed and keyed on
/// the authenticated user so one user's filters can never leak into another
/// user's session.
final discoveryFilterProvider =
    NotifierProvider.autoDispose<DiscoveryFilterNotifier, DiscoveryFilterState>(
  DiscoveryFilterNotifier.new,
);

class DiscoveryFilterNotifier extends AutoDisposeNotifier<DiscoveryFilterState> {
  @override
  DiscoveryFilterState build() {
    // Reset whenever the authenticated user changes (including sign-out).
    ref.watch(currentUserIdProvider);
    return const DiscoveryFilterState();
  }

  void setQuery(String value) => state = state.copyWith(query: value);

  void setIncomeBracket(String? value) =>
      state = state.copyWith(incomeBracket: value);

  void toggleRegion(String region) {
    final regions = {...state.regions};
    if (!regions.add(region)) {
      regions.remove(region);
    }
    state = state.copyWith(regions: regions);
  }

  void setClosingSoonOnly(bool value) =>
      state = state.copyWith(closingSoonOnly: value);

  void setHighFitOnly(bool value) =>
      state = state.copyWith(highFitOnly: value);

  void setMinAmount(double? value) =>
      state = state.copyWith(minAmount: value);

  void setSort(DiscoverySort value) => state = state.copyWith(sort: value);

  void reset() => state = const DiscoveryFilterState();
}

/// Number of active discovery filters (used for the filter-button badge).
final discoveryActiveFilterCountProvider = Provider<int>((ref) {
  final s = ref.watch(discoveryFilterProvider);
  var count = 0;
  if (s.query.trim().isNotEmpty) count++;
  if (s.incomeBracket != null) count++;
  count += s.regions.length;
  if (s.closingSoonOnly) count++;
  if (s.highFitOnly) count++;
  if (s.minAmount != null) count++;
  return count;
});

/// Personalized matches narrowed by the active discovery state. The default
/// sort preserves MatchingEngine's ranked order.
final filteredMatchesProvider = Provider<AsyncValue<List<Scholarship>>>((ref) {
  final matchesAsync = ref.watch(matchesProvider);
  final state = ref.watch(discoveryFilterProvider);
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  return matchesAsync.whenData(
    (matches) => DiscoveryFilters.applyAll(matches, state, isHighFit: (s) =>
      profile != null && evaluateApplicationReadiness(profile: profile, scholarship: s, referenceNow: DateTime.now()).canApply &&
      placeholderMatchPercentage(matchReasonsFor(profile, s).length) > 90),
  );
});

/// Full active catalog, deduplicated from the personalized matches, then
/// narrowed by the same discovery state.
final filteredBrowseProvider = Provider<AsyncValue<List<Scholarship>>>((ref) {
  final allAsync = ref.watch(scholarshipsProvider);
  final matchesAsync = ref.watch(matchesProvider);
  final state = ref.watch(discoveryFilterProvider);
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  final matchIds = (matchesAsync.valueOrNull ?? const <Scholarship>[])
      .map((s) => s.id)
      .toSet();
  return allAsync.whenData(
    (all) => DiscoveryFilters.applyAll(
      all.where((s) => !matchIds.contains(s.id)).toList(),
      state,
      isHighFit: (s) => profile != null &&
        evaluateApplicationReadiness(profile: profile, scholarship: s, referenceNow: DateTime.now()).canApply &&
        placeholderMatchPercentage(matchReasonsFor(profile, s).length) > 90,
    ),
  );
});
