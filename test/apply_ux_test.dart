// Widget tests for the Apply UX: the Apply action on the scholarship detail
// screen drives the existing applications provider/repository through the
// Day 15 safe-apply flow — readiness gating (closed/inactive/ineligible/
// incomplete profile cannot apply), a pre-apply confirmation whose Cancel
// never writes and whose Confirm goes through the existing apply path, and
// the preserved success/applied state, loading/disabled behavior, duplicate
// prevention, failure surfacing, unauthenticated safety, and bookmark +
// responsive/detail behavior.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

/// Application data source whose inserts block on a test-controlled gate, so
/// the apply button's loading/disabled state can be observed mid-flight.
class _SlowApplicationDataSource extends FakeApplicationDataSource {
  final Completer<void> gate = Completer<void>();

  @override
  Future<Map<String, dynamic>> insertApplication(
    String userId,
    Map<String, dynamic> row,
  ) async {
    await gate.future;
    return super.insertApplication(userId, row);
  }
}

/// Application data source that fails every insert, so application failures
/// can be surfaced and asserted without a network.
class _FailingApplicationDataSource extends FakeApplicationDataSource {
  @override
  Future<Map<String, dynamic>> insertApplication(
    String userId,
    Map<String, dynamic> row,
  ) async {
    throw Exception('insert failed');
  }
}

StudentProfile _student({
  double gpa = 3.2,
  bool setupComplete = true,
  double? monthlyFamilyIncome = 15000,
}) =>
    StudentProfile(
      id: 'user-a',
      fullName: 'Maria Santos',
      nationality: 'Filipino',
      region: 'NCR',
      gpa: gpa,
      yearLevel: 2,
      course: 'BS Computer Science',
      monthlyFamilyIncome: monthlyFamilyIncome,
      setupComplete: setupComplete,
    );

Scholarship _scholarship() =>
    Scholarship.fromJson(FakeScholarshipDataSource.defaultRows.first);

/// The default row's deadline (2026-10-15) is far enough ahead to stay valid
/// for these tests; this produces an explicitly expired variant.
Scholarship _expiredScholarship() {
  final row = {...FakeScholarshipDataSource.defaultRows.first};
  row['deadline'] = '2020-01-01';
  return Scholarship.fromJson(row);
}

Scholarship _inactiveScholarship() {
  final row = {...FakeScholarshipDataSource.defaultRows.first};
  row['is_active'] = false;
  return Scholarship.fromJson(row);
}

Scholarship _ineligibleScholarship() {
  // Student GPA is 3.2 → a 3.5 minimum makes the profile deterministically
  // ineligible without touching any other criterion.
  final row = {...FakeScholarshipDataSource.defaultRows.first};
  row['min_gpa'] = 3.5;
  return Scholarship.fromJson(row);
}

