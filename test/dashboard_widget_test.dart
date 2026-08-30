// Day 9 — Discover dashboard widget tests.
//
// Verifies the compact dashboard summary and the Closing Soon urgency surface
// on the Discover tab: correct counts, correct scholarships inside the closing
// window, deadline ordering, applied-state indicators, and no overflow on
// narrow screens. Providers are overridden with in-memory fakes so no network
// is hit.

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
import 'package:scholaris/features/scholarships/screens/discover_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

DateTime _inDays(int days) => DateTime.now().add(Duration(days: days));

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

/// Matches: DOST, CHED (both eligible for the NCR student).
/// Browse: BARMM Scholars Fund (2d), BARMM Study Grant (5d), TESDA (25d).
/// Closing-soon window surfaces BARMM Scholars Fund then BARMM Study Grant.
List<Map<String, dynamic>> _rows() => [
      {
        'id': 'sch-dost',
        'name': 'DOST-SEI Scholarship',
        'provider': 'DOST',
        'description': 'Supports students in priority STEM programs.',
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
        'id': 'sch-ched',
        'name': 'CHED Merit Scholarship',
        'provider': 'CHED',
        'description': 'A national merit scholarship for strong students.',
        'min_gpa': 3.0,
        'year_levels': [1, 2, 3, 4, 5],
        'eligible_courses': <String>[],
        'citizenship_required': 'Filipino',
        'regions_eligible': <String>[],
        'max_income_bracket': 'low',
        'is_pwd_priority': false,
        'is_working_student_priority': false,
        'slots_available': 2000,
        'deadline': _inDays(30).toIso8601String().split('T').first,
        'amount': 50000,
        'coverage_type': 'full',
        'tags': const ['merit'],
        'is_active': true,
      },
      {
        'id': 'sch-mar',
        'name': 'BARMM Scholars Fund',
        'provider': 'BARMM Ministry',
        'description': 'Support for qualified BARMM students.',
        'min_gpa': 2.0,
        'year_levels': [1, 2, 3, 4, 5],
        'eligible_courses': <String>[],
        'citizenship_required': 'any',
        'regions_eligible': ['BARMM'],
        'max_income_bracket': 'any',
        'is_pwd_priority': false,
        'is_working_student_priority': false,
        'slots_available': 200,
        'deadline': _inDays(2).toIso8601String().split('T').first,
        'amount': 20000,
        'coverage_type': 'partial',
        'tags': const ['community'],
        'is_active': true,
      },
      {
        'id': 'sch-barmm',
        'name': 'BARMM Study Grant',
        'provider': 'BARMM Ministry',
        'description': 'Support for qualified BARMM students.',
        'min_gpa': 2.0,
        'year_levels': [1, 2, 3, 4, 5],
        'eligible_courses': <String>[],
        'citizenship_required': 'any',
        'regions_eligible': ['BARMM'],
        'max_income_bracket': 'any',
        'is_pwd_priority': false,
        'is_working_student_priority': false,
        'slots_available': 200,
        'deadline': _inDays(5).toIso8601String().split('T').first,
        'amount': 40000,
        'coverage_type': 'full',
        'tags': const ['community'],
        'is_active': true,
      },
      {
        'id': 'sch-tes',
        'name': 'TESDA Skills Grant',
        'provider': 'TESDA',
        'description': 'Technical skills training financial support.',
        'min_gpa': 2.5,
        'year_levels': [1, 2, 3, 4, 5],
        'eligible_courses': <String>[],
        'citizenship_required': 'Filipino',
        'regions_eligible': ['Region VII'],
        'max_income_bracket': 'mid',
        'is_pwd_priority': false,
        'is_working_student_priority': false,
        'slots_available': 300,
        'deadline': _inDays(25).toIso8601String().split('T').first,
        'amount': 30000,
        'coverage_type': 'partial',
        'tags': const ['vocational'],
        'is_active': true,
      },
    ];

