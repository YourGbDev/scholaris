// lib/features/applications/providers/applications_provider.dart
//
// Reactive applications state: [applicationsProvider] holds the signed-in
// user's own scholarship applications and exposes [apply] / [updateStatus] for
// the Apply flow and Applications screen to call. [applicationFilterProvider]
// holds the tracking surface's status filter and
// [filteredApplicationsProvider] derives the narrowed list from it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/controllers/auth_controller.dart';
import '../models/application.dart';
import '../repositories/application_repository.dart';
import '../services/application_filters.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>(
  (ref) => ApplicationRepository(),
);

/// Watches the disbursement record for [applicationId].
/// Re-evaluates whenever [applicationRepositoryProvider] changes or when invalidated.
final applicationDisbursementProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, applicationId) async {
      return ref
          .watch(applicationRepositoryProvider)
          .getDisbursement(applicationId);
    });

final endorsedEvaluationProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, id) async {
      ref.watch(currentUserIdProvider);
      return Supabase.instance.client
          .from('application_evaluations')
          .select()
          .eq('application_id', id)
          .eq('decision', 'endorsed')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    });

final applicationsProvider =
    AsyncNotifierProvider<ApplicationsNotifier, List<Application>>(
      ApplicationsNotifier.new,
    );

class ApplicationsNotifier extends AsyncNotifier<List<Application>> {
  int _generation = 0;
  @override
  Future<List<Application>> build() async {
    _generation++;
    ref.onDispose(() => _generation++);
    // Bound to the authenticated user: rebuilt (and refetched) on every auth
    // transition, so a previous user's applications can never leak to the next.
    ref.watch(currentUserIdProvider);
    return ref.watch(applicationRepositoryProvider).fetchMyApplications();
  }

  /// Whether the signed-in user already applied to [scholarshipId]. False when
  /// signed out or the provider has not loaded yet.
  bool hasApplied(String scholarshipId) =>
      (state.valueOrNull ?? const <Application>[]).any(
        (application) => application.scholarshipId == scholarshipId,
      );

  /// Returns the existing application for [scholarshipId] if one exists.
  Application? applicationFor(String scholarshipId) =>
      (state.valueOrNull ?? const <Application>[])
          .where((application) => application.scholarshipId == scholarshipId)
          .firstOrNull;

  /// Submits an application for [scholarshipId]. On success the created or
  /// updated application is stored in the state. Throws
  /// [ApplicationNotAuthenticatedException] when signed out and
  /// [ApplicationDuplicateException] when the user already applied.
  Future<Application> apply(String scholarshipId, {String? notes}) async {
    final generation = _generation;
    final user = ref.read(currentUserIdProvider);
    final created = await ref
        .read(applicationRepositoryProvider)
        .apply(scholarshipId: scholarshipId, notes: notes);
    if (generation != _generation || user != ref.read(currentUserIdProvider)) {
      return created;
    }
    final currentList = state.valueOrNull ?? const <Application>[];
    final existsIndex = currentList.indexWhere((app) => app.id == created.id);
    if (existsIndex >= 0) {
      state = AsyncData([
        for (int i = 0; i < currentList.length; i++)
          if (i == existsIndex) created else currentList[i],
      ]);
    } else {
      state = AsyncData([...currentList, created]);
    }
    return created;
  }

  /// Saves an application as a draft for [scholarshipId].
  Future<Application> saveDraft(String scholarshipId, {String? notes}) async {
    final generation = _generation;
    final user = ref.read(currentUserIdProvider);
    final draft = await ref
        .read(applicationRepositoryProvider)
        .saveDraft(scholarshipId: scholarshipId, notes: notes);
    if (generation != _generation || user != ref.read(currentUserIdProvider)) return draft;
    final currentList = state.valueOrNull ?? const <Application>[];
    final existsIndex = currentList.indexWhere((app) => app.id == draft.id);
    if (existsIndex >= 0) {
      state = AsyncData([
        for (int i = 0; i < currentList.length; i++)
          if (i == existsIndex) draft else currentList[i],
      ]);
    } else {
      state = AsyncData([...currentList, draft]);
    }
    return draft;
  }

