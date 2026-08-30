// lib/features/applications/services/application_filters.dart
//
// Pure, client-side application tracking pipeline: status filter → counts →
// summary. Modeled after DiscoveryFilters so the tracking surface can narrow
// the signed-in user's applications to a single status while keeping the
// per-status counts (and a compact total/pending/approved summary) always in
// sync. Every function here is deterministic and unit-testable; filtering
// preserves the repository's default ordering (updated_at descending) — it
// never reorders, it only narrows.

import '../models/application.dart';

/// Sentinel distinguishing "leave unchanged" from "set to null" in copyWith.
class _Unset {
  const _Unset();
}

const _Unset _unset = _Unset();

/// Immutable snapshot of the tracking filter. Backed by the Riverpod notifier;
/// never mutated in place.
class ApplicationFilterState {
  const ApplicationFilterState({this.status});

  /// The single selected status, or null for "All".
  final ApplicationStatus? status;

  /// True when a non-default status filter is active.
  bool get isActive => status != null;

  ApplicationFilterState copyWith({Object? status = _unset}) {
    return ApplicationFilterState(
      status: identical(status, _unset) ? this.status : status as ApplicationStatus?,
    );
  }

  ApplicationFilterState reset() => const ApplicationFilterState();
}

class ApplicationFilters {
  const ApplicationFilters._();

  // --- Filtering ------------------------------------------------------------

  /// True when [application] matches the selected [status]; null (All) always
  /// matches.
  static bool matchesStatus(Application application, ApplicationStatus? status) =>
      status == null || application.status == status;

  /// Narrow the list to a single status (null = All). Order is preserved —
  /// this is a pure narrowing step and never re-sorts.
  static List<Application> filterByStatus(
    List<Application> applications,
    ApplicationStatus? status,
  ) {
    return applications.where((a) => matchesStatus(a, status)).toList();
  }

  // --- Counts ---------------------------------------------------------------

  /// Per-status counts across the full list. Every supported status is present
  /// (zero when absent) so the filter chips render consistent labels.
  static Map<ApplicationStatus, int> statusCounts(
    List<Application> applications,
  ) {
    final counts = <ApplicationStatus, int>{};
    for (final status in ApplicationStatus.values) {
      counts[status] = 0;
    }
    for (final application in applications) {
      counts[application.status] = counts[application.status]! + 1;
    }
    return counts;
  }

  /// Count of applications matching [status]; null (All) returns the total.
  static int countByStatus(
    List<Application> applications,
    ApplicationStatus? status,
  ) {
    if (status == null) return applications.length;
    return applications.where((a) => a.status == status).length;
  }

  /// Applications still in flight. The single authoritative definition of
  /// "pending" is [ApplicationStatus.isPending] — draft, submitted or under
  /// review. Terminal statuses (approved, rejected, withdrawn) are excluded.
  /// This is the one definition the Applications surface, the dashboard and
  /// every count must agree on.
  static int pendingCount(List<Application> applications) =>
      applications.where((a) => a.status.isPending).length;

  /// Applications that have been approved.
  static int approvedCount(List<Application> applications) =>
      applications.where((a) => a.status == ApplicationStatus.approved).length;

  /// Whether [application] still counts as an active application for its
  /// scholarship. A withdrawn application is a preserved historical record but
  /// no longer an active "Applied" state on Discover/Saved.
  static bool isActive(Application application) =>
      application.status != ApplicationStatus.withdrawn;

  /// The scholarship ids with at least one active (non-withdrawn) application.
  /// This drives the "Applied" indicator on Discover/Saved so a withdrawn
  /// application stops reading as "applied".
  static Set<String> activeAppliedScholarshipIds(
    List<Application> applications,
  ) =>
      applications.where(isActive).map((a) => a.scholarshipId).toSet();

  // --- Combined pipeline ----------------------------------------------------

  /// Filter → count in one pass. The default (null status) is a no-op that
  /// returns the list untouched, preserving the existing updated_at-descending
  /// order established by the repository.
  static List<Application> applyAll(
    List<Application> applications,
    ApplicationStatus? status,
  ) =>
      filterByStatus(applications, status);
}
