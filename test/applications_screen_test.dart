// Widget tests for the Day 6 Applications Tracking UI.
//
// Covers the entry point (Profile tab), the populated list with status chips,
// empty / loading / error+retry states, status rendering for every supported
// status, authenticated-user isolation, logout/login transitions, responsive
// narrow-screen rendering, and that the existing three-tab navigation contract
// is preserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/presentation/application_status_chip.dart';
import 'package:scholaris/features/applications/presentation/applications_screen.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

/// A controllable [AuthSessionNotifier]: starts signed out and lets the test
/// drive sign-in/sign-out like the real session boundary would.
class _TestAuthNotifier extends AuthSessionNotifier {
  @override
  AuthSession? build() => null;

  void signInAs(String userId) => state = AuthSession(userId: userId);
  void signOut() => state = null;
}

/// Application data source whose first fetch blocks on a test-controlled gate,
/// so the tracking screen's loading state can be observed mid-flight.
class _SlowApplicationDataSource extends FakeApplicationDataSource {
  final Completer<void> gate = Completer<void>();

  @override
  Future<List<Map<String, dynamic>>> fetchApplications(String userId) async {
    await gate.future;
    return super.fetchApplications(userId);
  }
}

/// Application data source that fails every fetch, so the error state can be
/// exercised without a network.
class _FailingApplicationDataSource extends FakeApplicationDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchApplications(String userId) async {
    throw Exception('fetch failed');
  }
}

/// Application data source that fails the first fetch then succeeds, so the
/// retry path can be verified to recover.
class _FlakyApplicationDataSource extends FakeApplicationDataSource {
  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchApplications(String userId) async {
    calls++;
    if (calls == 1) throw Exception('network down');
    return super.fetchApplications(userId);
  }
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

/// Wires a single application for [userId] into [applications].
Future<void> _seedApplication(
  FakeApplicationDataSource applications,
  String userId, {
  required String scholarshipId,
  required String status,
  DateTime? appliedAt,
}) {
  return applications.insertApplication(userId, {
    'user_id': userId,
    'scholarship_id': scholarshipId,
    'status': status,
    'applied_at': (appliedAt ?? DateTime(2026, 8, 27))
        .toUtc()
        .toIso8601String(),
  });
}

/// Pumps the Applications screen with the user-scoped providers backed by
/// in-memory fakes. [userId] null renders the signed-out state.
Widget _wrap({
  required FakeApplicationDataSource applications,
  FakeScholarshipDataSource? scholarships,
  String? userId = 'user-a',
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: applications,
          currentUserId: () => userId,
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) => ScholarshipRepository(
          dataSource: scholarships ?? FakeScholarshipDataSource(),
        ),
      ),
    ],
    child: const MaterialApp(home: ApplicationsScreen()),
  );
}

/// Wires the real HomeScreen shell (three tabs) with all feature providers,
/// mirroring the production dependency graph. Used by the entry-point and
/// three-tab navigation tests.
Widget _wrapHomeScreen() {
  final profileSource = FakeProfileDataSource();
  profileSource.upsertProfile('user-a', _student().toDbRow());

  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-a'),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: profileSource,
          currentUserId: () => 'user-a',
        ),
      ),
      bookmarkRepositoryProvider.overrideWith(
        (ref) => BookmarkRepository(
          dataSource: FakeBookmarkDataSource(),
          currentUserId: () => 'user-a',
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) => ScholarshipRepository(
          dataSource: FakeScholarshipDataSource(),
        ),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: FakeApplicationDataSource(),
          currentUserId: () => 'user-a',
        ),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