  /// Advances the status of one of the signed-in user's own applications,
  /// keeping the local state in sync.
  Future<void> updateStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    final generation = _generation;
    final user = ref.read(currentUserIdProvider);
    await ref
        .read(applicationRepositoryProvider)
        .updateStatus(applicationId, status);
    if (generation != _generation || user != ref.read(currentUserIdProvider)) {
      return;
    }
    state = AsyncData([
      for (final application in state.valueOrNull ?? const <Application>[])
        if (application.id == applicationId)
          application.copyWith(status: status)
        else
          application,
    ]);
  }

  /// Withdraws one of the signed-in user's own applications, keeping the local
  /// state in sync. The application is preserved (not deleted).
  Future<void> withdraw(String applicationId) async {
    final generation = _generation;
    final user = ref.read(currentUserIdProvider);
    await ref.read(applicationRepositoryProvider).withdraw(applicationId);
    if (generation != _generation || user != ref.read(currentUserIdProvider)) {
      return;
    }
    state = AsyncData([
      for (final application in state.valueOrNull ?? const <Application>[])
        if (application.id == applicationId)
          application.copyWith(status: ApplicationStatus.withdrawn)
        else
          application,
    ]);
  }

  /// Updates the notes of one of the signed-in user's own applications,
  /// keeping the local state in sync.
  Future<void> updateNotes(String applicationId, String notes) async {
    final generation = _generation;
    final user = ref.read(currentUserIdProvider);
    await ref
        .read(applicationRepositoryProvider)
        .updateNotes(applicationId, notes);
    if (generation != _generation || user != ref.read(currentUserIdProvider)) {
      return;
    }
    state = AsyncData([
      for (final application in state.valueOrNull ?? const <Application>[])
        if (application.id == applicationId)
          application.copyWith(notes: notes)
        else
          application,
    ]);
  }
}

/// The single status filter for the tracking surface. Auto-disposed and keyed
/// on the authenticated user so one user's filter choice can never leak into
/// another user's session (the same boundary DiscoveryFilters uses).
final applicationFilterProvider =
    NotifierProvider.autoDispose<
      ApplicationFilterNotifier,
      ApplicationFilterState
    >(ApplicationFilterNotifier.new);

class ApplicationFilterNotifier
    extends AutoDisposeNotifier<ApplicationFilterState> {
  @override
  ApplicationFilterState build() {
    // Reset to "All" whenever the authenticated user changes (including
    // sign-out), so a previous user's filter never carries into the next.
    ref.watch(currentUserIdProvider);
    return const ApplicationFilterState();
  }

  void select(ApplicationStatus? status) =>
      state = ApplicationFilterState(status: status);

  void reset() => state = const ApplicationFilterState();
}

/// The signed-in user's applications narrowed by the active status filter,
/// preserving the repository's default updated_at-descending ordering.
final filteredApplicationsProvider = Provider<AsyncValue<List<Application>>>((
  ref,
) {
  final applicationsAsync = ref.watch(applicationsProvider);
  final filter = ref.watch(applicationFilterProvider);
  return applicationsAsync.whenData(
    (applications) => ApplicationFilters.applyAll(applications, filter.status),
  );
});

/// Applications submitted to scholarships the signed-in provider owns
/// (those whose `scholarships.created_by` equals the current user id).
///
/// Read-only and user-scoped: bound to [currentUserIdProvider] so it refetches
/// on every auth transition and a previous provider's queue can never leak to
/// the next session. Mirrors [applicationsProvider]'s session-derived-id guard:
/// signed-out users get an empty list, never another provider's data.
final incomingApplicationsProvider =
    AsyncNotifierProvider<IncomingApplicationsNotifier, List<Application>>(
      IncomingApplicationsNotifier.new,
    );

class IncomingApplicationsNotifier extends AsyncNotifier<List<Application>> {
  @override
  Future<List<Application>> build() async {
    ref.watch(currentUserIdProvider);
    return ref.watch(applicationRepositoryProvider).fetchIncomingApplications();
  }

  /// Refreshes the provider queue (e.g. after a provider acts on an
  /// application). Mirrors [ApplicationsNotifier] retry ergonomics.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
