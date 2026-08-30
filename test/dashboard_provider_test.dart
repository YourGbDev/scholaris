// Day 9 — Deadline-Aware Dashboard providers.
//
// Unit tests for the pure derivation functions (closing-soon window, counts,
// deduplication) plus provider-level tests that compose the existing
// matches / catalog / bookmarks / applications providers with a fixed reference
// time so deadline math never depends on an uncontrolled DateTime.now().

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/dashboard_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

/// Fixed reference time so every deadline boundary is deterministic.
final DateTime _now = DateTime(2026, 1, 1);

DateTime _at(int days) => _now.add(Duration(days: days));

/// Deadlines in the future relative to the real clock so the MatchingEngine
/// (which filters on DateTime.now()) still accepts them in provider tests.
DateTime _inDays(int days) => DateTime.now().add(Duration(days: days));

Scholarship _s({
  required String id,
  required DateTime deadline,
  double amount = 50000,
}) =>
    Scholarship(
      id: id,
      name: id,
      minGpa: 2.0,
      yearLevels: const [1, 2, 3, 4, 5],
      eligibleCourses: const [],
      citizenshipRequired: 'any',
      regionsEligible: const [],
      maxIncomeBracket: 'any',
      isPwdPriority: false,
      isWorkingStudentPriority: false,
      slotsAvailable: null,
      deadline: deadline,
      amount: amount,
      coverageType: 'full',
      tags: const [],
      isActive: true,
    );

Application _app({
  required String id,
  required String scholarshipId,
  ApplicationStatus status = ApplicationStatus.submitted,
}) =>
    Application(
      id: id,
      userId: 'user-a',
      scholarshipId: scholarshipId,
      status: status,
      appliedAt: _now,
    );

/// A controllable [AuthSessionNotifier]: starts signed out and lets the test
/// drive sign-in/sign-out like the real session boundary would.
class _TestAuthNotifier extends AuthSessionNotifier {
  @override
  AuthSession? build() => null;

  void signInAs(String userId) => state = AuthSession(userId: userId);
  void signOut() => state = null;
}

StudentProfile _student() => StudentProfile(
      id: 'user-a',
      fullName: 'Maria Santos',
      nationality: 'Filipino',
      region: 'NCR',
      gpa: 3.2,
      yearLevel: 2,
      course: 'BS Computer Science',
      monthlyFamilyIncome: 15000,
      setupComplete: true,
    );

List<Map<String, dynamic>> _rows() => [
      {
        'id': 'sch-dost',
        'name': 'DOST-SEI Scholarship',
        'min_gpa': 2.0,
        'year_levels': [1, 2, 3, 4, 5],
        'eligible_courses': <String>[],
        'citizenship_required': 'Filipino',
        'regions_eligible': <String>[],
        'max_income_bracket': 'any',
        'is_pwd_priority': false,
        'is_working_student_priority': false,
        'slots_available': 8000,
        'deadline': _inDays(10).toIso8601String().split('T').first,
        'amount': 70000,
        'coverage_type': 'full',
        'tags': const ['stem'],
        'is_active': true,
      },
      {
        'id': 'sch-barmm',
        'name': 'BARMM Study Grant',
        'min_gpa': 2.0,
        'year_levels': [1, 2, 3, 4, 5],
        'eligible_courses': <String>[],
        'citizenship_required': 'any',
        'regions_eligible': ['BARMM'],
        'max_income_bracket': 'any',
        'is_pwd_priority': false,
        'is_working_student_priority': false,
        'slots_available': 200,
        'deadline': _inDays(6).toIso8601String().split('T').first,
        'amount': 40000,
        'coverage_type': 'full',
        'tags': const ['community'],
        'is_active': true,
      },
    ];

ProviderContainer _container({
  FakeBookmarkDataSource? bookmarks,
  FakeApplicationDataSource? applications,
}) {
  final profileSource = FakeProfileDataSource();
  profileSource.upsertProfile('user-a', _student().toDbRow());

  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-a'),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: profileSource,
          currentUserId: () => 'user-a',
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) => ScholarshipRepository(
          dataSource: FakeScholarshipDataSource(_rows()),
        ),
      ),
      bookmarkRepositoryProvider.overrideWith(
        (ref) => BookmarkRepository(
          dataSource: bookmarks ?? FakeBookmarkDataSource(),
          currentUserId: () => 'user-a',
        ),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: applications ?? FakeApplicationDataSource(),
          currentUserId: () => 'user-a',
        ),
      ),
    ],
  );
}

