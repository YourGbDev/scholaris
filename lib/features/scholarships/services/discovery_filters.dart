// lib/features/scholarships/services/discovery_filters.dart
//
// Pure, client-side discovery pipeline: search → filters → sort. Applied on top
// of the existing match/browse results as a display-level narrowing step. It
// never recomputes scholarship eligibility — that stays the sole responsibility
// of MatchingEngine. Every function here is deterministic and unit-testable.

import '../../../shared/utils/constants.dart';
import '../models/scholarship.dart';

/// Sort modes available for discovery results.
enum DiscoverySort {
  /// Soonest deadline first; a higher amount breaks ties.
  defaultSort,

  /// Highest amount first; the soonest deadline breaks ties.
  highestAmount,
}

/// Sentinel distinguishing "leave unchanged" from "set to null" in copyWith.
class _Unset {
  const _Unset();
}

const _Unset _unset = _Unset();

/// Immutable snapshot of every discovery control. Backed by the Riverpod
/// notifier; never mutated in place.
class DiscoveryFilterState {
  const DiscoveryFilterState({
    this.query = '',
    this.incomeBracket,
    this.regions = const <String>{},
    this.coverageTypes = const <String>{},
    this.tags = const <String>{},
    this.minAmount,
    this.maxAmount,
    this.closingSoonOnly = false,
    this.sort = DiscoverySort.defaultSort,
  });

  /// Free-text search applied to name/provider/description/tags/courses/regions.
  final String query;

  /// Selected income bracket ('low' | 'mid' | 'high'), or null for any.
  final String? incomeBracket;

  /// Selected eligible regions (OR). Empty means any region.
  final Set<String> regions;

  /// Selected coverage types (OR). Empty means any coverage.
  final Set<String> coverageTypes;

  /// Selected tags (OR). Empty means any tag.
  final Set<String> tags;

  /// Inclusive lower amount bound; null = unset.
  final double? minAmount;

  /// Inclusive upper amount bound; null = unset.
  final double? maxAmount;

  /// Restrict to scholarships closing within 14 days.
  final bool closingSoonOnly;

  final DiscoverySort sort;

  /// True when any search/filter control deviates from the default.
  bool get isActive =>
      query.trim().isNotEmpty ||
      incomeBracket != null ||
      regions.isNotEmpty ||
      coverageTypes.isNotEmpty ||
      tags.isNotEmpty ||
      minAmount != null ||
      maxAmount != null ||
      closingSoonOnly;

  DiscoveryFilterState copyWith({
    String? query,
    Object? incomeBracket = _unset,
    Set<String>? regions,
    Set<String>? coverageTypes,
    Set<String>? tags,
    Object? minAmount = _unset,
    Object? maxAmount = _unset,
    bool? closingSoonOnly,
    DiscoverySort? sort,
  }) {
    return DiscoveryFilterState(
      query: query ?? this.query,
      incomeBracket: identical(incomeBracket, _unset)
          ? this.incomeBracket
          : incomeBracket as String?,
      regions: regions ?? this.regions,
      coverageTypes: coverageTypes ?? this.coverageTypes,
      tags: tags ?? this.tags,
      minAmount:
          identical(minAmount, _unset) ? this.minAmount : minAmount as double?,
      maxAmount:
          identical(maxAmount, _unset) ? this.maxAmount : maxAmount as double?,
      closingSoonOnly: closingSoonOnly ?? this.closingSoonOnly,
      sort: sort ?? this.sort,
    );
  }

  DiscoveryFilterState reset() => const DiscoveryFilterState();
}

class DiscoveryFilters {
  const DiscoveryFilters._();

  // --- Search ---------------------------------------------------------------

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static List<String> _tokens(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return const [];
    return normalized.split(' ');
  }

  /// True when every whitespace-token of [query] appears as a case-insensitive
  /// substring of one of the scholarship's searchable fields.
  static bool matchesQuery(Scholarship s, String query) {
    final tokens = _tokens(query);
    if (tokens.isEmpty) return true;

    final haystack = _normalize([
      s.name,
      s.provider ?? '',
      s.description ?? '',
      s.tags.join(' '),
      s.eligibleCourses.join(' '),
      s.regionsEligible.join(' '),
    ].join(' '));

    return tokens.every(haystack.contains);
  }

  /// Empty / whitespace-only query is a no-op.
  static List<Scholarship> applySearch(List<Scholarship> items, String query) {
    if (_tokens(query).isEmpty) return List.of(items);
    return items.where((s) => matchesQuery(s, query)).toList();
  }

  // --- Filters --------------------------------------------------------------

