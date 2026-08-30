// Widget tests for the Day 11 application detail surface.
//
// Covers opening the detail from the tracking list, status rendering, editable
// notes (save + feedback), the withdrawal confirmation flow (cancel leaves the
// application unchanged, confirm withdraws), reactive count updates after a
// withdrawal, the path back to the scholarship detail, responsive 360px
// rendering, and the withdrawn filter on the tracking surface.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/presentation/application_detail_screen.dart';
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
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/features/scholarships/screens/saved_screen.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';

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
  String? notes,
  DateTime? appliedAt,
}) {
  return applications.insertApplication(userId, {
    'user_id': userId,
    'scholarship_id': scholarshipId,
    'status': status,
    'notes': notes,
    'applied_at': (appliedAt ?? DateTime(2026, 8, 27))
        .toUtc()
        .toIso8601String(),
  });
}

/// Wraps the Applications screen (standalone) with the user-scoped providers.
Widget _wrapApplications({
  required FakeApplicationDataSource applications,
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
        (ref) => ScholarshipRepository(dataSource: FakeScholarshipDataSource()),
      ),
    ],
    child: const MaterialApp(home: ApplicationsScreen()),
  );
}

/// Wraps the Applications tab embedded in the real Home shell (four tabs).
Widget _wrapHomeScreen({
  required FakeApplicationDataSource applications,
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
        (ref) => ScholarshipRepository(dataSource: FakeScholarshipDataSource()),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: applications,
          currentUserId: () => 'user-a',
        ),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Opening the application detail', () {
    testWidgets('tapping an application card opens the application detail',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');

      await tester.pumpWidget(_wrapApplications(applications: applications));
      await tester.pumpAndSettle();

      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      // The detail surface is present with application-specific content.
      expect(find.byType(ApplicationDetailScreen), findsOneWidget);
      expect(find.text('Application details'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Submitted'), findsWidgets);
    });

    testWidgets('application detail keeps a path back to the scholarship',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');

      await tester.pumpWidget(_wrapApplications(applications: applications));
      await tester.pumpAndSettle();

      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      // Tapping the scholarship header card opens the scholarship detail.
      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      expect(find.byType(ScholarshipDetailScreen), findsOneWidget);
      // The user has an application, so the applied state (not Apply now)
      // renders on the scholarship detail.
      expect(find.text('Application submitted'), findsOneWidget);
    });

    testWidgets('status renders correctly on the detail surface',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'under_review');

      await tester.pumpWidget(_wrapApplications(applications: applications));
      await tester.pumpAndSettle();

      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      expect(find.text('Under review'), findsWidgets);
      expect(find.byType(ApplicationStatusChip), findsOneWidget);
    });
  });

  group('Notes editing', () {
    testWidgets('existing notes are shown and can be saved', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost',
          status: 'submitted',
          notes: 'Statement of purpose attached.');

      await tester.pumpWidget(_wrapApplications(applications: applications));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      expect(find.text('Statement of purpose attached.'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('application-notes-field')),
          'Updated notes');
      await tester.tap(find.text('Save notes'));
      await tester.pumpAndSettle();

      expect(find.text('Notes saved.'), findsOneWidget);
      final rows = await applications.fetchApplications('user-a');
      expect(rows.single['notes'], 'Updated notes');
    });

    testWidgets('notes save does not modify the status', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');

      await tester.pumpWidget(_wrapApplications(applications: applications));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('application-notes-field')),
          'Just notes');
      await tester.tap(find.text('Save notes'));
      await tester.pumpAndSettle();

      final rows = await applications.fetchApplications('user-a');
      expect(rows.single['status'], 'submitted');
      expect(rows.single['notes'], 'Just notes');
      expect(find.text('Submitted'), findsWidgets);
    });

    testWidgets('saving empty notes clears the notes', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost',
          status: 'submitted',
          notes: 'Old note');

      await tester.pumpWidget(_wrapApplications(applications: applications));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('application-notes-field')), '');
      await tester.tap(find.text('Save notes'));
      await tester.pumpAndSettle();

      final rows = await applications.fetchApplications('user-a');
      expect(rows.single['notes'], '');
    });
  });

  group('Withdrawal confirmation', () {
    testWidgets('cancel leaves the application unchanged', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');

      await tester.pumpWidget(_wrapApplications(applications: applications));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('withdraw-action')));
      await tester.tap(find.byKey(const ValueKey('withdraw-action')));
      await tester.pumpAndSettle();

      expect(find.text('Withdraw application?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('withdraw-cancel')));
      await tester.pumpAndSettle();

      final rows = await applications.fetchApplications('user-a');
      expect(rows.single['status'], 'submitted');
      expect(find.text('Withdraw application?'), findsNothing);
      expect(find.text('Submitted'), findsWidgets);
    });

    testWidgets('confirm withdraws the application', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');

      await tester.pumpWidget(_wrapApplications(applications: applications));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('withdraw-action')));
      await tester.tap(find.byKey(const ValueKey('withdraw-action')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
      await tester.pumpAndSettle();

      final rows = await applications.fetchApplications('user-a');
      expect(rows.single['status'], 'withdrawn');
      expect(find.text('Application withdrawn.'), findsOneWidget);
      // The detail surface now reads withdrawn and drops the withdraw action.
      expect(find.text('Withdrawn'), findsWidgets);
      expect(find.byKey(const ValueKey('withdraw-action')), findsNothing);
    });

    testWidgets('withdrawn applications offer no withdraw action',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'withdrawn');

      await tester.pumpWidget(_wrapApplications(applications: applications));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      expect(find.text('Withdrawn'), findsWidgets);
      expect(find.byKey(const ValueKey('withdraw-action')), findsNothing);
      expect(find.textContaining('kept in your history'), findsOneWidget);
    });
  });

  group('Reactive updates after withdrawal', () {
    testWidgets('the tracking summary reflects the new withdrawn state',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'approved');

      await tester.pumpWidget(_wrapApplications(applications: applications));
      await tester.pumpAndSettle();

      // Before: 1 pending, 1 approved.
      expect(find.text('2 Total'), findsOneWidget);
      expect(find.text('1 Pending'), findsOneWidget);

      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('withdraw-action')));
      await tester.tap(find.byKey(const ValueKey('withdraw-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
      await tester.pumpAndSettle();

      // Back to the list — the summary updated reactively.
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('2 Total'), findsOneWidget);
      expect(find.text('0 Pending'), findsOneWidget);
      expect(find.text('1 Approved'), findsOneWidget);
      expect(find.text('Withdrawn (1)'), findsOneWidget);
    });

    testWidgets('the withdrawn filter surfaces withdrawn applications',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'withdrawn');
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-ched', status: 'approved');

      await tester.pumpWidget(_wrapHomeScreen(applications: applications));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Applications'));
      await tester.pumpAndSettle();

      expect(find.text('Withdrawn (1)'), findsOneWidget);
      await tester.ensureVisible(find.text('Withdrawn (1)'));
      await tester.tap(find.text('Withdrawn (1)'));
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsNothing);
      expect(find.byType(ApplicationStatusChip), findsOneWidget);
    });
  });

  group('Responsive rendering', () {
    testWidgets('application detail renders cleanly on a 360px screen',
        (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'under_review');

      await tester.pumpWidget(_wrapApplications(applications: applications));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('withdraw-action')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('withdraw-action')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Discover/Saved applied-state', () {
    testWidgets('a withdrawn application no longer reads as "Applied" on Saved',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'withdrawn');

      final profileSource = FakeProfileDataSource();
      profileSource.upsertProfile('user-a', _student().toDbRow());
      final bookmarks = FakeBookmarkDataSource();
      await bookmarks.addBookmark('user-a', 'sch-dost');

      await tester.pumpWidget(ProviderScope(
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
              dataSource: bookmarks,
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
              dataSource: applications,
              currentUserId: () => 'user-a',
            ),
          ),
        ],
        child: const MaterialApp(home: SavedScreen()),
      ));
      await tester.pumpAndSettle();

      // The saved card is present but must not show the "Applied" indicator.
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      final card = find.ancestor(
        of: find.text('DOST-SEI Undergraduate Scholarship'),
        matching: find.byType(ScholarshipCard),
      );
      expect(
        find.descendant(of: card, matching: find.text('Applied')),
        findsNothing,
      );
    });

    testWidgets('a pending application still reads as "Applied" on Discover',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final applications = FakeApplicationDataSource();
      await _seedApplication(applications, 'user-a',
          scholarshipId: 'sch-dost', status: 'submitted');

      final profileSource = FakeProfileDataSource();
      profileSource.upsertProfile('user-a', _student().toDbRow());

      await tester.pumpWidget(ProviderScope(
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
              dataSource: applications,
              currentUserId: () => 'user-a',
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 Applied'), findsOneWidget);
      final card = find.ancestor(
        of: find.text('DOST-SEI Undergraduate Scholarship'),
        matching: find.byType(ScholarshipCard),
      );
      expect(
        find.descendant(of: card, matching: find.text('Applied')),
        findsOneWidget,
      );
    });
  });
}
