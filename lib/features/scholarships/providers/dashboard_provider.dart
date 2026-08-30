// lib/features/scholarships/providers/dashboard_provider.dart
//
// Derived, read-only dashboard state for the Discover home surface. It composes
// the existing matches / catalog / bookmarks / applications providers into the
// compact "at a glance" summary (match, closing-soon, saved, applied counts)
// plus the deadline-urgent closing-soon list.
//
// No database access: every input already flows through the existing providers.
// Deadline math is deterministic — the reference time can be injected via
// [dashboardReferenceNowProvider] so tests never depend on an uncontrolled
// DateTime.now().

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../applications/models/application.dart';
import '../../applications/providers/applications_provider.dart';
import '../../bookmarks/providers/bookmarks_provider.dart';
import '../../../shared/utils/constants.dart';
import '../models/scholarship.dart';
import 'scholarships_provider.dart';

/// The derived counts + closing-soon list that power the Discover dashboard.
class DashboardInfo {
  const DashboardInfo({
    required this.matchCount,
    required this.closingSoonCount,
    required this.savedCount,
    required this.appliedCount,
    required this.pendingApplicationCount,
    required this.closingSoonScholarships,
  });

  /// Number of personalized matches for the signed-in student.
  final int matchCount;

  /// Number of scholarships surfaced in the closing-soon section.
  final int closingSoonCount;

  /// Number of scholarships the signed-in student has saved.
  final int savedCount;

  /// Number of applications the signed-in student has submitted.
  final int appliedCount;

  /// Applications still in flight (draft / submitted / under review).
  final int pendingApplicationCount;

  /// Deadline-urgent scholarships, soonest first. Already deduplicated against
  /// the personalized matches (see [buildDashboardInfo]).
  final List<Scholarship> closingSoonScholarships;
}

/// Injectable reference time used for deadline math. Defaults to the current
/// time; tests override this to keep closing-soon calculations deterministic.
final dashboardReferenceNowProvider = Provider<DateTime>(
  (ref) => DateTime.now(),
);

/// Scholarships in [catalog] that close within the same "closing soon" window
/// the discovery filter uses ([isClosingSoon]) and are still open (deadline not
/// yet passed), sorted by soonest deadline with a higher amount breaking ties.
/// Deterministic and unit-testable.
List<Scholarship> closingSoonScholarships(
  List<Scholarship> catalog, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final soon = catalog
      .where((s) => isClosingSoon(s.deadline.difference(reference).inDays))
      .where((s) => !s.deadline.isBefore(reference))
      .toList()
    ..sort((a, b) {
      final deadlineCmp = a.deadline.compareTo(b.deadline);
      if (deadlineCmp != 0) return deadlineCmp;
      return b.amount.compareTo(a.amount);
    });
  return soon;
}

/// Pure derivation of the dashboard summary from existing provider state.
///
/// The closing-soon surface is built from the browse remainder (catalog minus
/// the personalized matches) — the exact deduplication semantics Day 8
/// established for the browse section. A scholarship that is both a match and
/// part of the catalog therefore appears exactly once on the dashboard, and it
/// is never shown twice on the same screen (the matches section already
/// surfaces it with its urgency chip).
DashboardInfo buildDashboardInfo({
  required List<Scholarship> matches,
  required List<Scholarship> catalog,
  required Set<String> bookmarkIds,
  required List<Application> applications,
  required DateTime now,
}) {
  final matchIds = matches.map((s) => s.id).toSet();
  final browse = catalog.where((s) => !matchIds.contains(s.id)).toList();
  final closingSoon = closingSoonScholarships(browse, now: now);

  return DashboardInfo(
    matchCount: matches.length,
    closingSoonCount: closingSoon.length,
    savedCount: bookmarkIds.length,
    appliedCount: applications.length,
    pendingApplicationCount: applications
        .where((a) =>
            a.status != ApplicationStatus.approved &&
            a.status != ApplicationStatus.rejected)
        .length,
    closingSoonScholarships: closingSoon,
  );
}

/// The Discover dashboard, composed from the existing matches / catalog /
/// bookmarks / applications providers. Bound to the authenticated user through
/// those providers, so it can never leak another user's state. When a
/// dependency fails to load the dashboard surfaces nothing rather than showing
/// misleading zero counts.
final dashboardProvider = FutureProvider<DashboardInfo>((ref) async {
  final matches = await ref.watch(matchesProvider.future);
  final catalog = await ref.watch(scholarshipsProvider.future);
  final bookmarkIds = await ref.watch(bookmarksProvider.future);
  final applications = await ref.watch(applicationsProvider.future);
  final now = ref.watch(dashboardReferenceNowProvider);

  return buildDashboardInfo(
    matches: matches,
    catalog: catalog,
    bookmarkIds: bookmarkIds,
    applications: applications,
    now: now,
  );
});