  static bool matchesFilters(
    Scholarship s,
    DiscoveryFilterState state, {
    DateTime? now,
  }) {
    if (!_matchesIncome(s, state.incomeBracket)) return false;
    if (!_matchesRegions(s, state.regions)) return false;
    if (!_matchesCoverage(s, state.coverageTypes)) return false;
    if (!_matchesTags(s, state.tags)) return false;
    if (!_matchesAmount(s, state.minAmount, state.maxAmount)) return false;
    if (!_matchesDeadline(s, state.closingSoonOnly, now: now)) return false;
    return true;
  }

  static List<Scholarship> applyFilters(
    List<Scholarship> items,
    DiscoveryFilterState state, {
    DateTime? now,
  }) {
    return items.where((s) => matchesFilters(s, state, now: now)).toList();
  }

  /// Preserves the income hierarchy: low → low/mid/high/any, mid → mid/high/any,
  /// high → high/any. Mirrors MatchingEngine's ceiling semantics.
  static bool _matchesIncome(Scholarship s, String? selected) {
    if (selected == null || selected == 'any') return true;
    const hierarchy = ['low', 'mid', 'high'];
    final selectedIndex = hierarchy.indexOf(selected);
    if (selectedIndex == -1) return true;
    if (s.maxIncomeBracket == 'any') return true;
    final maxIndex = hierarchy.indexOf(s.maxIncomeBracket);
    if (maxIndex == -1) return false;
    return maxIndex >= selectedIndex;
  }

  /// Selected regions use OR semantics; an unrestricted scholarship (empty
  /// regionsEligible) remains eligible for any region.
  static bool _matchesRegions(Scholarship s, Set<String> selected) {
    if (selected.isEmpty) return true;
    if (s.regionsEligible.isEmpty) return true;
    return s.regionsEligible.any(selected.contains);
  }

  static bool _matchesCoverage(Scholarship s, Set<String> selected) {
    if (selected.isEmpty) return true;
    final coverage = s.coverageType;
    return coverage != null && selected.contains(coverage);
  }

  static bool _matchesTags(Scholarship s, Set<String> selected) {
    if (selected.isEmpty) return true;
    return s.tags.any(selected.contains);
  }

  /// Inclusive boundaries. When min > max the range is invalid and treated as
  /// unset (no amount filtering).
  static bool _matchesAmount(Scholarship s, double? min, double? max) {
    if (min != null && max != null && min > max) return true;
    if (min != null && s.amount < min) return false;
    if (max != null && s.amount > max) return false;
    return true;
  }

  static bool _matchesDeadline(
    Scholarship s,
    bool closingSoonOnly, {
    DateTime? now,
  }) {
    if (!closingSoonOnly) return true;
    final days = s.deadline.difference(now ?? DateTime.now()).inDays;
    return isClosingSoon(days);
  }

  /// Parses an optional numeric amount. Empty, non-numeric, negative or NaN
  /// input returns null so the amount filter is treated as unset.
  static double? parseAmount(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed.isNaN || parsed < 0) return null;
    return parsed;
  }

  // --- Sort -----------------------------------------------------------------

  static int compare(Scholarship a, Scholarship b, DiscoverySort sort) {
    switch (sort) {
      case DiscoverySort.defaultSort:
        final deadlineCmp = a.deadline.compareTo(b.deadline);
        if (deadlineCmp != 0) return deadlineCmp;
        return b.amount.compareTo(a.amount);
      case DiscoverySort.highestAmount:
        final amountCmp = b.amount.compareTo(a.amount);
        if (amountCmp != 0) return amountCmp;
        return a.deadline.compareTo(b.deadline);
    }
  }

  static List<Scholarship> sort(List<Scholarship> items, DiscoverySort sort) {
    final sorted = List.of(items);
    sorted.sort((a, b) => compare(a, b, sort));
    return sorted;
  }

  // --- Combined pipeline ----------------------------------------------------

  /// Search → filters → sort in one pass. The default sort keeps personalized
  /// matches in MatchingEngine's order (soonest deadline, then higher amount).
  static List<Scholarship> applyAll(
    List<Scholarship> items,
    DiscoveryFilterState state, {
    DateTime? now,
  }) {
    return sort(
      applyFilters(applySearch(items, state.query), state, now: now),
      state.sort,
    );
  }

  // --- Catalog-derived ------------------------------------------------------

  /// Distinct tags across the active catalog. Never hardcoded — the options
  /// grow/shrink with the data.
  static Set<String> availableTags(List<Scholarship> catalog) {
    final tags = <String>{};
    for (final s in catalog) {
      tags.addAll(s.tags);
    }
    return tags;
  }
}