void main() {
  group('closingSoonScholarships', () {
    test('includes the boundary day (exactly 14 days out)', () {
      final soon = closingSoonScholarships(
        [_s(id: 'day14', deadline: _at(14))],
        now: _now,
      );
      expect(soon.map((s) => s.id), ['day14']);
    });

    test('excludes a scholarship 15 days out', () {
      final soon = closingSoonScholarships(
        [_s(id: 'day15', deadline: _at(15))],
        now: _now,
      );
      expect(soon, isEmpty);
    });

    test('includes a scholarship closing today', () {
      final soon = closingSoonScholarships(
        [_s(id: 'today', deadline: _now)],
        now: _now,
      );
      expect(soon.map((s) => s.id), ['today']);
    });

    test('excludes an already-closed scholarship', () {
      final soon = closingSoonScholarships(
        [_s(id: 'closed', deadline: _at(-1))],
        now: _now,
      );
      expect(soon, isEmpty);
    });

    test('sorts by soonest deadline, higher amount breaks ties', () {
      final soon = closingSoonScholarships(
        [
          _s(id: 'late', deadline: _at(10), amount: 90000),
          _s(id: 'soonSmall', deadline: _at(3), amount: 10000),
          _s(id: 'soonBig', deadline: _at(3), amount: 80000),
        ],
        now: _now,
      );
      expect(soon.map((s) => s.id), ['soonBig', 'soonSmall', 'late']);
    });

    test('returns empty for an empty catalog', () {
      expect(closingSoonScholarships(const [], now: _now), isEmpty);
    });
  });

  group('buildDashboardInfo', () {
    final match1 = _s(id: 'match1', deadline: _at(5));
    final match2 = _s(id: 'match2', deadline: _at(30));
    final browseSoon = _s(id: 'browseSoon', deadline: _at(3));
    final browseFar = _s(id: 'browseFar', deadline: _at(60));
    final catalog = [match1, match2, browseSoon, browseFar];

    test('counts matches, saved, applied and pending correctly', () {
      final info = buildDashboardInfo(
        matches: [match1, match2],
        catalog: catalog,
        bookmarkIds: {'match1', 'browseFar'},
        applications: [
          _app(id: 'a1', scholarshipId: 'match1', status: ApplicationStatus.submitted),
          _app(id: 'a2', scholarshipId: 'browseFar', status: ApplicationStatus.approved),
          _app(id: 'a3', scholarshipId: 'x', status: ApplicationStatus.rejected),
          _app(id: 'a4', scholarshipId: 'y', status: ApplicationStatus.draft),
        ],
        now: _now,
      );

      expect(info.matchCount, 2);
      expect(info.savedCount, 2);
      expect(info.appliedCount, 4);
      // submitted + draft are pending; approved/rejected are terminal.
      expect(info.pendingApplicationCount, 2);
    });

    test('withdrawn applications are not pending on the dashboard', () {
      final info = buildDashboardInfo(
        matches: const [],
        catalog: const [],
        bookmarkIds: const {},
        applications: [
          _app(id: 'a1', scholarshipId: 'x', status: ApplicationStatus.draft),
          _app(id: 'a2', scholarshipId: 'y', status: ApplicationStatus.submitted),
          _app(id: 'a3', scholarshipId: 'z', status: ApplicationStatus.underReview),
          _app(id: 'a4', scholarshipId: 'q', status: ApplicationStatus.withdrawn),
          _app(id: 'a5', scholarshipId: 'w', status: ApplicationStatus.approved),
          _app(id: 'a6', scholarshipId: 'e', status: ApplicationStatus.rejected),
        ],
        now: _now,
      );

      // The dashboard pending count agrees with the Applications surface:
      // withdrawn is terminal and excluded.
      expect(info.appliedCount, 6);
      expect(info.pendingApplicationCount, 3);
    });

    test('does not double-count a scholarship that is both a match and in the '
        'catalog', () {
      final info = buildDashboardInfo(
        matches: [match1, match2],
        catalog: catalog,
        bookmarkIds: const {},
        applications: const [],
        now: _now,
      );

      // match1 (5 days) is closing soon but is a match — it must not be
      // re-surfaced in the closing-soon list; only the browse remainder is.
      expect(info.closingSoonCount, 1);
      expect(info.closingSoonScholarships.map((s) => s.id), ['browseSoon']);
    });

    test('empty dashboard surfaces no matches, saved or applied', () {
      final info = buildDashboardInfo(
        matches: const [],
        catalog: const [],
        bookmarkIds: const {},
        applications: const [],
        now: _now,
      );

      expect(info.matchCount, 0);
      expect(info.closingSoonCount, 0);
      expect(info.closingSoonScholarships, isEmpty);
      expect(info.savedCount, 0);
      expect(info.appliedCount, 0);
      expect(info.pendingApplicationCount, 0);
    });

    test('closing soon count is empty when nothing closes in the window', () {
      final info = buildDashboardInfo(
        matches: const [],
        catalog: [_s(id: 'far', deadline: _at(60))],
        bookmarkIds: const {},
        applications: const [],
        now: _now,
      );
      expect(info.closingSoonCount, 0);
      expect(info.closingSoonScholarships, isEmpty);
    });
  });

  group('dashboardProvider', () {
    test('composes the signed-in user dashboard from existing providers',
        () async {
      final bookmarks = FakeBookmarkDataSource();
      await bookmarks.addBookmark('user-a', 'sch-dost');
      final applications = FakeApplicationDataSource();
      await applications.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': 'sch-dost',
        'status': 'submitted',
      });

      final container = _container(bookmarks: bookmarks, applications: applications);
      addTearDown(container.dispose);

      final info = await container.read(dashboardProvider.future);

      // DOST is the only match (BARMM is region-restricted to BARMM).
      expect(info.matchCount, 1);
      // BARMM is the browse remainder and closes in 6 days → closing soon.
      expect(info.closingSoonCount, 1);
      expect(info.closingSoonScholarships.map((s) => s.id), ['sch-barmm']);
      expect(info.savedCount, 1);
      expect(info.appliedCount, 1);
      expect(info.pendingApplicationCount, 1);
    });

    test('reflects bookmarks and applications reactively', () async {
      final bookmarks = FakeBookmarkDataSource();
      final applications = FakeApplicationDataSource();
      final container =
          _container(bookmarks: bookmarks, applications: applications);
      addTearDown(container.dispose);

      await container.read(dashboardProvider.future);

      await container.read(bookmarksProvider.notifier).toggle('sch-dost');
      await container.read(applicationsProvider.notifier).apply('sch-dost');

      final info = await container.read(dashboardProvider.future);
      expect(info.savedCount, 1);
      expect(info.appliedCount, 1);
    });

    test('default state has zero saved and applied counts', () async {
      final container = _container();
      addTearDown(container.dispose);

      final info = await container.read(dashboardProvider.future);
      expect(info.matchCount, 1);
      expect(info.savedCount, 0);
      expect(info.appliedCount, 0);
    });

    test('is scoped to the signed-in user and clears on sign-out', () async {
      final auth = _TestAuthNotifier();
      final bookmarks = FakeBookmarkDataSource();
      final applications = FakeApplicationDataSource();
      String? currentUser;

      // user-b's data must never leak into the dashboard of anyone else.
      await bookmarks.addBookmark('user-b', 'sch-dost');
      await applications.insertApplication('user-b', {
        'user_id': 'user-b',
        'scholarship_id': 'sch-dost',
        'status': 'submitted',
      });

      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(() => auth),
          profileRepositoryProvider.overrideWith(
            (ref) => ProfileRepository(
              dataSource: FakeProfileDataSource(),
              currentUserId: () => currentUser,
            ),
          ),
          scholarshipRepositoryProvider.overrideWith(
            (ref) => ScholarshipRepository(
              dataSource: FakeScholarshipDataSource(_rows()),
            ),
          ),
          bookmarkRepositoryProvider.overrideWith(
            (ref) => BookmarkRepository(
              dataSource: bookmarks,
              currentUserId: () => currentUser,
            ),
          ),
          applicationRepositoryProvider.overrideWith(
            (ref) => ApplicationRepository(
              dataSource: applications,
              currentUserId: () => currentUser,
            ),
          ),
        ],
      );
      // Force the auth provider element to exist so the controllable notifier
      // is bound before any test drives sign-in/sign-out.
      container.read(authSessionProvider);
      addTearDown(container.dispose);

      // Signed out → no saved / applied counts.
      var info = await container.read(dashboardProvider.future);
      expect(info.savedCount, 0);
      expect(info.appliedCount, 0);

      // user-b signs in → only user-b's own saved / applied appear.
      currentUser = 'user-b';
      auth.signInAs('user-b');
      info = await container.read(dashboardProvider.future);
      expect(info.savedCount, 1);
      expect(info.appliedCount, 1);

      // Sign out clears the dashboard again.
      currentUser = null;
      auth.signOut();
      info = await container.read(dashboardProvider.future);
      expect(info.savedCount, 0);
      expect(info.appliedCount, 0);
    });
  });
}
