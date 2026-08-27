// lib/features/applications/providers/applications_provider.dart
//
// Reactive applications state: [applicationsProvider] holds the signed-in
// user's own scholarship applications and exposes [apply] / [updateStatus] for
// the Apply flow and future Applications screen to call.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../models/application.dart';
import '../repositories/application_repository.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>(
  (ref) => ApplicationRepository(),
);

final applicationsProvider =
    AsyncNotifierProvider<ApplicationsNotifier, List<Application>>(
  ApplicationsNotifier.new,
);

class ApplicationsNotifier extends AsyncNotifier<List<Application>> {
  @override
  Future<List<Application>> build() async {
    // Bound to the authenticated user: rebuilt (and refetched) on every auth
    // transition, so a previous user's applications can never leak to the next.
    ref.watch(currentUserIdProvider);
    return ref.watch(applicationRepositoryProvider).fetchMyApplications();
  }

  /// Whether the signed-in user already applied to [scholarshipId]. False when
  /// signed out or the provider has not loaded yet.
  bool hasApplied(String scholarshipId) =>
      (state.valueOrNull ?? const <Application>[])
          .any((application) => application.scholarshipId == scholarshipId);

  /// Submits an application for [scholarshipId]. On success the created
  /// application is appended to the state. Throws
  /// [ApplicationNotAuthenticatedException] when signed out and
  /// [ApplicationDuplicateException] when the user already applied.
  Future<Application> apply(String scholarshipId, {String? notes}) async {
    final created = await ref
        .read(applicationRepositoryProvider)
        .apply(scholarshipId: scholarshipId, notes: notes);
    state = AsyncData([
      ...state.valueOrNull ?? const <Application>[],
      created,
    ]);
    return created;
  }

  /// Advances the status of one of the signed-in user's own applications,
  /// keeping the local state in sync.
  Future<void> updateStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    await ref
        .read(applicationRepositoryProvider)
        .updateStatus(applicationId, status);
    state = AsyncData([
      for (final application in state.valueOrNull ?? const <Application>[])
        if (application.id == applicationId)
          application.copyWith(status: status)
        else
          application,
    ]);
  }
}
