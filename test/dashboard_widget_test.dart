import 'dart:async';
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
import 'package:scholaris/features/dashboard/presentation/student_dashboard_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/scholarships/screens/saved_screen.dart';

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
        'title': 'DOST-SEI Scholarship',
        'provider': 'DOST',
        'description': 'Supports students in priority STEM programs.',
        'min_gpa': 2.0,
        'required_year_levels': [1, 2, 3, 4, 5],
        'required_courses': <String>[],
        'location_restriction': null,
        'max_monthly_income': null,
        'for_pwd': false,
        'for_indigenous': false,
        'slots': 8000,
        'deadline': _inDays(10).toIso8601String().split('T').first,
        'application_url': 'https://dost.gov.ph/scholarships',
        'is_active': true,
      },
      {
        'id': 'sch-ched',
        'title': 'CHED Merit Scholarship',
        'provider': 'CHED',
        'description': 'A national merit scholarship for strong students.',
        'min_gpa': 3.0,
        'required_year_levels': [1, 2, 3, 4, 5],
        'required_courses': <String>[],
        'location_restriction': null,
        'max_monthly_income': 15000,
        'for_pwd': false,
        'for_indigenous': false,
        'slots': 2000,
        'deadline': _inDays(30).toIso8601String().split('T').first,
        'application_url': 'https://ched.gov.ph/scholarships',
        'is_active': true,
      },
      {
        'id': 'sch-mar',
        'title': 'BARMM Scholars Fund',
        'provider': 'BARMM Ministry',
        'description': 'Support for qualified BARMM students.',
        'min_gpa': 2.0,
        'required_year_levels': [1, 2, 3, 4, 5],
        'required_courses': <String>[],
        'location_restriction': 'BARMM',
        'max_monthly_income': null,
        'for_pwd': false,
        'for_indigenous': false,
        'slots': 200,
        'deadline': _inDays(2).toIso8601String().split('T').first,
        'application_url': 'https://barmm.gov.ph/scholarships',
        'is_active': true,
      },
      {
        'id': 'sch-barmm',
        'title': 'BARMM Study Grant',
        'provider': 'BARMM Ministry',
        'description': 'Support for qualified BARMM students.',
        'min_gpa': 2.0,
        'required_year_levels': [1, 2, 3, 4, 5],
        'required_courses': <String>[],
        'location_restriction': 'BARMM',
        'max_monthly_income': null,
        'for_pwd': false,
        'for_indigenous': false,
        'slots': 200,
        'deadline': _inDays(5).toIso8601String().split('T').first,
        'application_url': 'https://barmm.gov.ph/scholarships',
        'is_active': true,
      },
      {
        'id': 'sch-tes',
        'title': 'TESDA Skills Grant',
        'provider': 'TESDA',
        'description': 'Technical skills training financial support.',
        'min_gpa': 2.5,
        'required_year_levels': [1, 2, 3, 4, 5],
        'required_courses': <String>[],
        'location_restriction': 'Region VII',
        'max_monthly_income': null,
        'for_pwd': false,
        'for_indigenous': false,
        'slots': 300,
        'deadline': _inDays(25).toIso8601String().split('T').first,
        'application_url': 'https://tesda.gov.ph/scholarships',
        'is_active': true,
      },
    ];

