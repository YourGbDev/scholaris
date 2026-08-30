// Provider tests for the Day 10 tracking filter.
//
// Covers the reactive status filter: default "All", selection/reset, the
// derived filtered list (preserving the repository's ordering), and the
// user-scoping guarantee that one user's filter can never carry into another
// user's session (the filter resets to "All" on every auth transition).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';

import 'helpers/fake_application_data_source.dart';

/// A controllable [AuthSessionNotifier]: starts signed out and lets the test
/// drive sign-in/sign-out like the real session boundary would.
class _TestAuthNotifier extends AuthSessionNotifier {
  @override
  AuthSession? build() => null;

  void signInAs(String userId) => state = AuthSession(userId: userId);
  void signOut() => state = null;
}

/// Wires the user-scoped repository and the auth session boundary together so
/// a session change propagates through the same dependency graph the real app
/// uses. [currentUser] is the "session" the repository believes is signed in.
class _Harness {
  _Harness() {
    auth = _TestAuthNotifier();
    applications = FakeApplicationDataSource();
    container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(() => auth),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(
            dataSource: applications,
            currentUserId: () => currentUser,
          ),
        ),
      ],
    );
    // Force the auth provider element to exist so the controllable notifier is
    // bound to it before any test drives sign-in/sign-out.
    container.read(authSessionProvider);
  }

  late final _TestAuthNotifier auth;
  late final FakeApplicationDataSource applications;
  late final ProviderContainer container;

  /// The user id the repository believes is signed in.
  String? currentUser;

  void signInAs(String userId) {
    currentUser = userId;
    auth.signInAs(userId);
  }

  void signOut() {
    currentUser = null;
    auth.signOut();
  }
}

Future<void> _seed(FakeApplicationDataSource source, String userId,
    List<Map<String, dynamic>> rows) async {
  for (final row in rows) {
    await source.insertApplication(userId, row);
  }
}

void main() {
  group('ApplicationFilterNotifier', () {
    test('defaults to All (null status)', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);

      final filter = h.container.read(applicationFilterProvider);
      expect(filter.status, isNull);
      expect(filter.isActive, isFalse);
    });

    test('select sets the status and isActive reflects it', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);

      h.container
          .read(applicationFilterProvider.notifier)
          .select(ApplicationStatus.approved);

      final filter = h.container.read(applicationFilterProvider);
      expect(filter.status, ApplicationStatus.approved);
      expect(filter.isActive, isTrue);
    });

    test('reset returns to All', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);

      final notifier = h.container.read(applicationFilterProvider.notifier);
      notifier.select(ApplicationStatus.rejected);
      notifier.reset();

      expect(h.container.read(applicationFilterProvider).status, isNull);
      expect(h.container.read(applicationFilterProvider).isActive, isFalse);
    });
  });

  group('filteredApplicationsProvider', () {
    test('All returns every application in the original order', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      h.signInAs('user-a');
      await _seed(h.applications, 'user-a', [
        {
          'user_id': 'user-a',
          'scholarship_id': 'sch-1',
          'status': 'submitted',
          'updated_at': '2026-08-10T00:00:00Z',
        },
        {
          'user_id': 'user-a',
          'scholarship_id': 'sch-2',
          'status': 'approved',
          'updated_at': '2026-08-09T00:00:00Z',
        },
        {
          'user_id': 'user-a',
          'scholarship_id': 'sch-3',
          'status': 'draft',
          'updated_at': '2026-08-08T00:00:00Z',
        },
      ]);

      await h.container.read(applicationsProvider.future);
      final filtered =
          h.container.read(filteredApplicationsProvider).value!;

      expect(filtered.map((a) => a.scholarshipId), ['sch-1', 'sch-2', 'sch-3']);
    });

    test('narrows to the selected status', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      h.signInAs('user-a');
      await _seed(h.applications, 'user-a', [
        {
          'user_id': 'user-a',
          'scholarship_id': 'sch-1',
          'status': 'submitted',
          'updated_at': '2026-08-10T00:00:00Z',
        },
        {
          'user_id': 'user-a',
          'scholarship_id': 'sch-2',
          'status': 'approved',
          'updated_at': '2026-08-09T00:00:00Z',
        },
        {
          'user_id': 'user-a',
          'scholarship_id': 'sch-3',
          'status': 'submitted',
          'updated_at': '2026-08-08T00:00:00Z',
        },
      ]);

      h.container
          .read(applicationFilterProvider.notifier)
          .select(ApplicationStatus.submitted);

      await h.container.read(applicationsProvider.future);
      final filtered =
          h.container.read(filteredApplicationsProvider).value!;

      expect(filtered.map((a) => a.scholarshipId), ['sch-1', 'sch-3']);
    });

    test('unmatched status yields an empty list', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      h.signInAs('user-a');
      await _seed(h.applications, 'user-a', [
        {
          'user_id': 'user-a',
          'scholarship_id': 'sch-1',
          'status': 'approved',
          'updated_at': '2026-08-10T00:00:00Z',
        },
      ]);

      h.container
          .read(applicationFilterProvider.notifier)
          .select(ApplicationStatus.underReview);

      await h.container.read(applicationsProvider.future);
      final filtered = h.container.read(filteredApplicationsProvider).value!;
      expect(filtered, isEmpty);
    });
  });

  group('user isolation', () {
    test('filter resets to All when a different user signs in', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);

      h.signInAs('user-a');
      await _seed(h.applications, 'user-a', [
        {
          'user_id': 'user-a',
          'scholarship_id': 'sch-1',
          'status': 'approved',
          'updated_at': '2026-08-10T00:00:00Z',
        },
      ]);

      // User A picks a filter.
      h.container
          .read(applicationFilterProvider.notifier)
          .select(ApplicationStatus.approved);
      expect(h.container.read(applicationFilterProvider).status,
          ApplicationStatus.approved);

      // Logout clears the filter back to All.
      h.signOut();
      await h.container.read(applicationsProvider.future);
      expect(h.container.read(applicationFilterProvider).status, isNull);

      // User B starts from All too — never inherits A's filter.
      await _seed(h.applications, 'user-b', [
        {
          'user_id': 'user-b',
          'scholarship_id': 'sch-b',
          'status': 'draft',
          'updated_at': '2026-08-11T00:00:00Z',
        },
      ]);
      h.signInAs('user-b');
      await h.container.read(applicationsProvider.future);
      expect(h.container.read(applicationFilterProvider).status, isNull);

      final filtered = h.container.read(filteredApplicationsProvider).value!;
      expect(filtered.map((a) => a.scholarshipId), ['sch-b']);
    });
  });
}