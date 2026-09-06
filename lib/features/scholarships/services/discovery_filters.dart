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
  /// Soonest deadline first.
  defaultSort,

  /// Soonest deadline first (amount sort removed; no amount field in schema).
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
    this.closingSoonOnly = false,
    this.sort = DiscoverySort.defaultSort,
  });

  /// Free-text search applied to title/provider/description/courses/location.
  final String query;

  /// Selected income bracket ('low' | 'mid' | 'high'), or null for any.
  final String? incomeBracket;

  /// Selected regions (OR). Empty means any region.
  final Set<String> regions;

  /// Restrict to scholarships closing within 14 days.
  final bool closingSoonOnly;

  final DiscoverySort sort;

  /// True when any search/filter control deviates from the default.
  bool get isActive =>
      query.trim().isNotEmpty ||
      incomeBracket != null ||
      regions.isNotEmpty ||
      closingSoonOnly;

  DiscoveryFilterState copyWith({
    String? query,
    Object? incomeBracket = _unset,
    Set<String>? regions,
    bool? closingSoonOnly,
    DiscoverySort? sort,
  }) {
    return DiscoveryFilterState(
      query: query ?? this.query,
      incomeBracket: identical(incomeBracket, _unset)
          ? this.incomeBracket
          : incomeBracket as String?,
      regions: regions ?? this.regions,
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
      s.title,
      s.provider ?? '',
      s.description ?? '',
      s.requiredCourses?.join(' ') ?? '',
      s.locationRestriction ?? '',
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

  /// Maps the selected income bracket to a numeric threshold. A scholarship
  /// passes when its max_monthly_income is null (no restriction) or >= the
  /// student's income threshold.
  static const _incomeThresholds = <String, double>{
    'low': 15000,
    'mid': 25000,
    'high': 60000,
  };

  static bool _matchesIncome(Scholarship s, String? selected) {
    if (selected == null) return true;
    final threshold = _incomeThresholds[selected];
    if (threshold == null) return true;
    if (s.maxMonthlyIncome == null) return true;
    return s.maxMonthlyIncome! >= threshold;
  }

  /// Selected regions use OR semantics; an unrestricted scholarship (null
  /// location_restriction) remains eligible for any region.
  static bool _matchesRegions(Scholarship s, Set<String> selected) {
    if (selected.isEmpty) return true;
    if (s.locationRestriction == null) return true;
    return selected.contains(s.locationRestriction);
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
        return a.deadline.compareTo(b.deadline);
      case DiscoverySort.highestAmount:
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
  /// matches in MatchingEngine's order (soonest deadline).
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

  /// Distinct values across the active catalog. Never hardcoded — the options
  /// grow/shrink with the data.
  static Set<String> availableRegions(List<Scholarship> catalog) {
    final regions = <String>{};
    for (final s in catalog) {
      if (s.locationRestriction != null) {
        regions.add(s.locationRestriction!);
      }
    }
    return regions;
  }
}