/// Wires a controllable auth session together with the user-scoped
/// repositories so a session change propagates through the same dependency
/// graph the real app uses.
class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(() => auth),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(
            dataSource: applications,
            currentUserId: () => currentUser,
          ),
        ),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(dataSource: scholarships),
        ),
      ],
    );
    // Force the auth provider element to exist so the controllable notifier is
    // bound to it before any test drives sign-in/sign-out.
    container.read(authSessionProvider);
  }

  final _TestAuthNotifier auth = _TestAuthNotifier();
  final FakeApplicationDataSource applications = FakeApplicationDataSource();
  final FakeScholarshipDataSource scholarships = FakeScholarshipDataSource();

  late final ProviderContainer container;

  /// The user id the repositories believe is signed in.
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

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Entry point from Profile tab', () {
    testWidgets('Profile tab exposes a My Applications entry', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrapHomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('My Applications'), findsOneWidget);
    });

    testWidgets('tapping My Applications opens the tracking screen',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrapHomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Applications'));
      await tester.pumpAndSettle();

      // The pushed screen's AppBar shows the title and its body shows the
      // tracking surface (empty state here).
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('My Applications'),
        ),
        findsOneWidget,
      );
      expect(find.text('No applications yet'), findsOneWidget);
    });

    testWidgets('the three-tab navigation contract remains intact',
        (tester) async {
      await tester.pumpWidget(_wrapHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing saved yet'), findsOneWidget);
    });
  });

  group('Applications list', () {
    testWidgets('populated list shows scholarship info and status chips',
        (tester) async {
      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'approved');

      await tester.pumpWidget(_wrap(applications: applications));
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsOneWidget);
      expect(find.text('₱70,000'), findsOneWidget);
      expect(find.text('₱50,000'), findsOneWidget);
      expect(find.byType(ApplicationStatusChip), findsNWidgets(2));
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
    });

    testWidgets('empty state renders when the user has no applications',
        (tester) async {
      await tester.pumpWidget(
        _wrap(applications: FakeApplicationDataSource()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No applications yet'), findsOneWidget);
      expect(find.byType(ApplicationStatusChip), findsNothing);
    });

    testWidgets('loading state renders while applications are in flight',
        (tester) async {
      final slow = _SlowApplicationDataSource();
      await _seedApplication(slow, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');

      await tester.pumpWidget(_wrap(applications: slow));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No applications yet'), findsNothing);

      slow.gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
    });

    testWidgets('error state surfaces with a retry path', (tester) async {
      await tester.pumpWidget(
        _wrap(applications: _FailingApplicationDataSource()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('retry recovers from a failed load', (tester) async {
      final flaky = _FlakyApplicationDataSource();
      await _seedApplication(flaky, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');

      await tester.pumpWidget(_wrap(applications: flaky));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });
  });

  group('Status rendering', () {
    testWidgets('every supported status renders its chip label',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'draft');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'submitted');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'under_review');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'approved');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'rejected');

      await tester.pumpWidget(_wrap(applications: applications));
      await tester.pumpAndSettle();

      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    });
  });

  group('Authenticated user isolation', () {
    testWidgets('a user only ever sees their own applications',
        (tester) async {
      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(applications, 'user-b',
          scholarshipId: 'sch-ched', status: 'submitted');

      await tester.pumpWidget(_wrap(applications: applications, userId: 'user-a'));
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsNothing);
    });

    testWidgets('logout then login as another user shows only that user apps',
        (tester) async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await _seedApplication(h.applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(h.applications, 'user-b',
          scholarshipId: 'sch-ched', status: 'approved');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: const MaterialApp(home: ApplicationsScreen()),
        ),
      );

      // User A sees A's application.
      h.signInAs('user-a');
      await tester.pumpAndSettle();
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);

      // Logout clears the surface.
      h.signOut();
      await tester.pumpAndSettle();
      expect(find.text('No applications yet'), findsOneWidget);

      // User B sees only B's application — never A's.
      h.signInAs('user-b');
      await tester.pumpAndSettle();
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsOneWidget);
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsNothing);
    });
  });

  group('Responsive rendering', () {
    testWidgets('populated list renders cleanly on a narrow screen',
        (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'under_review');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'approved');

      await tester.pumpWidget(_wrap(applications: applications));
      await tester.pumpAndSettle();

      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
