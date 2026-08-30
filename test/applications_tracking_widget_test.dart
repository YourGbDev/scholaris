// Widget tests for the Day 10 tracking surface.
//
// Covers the new first-class Applications tab, the status filter bar with live
// per-status counts, the compact summary (total / pending / approved), filtered
// empty states, responsive narrow-screen rendering, and the user-scoping of
// both the filtered list and the filter choice itself. Existing Day 6 tracking
// behavior is preserved and verified by applications_screen_test.dart.

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
import 'package:scholaris/shared/utils/constants.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

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

Future<void> _seedApplication(
  FakeApplicationDataSource applications,
  String userId, {
  required String scholarshipId,
  required String status,
  String? updatedAt,
}) {
  return applications.insertApplication(userId, {
    'user_id': userId,
    'scholarship_id': scholarshipId,
    'status': status,
    'applied_at': '2026-08-27T00:00:00Z',
    'updated_at': ?updatedAt,
  });
}

/// Pumps the Applications screen (embedded as a tab body) with the user-scoped
/// providers backed by in-memory fakes.
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
    child: const MaterialApp(
      home: ApplicationsScreen(embedded: true),
    ),
  );
}

/// Wires the real HomeScreen shell (four tabs) with all feature providers,
/// mirroring the production dependency graph.
Widget _wrapHomeScreen({
  FakeApplicationDataSource? applications,
  FakeScholarshipDataSource? scholarships,
}) {
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
          dataSource: scholarships ?? FakeScholarshipDataSource(),
        ),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: applications ?? FakeApplicationDataSource(),
          currentUserId: () => 'user-a',
        ),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

/// A controllable [AuthSessionNotifier]: starts signed out and lets the test
/// drive sign-in/sign-out like the real session boundary would.
class _TestAuthNotifier extends AuthSessionNotifier {
  @override
  AuthSession? build() => null;

  void signInAs(String userId) => state = AuthSession(userId: userId);
  void signOut() => state = null;
}

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

  group('Applications tab navigation', () {
    testWidgets('Applications is a first-class Home tab', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrapHomeScreen());
      await tester.pumpAndSettle();

      // All four destinations are present.
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Applications'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Switching to the Applications tab surfaces the tracking surface.
      await tester.tap(find.text('Applications'));
      await tester.pumpAndSettle();

      expect(find.text('My Applications'), findsOneWidget);
      expect(find.text('No applications yet'), findsOneWidget);

      // Discover still works after switching back — IndexedStack preserved.
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();
      expect(find.text('Good to see you, Maria'), findsOneWidget);
    });

    testWidgets('Applications tab shows the filtered tracking surface',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'approved');

      await tester.pumpWidget(_wrapHomeScreen(applications: applications));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Applications'));
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsOneWidget);
      expect(find.text('All (2)'), findsOneWidget);
    });
  });

  group('Filter bar and counts', () {
    testWidgets('filter bar renders every status with live counts',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'approved');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'draft');

      await tester.pumpWidget(_wrap(applications: applications));
      await tester.pumpAndSettle();

      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Draft (1)'), findsOneWidget);
      expect(find.text('Submitted (1)'), findsOneWidget);
      expect(find.text('Under review (0)'), findsOneWidget);
      expect(find.text('Approved (1)'), findsOneWidget);
      expect(find.text('Rejected (0)'), findsOneWidget);
    });

    testWidgets('tapping a status chip narrows the list reactively',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'approved');

      await tester.pumpWidget(_wrap(applications: applications));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Approved (1)'));
      await tester.tap(find.text('Approved (1)'));
      await tester.pumpAndSettle();

      expect(find.text('CHED Merit Scholarship (MSRS)'), findsOneWidget);
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsNothing);

      // Back to All restores the full list.
      await tester.ensureVisible(find.text('All (2)'));
      await tester.tap(find.text('All (2)'));
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsOneWidget);
    });

    testWidgets('an unmatched status shows a filtered empty state',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'approved');

      await tester.pumpWidget(_wrap(applications: applications));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Submitted (0)'));
      await tester.tap(find.text('Submitted (0)'));
      await tester.pumpAndSettle();

      expect(find.text('No submitted applications'), findsOneWidget);
      expect(find.byType(ApplicationStatusChip), findsNothing);

      // "Show all applications" recovers the populated list.
      await tester.tap(find.text('Show all applications'));
      await tester.pumpAndSettle();
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
    });
  });

  group('Compact summary', () {
    testWidgets('summary shows total, pending and approved counts',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'under_review');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'approved');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'draft');

      await tester.pumpWidget(_wrap(applications: applications));
      await tester.pumpAndSettle();

      expect(find.text('4 Total'), findsOneWidget);
      expect(find.text('3 Pending'), findsOneWidget);
      expect(find.text('1 Approved'), findsOneWidget);
    });

    testWidgets('summary stays consistent while a filter is active',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'approved');

      await tester.pumpWidget(_wrap(applications: applications));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Approved (1)'));
      await tester.tap(find.text('Approved (1)'));
      await tester.pumpAndSettle();

      // Summary reflects the full list, not just the filtered slice.
      expect(find.text('2 Total'), findsOneWidget);
      expect(find.text('1 Pending'), findsOneWidget);
      expect(find.text('1 Approved'), findsOneWidget);
    });
  });

  group('Deadline labels', () {
    testWidgets('reuses the shared deadlineLabel formatting', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');

      await tester.pumpWidget(_wrap(applications: applications));
      await tester.pumpAndSettle();

      // The card derives its deadline chip from the shared deadlineLabel
      // helper (FakeScholarshipDataSource: sch-dost closes 2026-10-15).
      final expected = deadlineLabel(DateTime(2026, 10, 15));
      expect(find.text(expected), findsOneWidget);
    });
  });

  group('Responsive rendering', () {
    testWidgets('filter bar and summary render cleanly on a 360px screen',
        (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'approved');

      await tester.pumpWidget(_wrap(applications: applications));
      await tester.pumpAndSettle();

      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('2 Total'), findsOneWidget);
      expect(find.text('Submitted (1)'), findsOneWidget);
      expect(find.text('Approved (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('User isolation', () {
    testWidgets('a user only ever sees their own applications and counts',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(applications, 'user-b',
          scholarshipId: 'sch-ched', status: 'approved');

      await tester.pumpWidget(_wrap(applications: applications, userId: 'user-a'));
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsNothing);
      expect(find.text('All (1)'), findsOneWidget);
      expect(find.text('Approved (0)'), findsOneWidget);
    });

    testWidgets('a filter choice does not leak across user sessions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final h = _Harness();
      addTearDown(h.container.dispose);
      await _seedApplication(h.applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(h.applications, 'user-b',
          scholarshipId: 'sch-ched', status: 'approved');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: const MaterialApp(
            home: ApplicationsScreen(embedded: true),
          ),
        ),
      );

      // User A narrows to Submitted.
      h.signInAs('user-a');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submitted (1)'));
      await tester.pumpAndSettle();
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);

      // Logout clears the surface and resets the filter.
      h.signOut();
      await tester.pumpAndSettle();
      expect(find.text('No applications yet'), findsOneWidget);

      // User B starts from All — sees only B's approved application and never
      // inherits A's Submitted filter.
      h.signInAs('user-b');
      await tester.pumpAndSettle();
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsOneWidget);
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsNothing);
      expect(find.text('All (1)'), findsOneWidget);
    });
  });
}