/// Pumps the scholarship detail screen with the user-scoped providers backed by
/// in-memory fakes, mirroring the real dependency graph. [userId] null renders
/// the signed-out state.
Widget _wrap({
  required Scholarship scholarship,
  String? userId = 'user-a',
  StudentProfile? profile,
  FakeApplicationDataSource? applications,
  FakeBookmarkDataSource? bookmarks,
}) {
  final profileSource = FakeProfileDataSource();
  if (userId != null) {
    profileSource.upsertProfile(
      userId,
      (profile ?? _student()).toDbRow(),
    );
  }

  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: profileSource,
          currentUserId: () => userId,
        ),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: applications ?? FakeApplicationDataSource(),
          currentUserId: () => userId,
        ),
      ),
      bookmarkRepositoryProvider.overrideWith(
        (ref) => BookmarkRepository(
          dataSource: bookmarks ?? FakeBookmarkDataSource(),
          currentUserId: () => userId,
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) => ScholarshipRepository(
          dataSource: FakeScholarshipDataSource(),
        ),
      ),
    ],
    child: MaterialApp(
      home: ScholarshipDetailScreen(
        scholarshipId: scholarship.id,
        initial: scholarship,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Apply action rendering', () {
    testWidgets('eligible student sees the enabled Apply action',
        (tester) async {
      await tester.pumpWidget(_wrap(scholarship: _scholarship()));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
      expect(find.text('Apply now'), findsOneWidget);
      expect(find.text('Application submitted'), findsNothing);
    });

    testWidgets('already-applied scholarship renders the applied state',
        (tester) async {
      final applications = FakeApplicationDataSource();
      await applications.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': _scholarship().id,
        'status': 'submitted',
      });

      await tester.pumpWidget(
        _wrap(scholarship: _scholarship(), applications: applications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Application submitted'), findsOneWidget);
      expect(find.text('Apply now'), findsNothing);
    });
  });

  group('Pre-apply confirmation', () {
    testWidgets('tapping Apply opens the confirmation before any write',
        (tester) async {
      final applications = FakeApplicationDataSource();

      await tester.pumpWidget(
        _wrap(scholarship: _scholarship(), applications: applications),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply now'));
      await tester.pumpAndSettle();

      expect(find.text('Apply to this scholarship?'), findsOneWidget);
      // No write happened just by opening the dialog.
      expect(await applications.fetchApplications('user-a'), isEmpty);
    });

    testWidgets('cancelling the confirmation never creates an application',
        (tester) async {
      final applications = FakeApplicationDataSource();

      await tester.pumpWidget(
        _wrap(scholarship: _scholarship(), applications: applications),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply now'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Apply to this scholarship?'), findsNothing);
      expect(find.text('Apply now'), findsOneWidget);
      expect(find.text('Application submitted'), findsNothing);
      expect(await applications.fetchApplications('user-a'), isEmpty);
    });

    testWidgets('confirming creates the application through the existing path',
        (tester) async {
      final applications = FakeApplicationDataSource();

      await tester.pumpWidget(
        _wrap(scholarship: _scholarship(), applications: applications),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply now'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Application submitted!'), findsOneWidget);
      expect(find.text('Application submitted'), findsOneWidget);
      expect(find.text('Apply now'), findsNothing);

      final rows = await applications.fetchApplications('user-a');
      expect(rows, hasLength(1));
      expect(rows.single['scholarship_id'], _scholarship().id);
      expect(rows.single['status'], 'submitted');
    });
  });

  group('Apply submission', () {
    testWidgets('apply shows a spinner and disables the button while in flight',
        (tester) async {
      final slow = _SlowApplicationDataSource();

      await tester.pumpWidget(
        _wrap(scholarship: _scholarship(), applications: slow),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply now'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-confirm')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      slow.gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Application submitted'), findsOneWidget);
      expect(await slow.fetchApplications('user-a'), hasLength(1));
    });
  });

  group('Deadline safety', () {
    testWidgets('an expired scholarship cannot be applied to',
        (tester) async {
      final applications = FakeApplicationDataSource();

      await tester.pumpWidget(
        _wrap(scholarship: _expiredScholarship(), applications: applications),
      );
      await tester.pumpAndSettle();

      // No Apply affordance at all — the closed state replaces it.
      expect(find.text('Apply now'), findsNothing);
      expect(find.text('Applications closed'), findsOneWidget);
      // Never labelled "Closing soon" (regression: Closing soon — Closed).
      expect(find.textContaining('Closing soon'), findsNothing);

      await tester.tap(find.text('Applications closed'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(await applications.fetchApplications('user-a'), isEmpty);
    });

    testWidgets('an inactive scholarship cannot be applied to',
        (tester) async {
      final applications = FakeApplicationDataSource();

      await tester.pumpWidget(
        _wrap(scholarship: _inactiveScholarship(), applications: applications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apply now'), findsNothing);
      expect(find.text('Not accepting applications'), findsOneWidget);

      await tester.tap(
        find.text('Not accepting applications'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(await applications.fetchApplications('user-a'), isEmpty);
    });
  });

  group('Readiness gating', () {
    testWidgets('an ineligible profile cannot apply and sees the missing '
        'criteria', (tester) async {
      final applications = FakeApplicationDataSource();

      await tester.pumpWidget(
        _wrap(scholarship: _ineligibleScholarship(), applications: applications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apply now'), findsNothing);
      expect(find.text("Why you can't apply"), findsOneWidget);
      // Deterministic, value-bearing explanation — not just "Not eligible".
      expect(
        find.text('Minimum GPA 3.50 — your GPA is 3.20'),
        findsOneWidget,
      );
      // No match is claimed for a profile that does not qualify.
      expect(find.text('Why this matches you'), findsNothing);

      await tester.tap(find.text("Why you can't apply"), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(await applications.fetchApplications('user-a'), isEmpty);
    });

    testWidgets('a missing profile gets the profile-incomplete readiness, '
        'not an eligibility verdict', (tester) async {
      final applications = FakeApplicationDataSource();

      await tester.pumpWidget(
        _wrap(
          scholarship: _ineligibleScholarship(),
          userId: 'user-a',
          profile: _student(setupComplete: false),
          applications: applications,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apply now'), findsNothing);
      expect(find.text('Finish your profile to apply'), findsOneWidget);
      // Must NOT be misrepresented as "not eligible" even though the profile's
      // values would fail the scholarship's requirements.
      expect(find.text("Why you can't apply"), findsNothing);
      expect(find.textContaining('Minimum GPA'), findsNothing);
      expect(await applications.fetchApplications('user-a'), isEmpty);
    });

    testWidgets('an incomplete profile offers the existing profile-setup route',
        (tester) async {
      await tester.pumpWidget(
        _wrap(scholarship: _scholarship(), profile: _student(setupComplete: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Finish your profile to apply'), findsOneWidget);
      expect(find.text('Update profile'), findsOneWidget);
    });
  });

  group('Duplicate prevention', () {
    testWidgets('an existing application is not duplicated', (tester) async {
      final applications = FakeApplicationDataSource();
      await applications.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': _scholarship().id,
        'status': 'submitted',
      });

      await tester.pumpWidget(
        _wrap(scholarship: _scholarship(), applications: applications),
      );
      await tester.pumpAndSettle();

      // The applied state replaces the Apply affordance, so there is no way to
      // submit a second application from the UI.
      expect(find.text('Application submitted'), findsOneWidget);
      expect(find.text('Apply now'), findsNothing);
      expect(await applications.fetchApplications('user-a'), hasLength(1));
    });
  });

  group('Application failure', () {
    testWidgets('a failed submission surfaces an error and stays unapplied',
        (tester) async {
      final failing = _FailingApplicationDataSource();

      await tester.pumpWidget(
        _wrap(scholarship: _scholarship(), applications: failing),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply now'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-confirm')));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not submit your application. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Application submitted'), findsNothing);
      expect(find.text('Apply now'), findsOneWidget);
      expect(await failing.fetchApplications('user-a'), isEmpty);
    });
  });

  group('Unauthenticated safety', () {
    testWidgets('applying while signed out is safe and explains why',
        (tester) async {
      final applications = FakeApplicationDataSource();

      await tester.pumpWidget(
        _wrap(scholarship: _scholarship(), userId: null, applications: applications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apply now'), findsOneWidget);

      await tester.tap(find.text('Apply now'));
      await tester.pumpAndSettle();

      expect(find.text('You must be signed in to apply.'), findsOneWidget);
      expect(find.text('Application submitted'), findsNothing);
      expect(await applications.fetchApplications('user-a'), isEmpty);
    });
  });

  group('Preserved behavior', () {
    testWidgets('bookmark action still saves alongside the Apply action',
        (tester) async {
      final bookmarks = FakeBookmarkDataSource();
      final applications = FakeApplicationDataSource();

      await tester.pumpWidget(
        _wrap(
          scholarship: _scholarship(),
          bookmarks: bookmarks,
          applications: applications,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apply now'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      await tester.pumpAndSettle();
      expect(await bookmarks.fetchScholarshipIds('user-a'), [_scholarship().id]);

      // Applying still works after bookmarking.
      await tester.tap(find.text('Apply now'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Application submitted'), findsOneWidget);
      expect(await applications.fetchApplications('user-a'), hasLength(1));
    });

    testWidgets('detail content is capped to a readable width on desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(scholarship: _scholarship()));
      await tester.pumpAndSettle();

      final listView = find.byType(ListView).first;
      expect(tester.getSize(listView).width, lessThanOrEqualTo(640));
      expect(tester.takeException(), isNull);
    });

    testWidgets('detail facts and Apply action render on a narrow screen',
        (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(scholarship: _scholarship()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Apply now'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Apply now'), findsOneWidget);
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Min GPA 2.00'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Min GPA 2.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