ProviderScope _wrap({
  Widget? child,
  Future<StudentProfile?>? profileFuture,
  FakeBookmarkDataSource? bookmarks,
  FakeApplicationDataSource? applications,
}) {
  final profileSource = FakeProfileDataSource();
  profileSource.upsertProfile('user-a', _student().toDbRow());

  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-a'),
      if (profileFuture != null)
        currentProfileProvider.overrideWith((ref) => profileFuture),
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
        body: child ?? const StudentDashboardScreen(),
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
  for (final gender in ['male', 'female']) {
  testWidgets('$gender hero keeps shared recommendations and a working Explore action', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(child: const HomeScreen(),
      profileFuture: Future.value(_student().copyWith(gender: gender))));
    await tester.pumpAndSettle();
    expect(find.text('Matches for your profile'), findsNothing);
    expect(find.text('MATCH REVEAL'), findsNothing);
    expect(find.byKey(const ValueKey('stat-count-matches')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Recommended for you'), 160,
      scrollable: find.descendant(of: find.byType(StudentDashboardScreen),
        matching: find.byType(Scrollable)).first);
    expect(find.text('Recommended for you'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Explore matches'), -160,
      scrollable: find.descendant(of: find.byType(StudentDashboardScreen),
        matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore matches'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
    expect(container.read(homeTabIndexProvider), 1);
  });

  testWidgets('$gender hero reflows on a narrow phone with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_wrap(profileFuture: Future.value(_student().copyWith(gender: gender))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Explore matches'));
    await tester.pumpAndSettle();
    expect(find.text('Explore matches').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  }

  testWidgets('Home lists do not repeat dock clearance between sections', (tester) async {
    tester.view.physicalSize = const Size(440, 12000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(child: const MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(bottom: 144)),
      child: StudentDashboardScreen(),
    )));
    await tester.pumpAndSettle();
    final lists = find.byWidgetPredicate((w) => w is ListView && w.shrinkWrap);
    expect(lists, findsNWidgets(2));
    for (final element in lists.evaluate()) {
      final list = find.byWidget(element.widget);
      final cards = find.descendant(of: list, matching: find.byType(ScholarshipCard));
      expect(cards, findsWidgets);
      expect(tester.getBottomRight(list).dy - tester.getBottomRight(cards.last).dy, closeTo(0, 1));
    }
  });

  testWidgets('Saved opened from Home returns to Home with Back', (tester) async {
    await tester.pumpWidget(_wrap(child: const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('stat-chip-saved')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stat-chip-saved')));
    await tester.pumpAndSettle();
    expect(find.byType(SavedScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
    expect(container.read(homeTabIndexProvider), 0);
    expect(find.byKey(const ValueKey('stat-chip-saved')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('female login never paints a male hero while profile loads', (tester) async {
    final pending = Completer<StudentProfile?>();
    await tester.pumpWidget(_wrap(profileFuture: pending.future));
    await tester.pump(const Duration(milliseconds: 100));
    Finder banner(String name) => find.byWidgetPredicate((w) =>
      w is Image && w.image is AssetImage &&
      (w.image as AssetImage).assetName == 'assets/images/$name');
    expect(banner('student_hero_graduate_campus.png'), findsNothing);
    expect(find.byKey(const ValueKey('student-hero-loading')), findsOneWidget);
    pending.complete(_student().copyWith(gender: 'female'));
    await tester.pumpAndSettle();
    expect(banner('student_hero_graduate_campus.png'), findsNothing);
    expect(banner('student_hero_graduate_campus_female.png'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit male gender wins over a name containing Maria', (tester) async {
    await tester.pumpWidget(_wrap(profileFuture: Future.value(_student().copyWith(gender: 'male'))));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage &&
      (w.image as AssetImage).assetName == 'assets/images/student_hero_graduate_campus.png'), findsOneWidget);
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

      // Stat tiles expose their counts via stable keys; the number itself is
      // the tile's primary text.
      int countOf(String statKey) => int.parse(
            tester
                .widget<Text>(
                  find.byKey(ValueKey('stat-count-$statKey')),
                )
                .data!.split(' ').first,
          );

      expect(countOf('matches'), 2);
      expect(find.text('Find your next opportunity.'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const ValueKey('stat-count-matches'))).data,
          '2 scholarships match your profile.');
      expect(countOf('closing-soon'), 2);
      expect(countOf('saved'), 1);
      expect(countOf('applied'), 1);
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
    for (final status in ['approved', 'awarded']) {
      testWidgets('dashboard distinguishes $status applications', (tester) async {
        final applications = FakeApplicationDataSource();
        await applications.insertApplication('user-a', {
          'user_id': 'user-a',
          'scholarship_id': 'sch-dost',
          'status': status,
        });
        await _pumpDiscover(tester, applications: applications);
        expect(find.text(status == 'approved'
            ? 'Application Approved'
            : 'Scholarship Awarded!'), findsOneWidget);
        if (status == 'approved') {
          expect(find.text('Scholarship Awarded!'), findsNothing);
        }
      });
    }

    testWidgets('a closing-soon card shows the applied indicator',
        (tester) async {
      final applications = FakeApplicationDataSource();
      await applications.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': 'sch-barmm',
        'status': 'submitted',
      });

      await _pumpDiscover(tester, applications: applications);

      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('stat-count-applied')))
            .data,
        '1',
      );
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

      expect(find.byKey(const ValueKey('stat-count-matches')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Dashboard advice card', () {
    testWidgets('shows closing scholarships without a repeated alert',
        (tester) async {
      await _pumpDiscover(tester);

      expect(find.byKey(const ValueKey('eli-advice-card')), findsNothing);
      expect(find.text('Deadline Alert!'), findsNothing);
      expect(find.text('Closing Soon (2)'), findsOneWidget);
    });
  });
}