ProviderScope _wrap({
  Widget? child,
  FakeBookmarkDataSource? bookmarks,
  FakeApplicationDataSource? applications,
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
    child: MaterialApp(
      home: Scaffold(
        body: child ?? const DiscoverScreen(),
      ),
    ),
  );
}

Future<void> _pumpDiscover(
  WidgetTester tester, {
  FakeBookmarkDataSource? bookmarks,
  FakeApplicationDataSource? applications,
  Size size = const Size(900, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap(
    bookmarks: bookmarks,
    applications: applications,
  ));
  await tester.pumpAndSettle();
}

Finder _inClosingSoon(Finder inner) => find.descendant(
      of: find.byKey(const ValueKey('closing-soon-section')),
      matching: inner,
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Dashboard summary', () {
    testWidgets('renders the summary with correct counts', (tester) async {
      final bookmarks = FakeBookmarkDataSource();
      await bookmarks.addBookmark('user-a', 'sch-ched');
      final applications = FakeApplicationDataSource();
      await applications.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': 'sch-barmm',
        'status': 'submitted',
      });

      await _pumpDiscover(tester, bookmarks: bookmarks, applications: applications);

      expect(find.text('2 Matches'), findsOneWidget);
      expect(find.text('2 Closing soon'), findsOneWidget);
      expect(find.text('1 Saved'), findsOneWidget);
      expect(find.text('1 Applied'), findsOneWidget);
    });
  });

  group('Closing Soon section', () {
    testWidgets('shows browse scholarships inside the closing window',
        (tester) async {
      await _pumpDiscover(tester);

      expect(_inClosingSoon(find.text('BARMM Scholars Fund')), findsOneWidget);
      expect(_inClosingSoon(find.text('BARMM Study Grant')), findsOneWidget);
    });

    testWidgets('excludes scholarships outside the closing window',
        (tester) async {
      await _pumpDiscover(tester);

      // TESDA closes in 25 days → not in the urgency surface.
      expect(_inClosingSoon(find.text('TESDA Skills Grant')), findsNothing);
    });

    testWidgets('does not duplicate a personalized match', (tester) async {
      await _pumpDiscover(tester);

      // DOST closes in 10 days but is a personalized match — it is surfaced in
      // the matches list below, never re-shown in the closing-soon surface.
      expect(_inClosingSoon(find.text('DOST-SEI Scholarship')), findsNothing);
    });

    testWidgets('orders closing-soon scholarships by deadline urgency',
        (tester) async {
      await _pumpDiscover(tester);

      final fund = tester.getTopLeft(
        _inClosingSoon(find.text('BARMM Scholars Fund')),
      );
      final grant = tester.getTopLeft(
        _inClosingSoon(find.text('BARMM Study Grant')),
      );
      // BARMM Scholars Fund closes first (2d) → appears above the 5d grant.
      expect(fund.dy, lessThan(grant.dy));
    });
  });

  group('Applied state', () {
    testWidgets('a closing-soon card shows the applied indicator',
        (tester) async {
      final applications = FakeApplicationDataSource();
      await applications.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': 'sch-barmm',
        'status': 'submitted',
      });

      await _pumpDiscover(tester, applications: applications);

      expect(find.text('1 Applied'), findsOneWidget);
      expect(_inClosingSoon(find.text('Applied')), findsOneWidget);
    });

    testWidgets('a matched card shows the applied indicator', (tester) async {
      final applications = FakeApplicationDataSource();
      await applications.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': 'sch-dost',
        'status': 'submitted',
      });

      await _pumpDiscover(tester, applications: applications);

      final dostCard = find.ancestor(
        of: find.text('DOST-SEI Scholarship'),
        matching: find.byType(ScholarshipCard),
      );
      expect(find.descendant(of: dostCard, matching: find.text('Applied')),
          findsOneWidget);
    });
  });

  group('Responsive layout', () {
    testWidgets('dashboard does not overflow on a narrow screen',
        (tester) async {
      await _pumpDiscover(tester, size: const Size(360, 720));

      expect(find.text('2 Matches'), findsOneWidget);
      expect(find.text('2 Closing soon'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
