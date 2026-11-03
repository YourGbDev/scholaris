import 'dart:async';
// Day 9 — Discover dashboard widget tests.
//
// Verifies the compact dashboard summary and the Closing Soon urgency surface
// on the Discover tab: correct counts, correct scholarships inside the closing
// window, deadline ordering, applied-state indicators, and no overflow on
// narrow screens. Providers are overridden with in-memory fakes so no network
// is hit.

import 'package:flutter/material.dart';
import 'package:scholaris/shared/widgets/greeting_mascot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/load_app_fonts.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/account/presentation/account_settings_screen.dart';
import 'package:scholaris/shared/widgets/student_header_actions.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/dashboard/presentation/student_dashboard_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/providers/dashboard_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
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
  Future<DashboardInfo> Function(Ref)? dashboard,
}) {
  final profileSource = FakeProfileDataSource();
  profileSource.upsertProfile('user-a', _student().toDbRow());

  return ProviderScope(
    overrides: [
      if (dashboard != null) dashboardProvider.overrideWith(dashboard),
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
      home: Scaffold(body: child ?? const StudentDashboardScreen()),
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
  await tester.pumpWidget(
    _wrap(bookmarks: bookmarks, applications: applications),
  );
  await tester.pumpAndSettle();
}

Finder _inClosingSoon(Finder inner) => find.descendant(
  of: find.byKey(const ValueKey('closing-soon-section')),
  matching: inner,
);

void main() {
  testWidgets(
    'saving keeps the existing dashboard visible during recomputation',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final pending = Completer<DashboardInfo>();
      final info = DashboardInfo(
        matchCount: 2,
        closingSoonCount: 1,
        savedCount: 0,
        appliedCount: 0,
        pendingApplicationCount: 0,
        closingSoonScholarships: [Scholarship.fromJson(_rows()[2])],
      );
      await tester.pumpWidget(
        _wrap(
          dashboard: (ref) async {
            final bookmarks = ref.watch(bookmarksProvider);
            return bookmarks.valueOrNull?.contains('sch-dost') == true
                ? pending.future
                : info;
          },
        ),
      );
      await tester.pumpAndSettle();
      final closing = find.byKey(const ValueKey('closing-soon-section'));
      expect(closing, findsOneWidget);
      final position = tester.getTopLeft(closing);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(StudentDashboardScreen)),
      );
      await container.read(bookmarksProvider.notifier).toggle('sch-dost');
      await tester.pump();
      expect(container.read(dashboardProvider).isLoading, isTrue);
      expect(closing, findsOneWidget);
      expect(tester.getTopLeft(closing), position);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('stat-count-saved')))
            .data,
        '0',
      );
      pending.complete(info);
      await tester.pumpAndSettle();
    },
  );
  for (final width in [320.0, 390.0]) {
    testWidgets('See all stays at the trailing side of the heading at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final heading = find.text('Recommended for you');
      await tester.scrollUntilVisible(
        heading,
        160,
        scrollable: find
            .descendant(
              of: find.byType(StudentDashboardScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      final action = find.text('See all (2)');
      final button = find.ancestor(
        of: action,
        matching: find.byType(TextButton),
      );
      final headingRect = tester.getRect(heading);
      expect(
        tester.getRect(action).center.dy,
        inInclusiveRange(headingRect.top, headingRect.bottom),
      );
      expect(tester.getRect(button).right, closeTo(width - 20, 1));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'summary tiles use full rows at enlarged text on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final saved = find.byKey(const ValueKey('stat-chip-saved'));
      expect(tester.getSize(saved).width, greaterThanOrEqualTo(280));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('stat-chip-applied'))).dy,
        greaterThan(tester.getBottomLeft(saved).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'recommendation heading reflows at large text without scaling down',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final heading = find.text('Recommended for you');
      await tester.scrollUntilVisible(
        heading,
        180,
        scrollable: find
            .descendant(
              of: find.byType(StudentDashboardScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(
        find.ancestor(of: heading, matching: find.byType(FittedBox)),
        findsNothing,
      );
      final action = find.text('See all (2)');
      expect(
        tester.getTopLeft(action).dy,
        greaterThan(tester.getBottomLeft(heading).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final tab in ['Home', 'Discover']) {
    testWidgets('$tab header Settings opens account settings', (tester) async {
      await tester.pumpWidget(_wrap(child: const HomeScreen()));
      await tester.pumpAndSettle();
      if (tab == 'Discover') {
        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();
      }
      expect(find.byType(StudentHeaderActions), findsOneWidget);
      for (final tooltip in ['Notifications', 'Settings']) {
        final button = find.byTooltip(tooltip);
        expect(tester.getSize(button).shortestSide, greaterThanOrEqualTo(44));
        expect(
          tester
              .widget<Icon>(
                find.descendant(of: button, matching: find.byType(Icon)),
              )
              .color,
          kPrimary,
        );
      }
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountSettingsScreen), findsOneWidget);
    });
  }
  for (final gender in ['male', 'female']) {
    testWidgets(
      '$gender hero keeps shared recommendations and a working Explore action',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _wrap(
            child: const HomeScreen(),
            profileFuture: Future.value(_student().copyWith(gender: gender)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Matches for your profile'), findsNothing);
        expect(find.text('MATCH REVEAL'), findsNothing);
        expect(
          find.byKey(const ValueKey('stat-count-matches')),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.text('Recommended for you'),
          160,
          scrollable: find
              .descendant(
                of: find.byType(StudentDashboardScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.text('Recommended for you'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Explore matches'),
          -160,
          scrollable: find
              .descendant(
                of: find.byType(StudentDashboardScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Explore matches'));
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeScreen)),
        );
        expect(container.read(homeTabIndexProvider), 1);
      },
    );

    testWidgets('$gender hero reflows on a narrow phone with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        _wrap(profileFuture: Future.value(_student().copyWith(gender: gender))),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Explore matches'));
      await tester.pumpAndSettle();
      expect(find.text('Explore matches').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Home lists do not repeat dock clearance between sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 12000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _wrap(
        child: const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(bottom: 144)),
          child: StudentDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final lists = find.byWidgetPredicate((w) => w is ListView && w.shrinkWrap);
    expect(lists, findsNWidgets(2));
    for (final element in lists.evaluate()) {
      final list = find.byWidget(element.widget);
      final cards = find.descendant(
        of: list,
        matching: find.byType(ScholarshipCard),
      );
      expect(cards, findsWidgets);
      expect(
        tester.getBottomRight(list).dy - tester.getBottomRight(cards.last).dy,
        closeTo(0, 1),
      );
    }
  });

  testWidgets('holding the Home brand opens read-only typography diagnostics', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(child: const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Scholaris').first);
    await tester.pumpAndSettle();
    expect(find.text('Typography check'), findsOneWidget);
    expect(find.text('Diagnostic: type-probe-1'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Typography check'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Saved opened from Home returns to Home with Back', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(child: const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('stat-chip-saved')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stat-chip-saved')));
    await tester.pumpAndSettle();
    expect(find.byType(SavedScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    expect(container.read(homeTabIndexProvider), 0);
    expect(find.byKey(const ValueKey('stat-chip-saved')), findsOneWidget);
    final savedLabel = tester.widget<Text>(find.text('Saved').first);
    expect(savedLabel.style?.fontWeight, FontWeight.w500);
    expect(savedLabel.style?.fontSize, 13);
    expect(savedLabel.style?.letterSpacing, -.1);
    expect(tester.takeException(), isNull);
  });
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadAppFonts();
  });

  testWidgets('female login never paints a male hero while profile loads', (
    tester,
  ) async {
    final pending = Completer<StudentProfile?>();
    await tester.pumpWidget(_wrap(profileFuture: pending.future));
    await tester.pump(const Duration(milliseconds: 100));
    Finder banner(String name) => find.byWidgetPredicate(
      (w) =>
          w is GreetingMascotPortrait &&
          (w.gender?.toLowerCase() == 'female'
              ? name == 'female'
              : name == 'male'),
    );
    expect(banner('male'), findsNothing);
    expect(
      find.byKey(const ValueKey('student-overview-loading')),
      findsOneWidget,
    );
    pending.complete(_student().copyWith(gender: 'female'));
    await tester.pumpAndSettle();
    expect(banner('male'), findsNothing);
    expect(banner('female'), findsOneWidget);
    expect(find.textContaining('Maria!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home selects the greeting mascot using the stored gender', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(profileFuture: Future.value(_student().copyWith(gender: 'male'))),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is GreetingMascotPortrait && w.gender == 'male',
      ),
      findsOneWidget,
    );
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

      await _pumpDiscover(
        tester,
        bookmarks: bookmarks,
        applications: applications,
      );

      // Stat tiles expose their counts via stable keys; the number itself is
      // the tile's primary text.
      int countOf(String statKey) => int.parse(
        tester
            .widget<Text>(find.byKey(ValueKey('stat-count-$statKey')))
            .data!
            .split(' ')
            .first,
      );

      expect(find.text('Application Submitted'), findsOneWidget);
      expect(find.text('Explore matches'), findsOneWidget);
      expect(countOf('closing-soon'), 2);
      expect(countOf('saved'), 1);
      expect(countOf('applied'), 1);
    });
  });

  group('Closing Soon section', () {
    testWidgets('shows browse scholarships inside the closing window', (
      tester,
    ) async {
      await _pumpDiscover(tester);

      expect(_inClosingSoon(find.text('BARMM Scholars Fund')), findsOneWidget);
      expect(_inClosingSoon(find.text('BARMM Study Grant')), findsOneWidget);
    });

    testWidgets('excludes scholarships outside the closing window', (
      tester,
    ) async {
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

    testWidgets('orders closing-soon scholarships by deadline urgency', (
      tester,
    ) async {
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
      testWidgets('dashboard distinguishes $status applications', (
        tester,
      ) async {
        final applications = FakeApplicationDataSource();
        await applications.insertApplication('user-a', {
          'user_id': 'user-a',
          'scholarship_id': 'sch-dost',
          'status': status,
        });
        await _pumpDiscover(tester, applications: applications);
        expect(
          find.text(
            status == 'approved'
                ? 'Application Approved'
                : 'Scholarship Awarded!',
          ),
          findsOneWidget,
        );
        if (status == 'approved') {
          expect(find.text('Scholarship Awarded!'), findsNothing);
        }
      });
    }

    testWidgets('a closing-soon card shows the applied indicator', (
      tester,
    ) async {
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
      expect(
        find.descendant(of: dostCard, matching: find.text('Applied')),
        findsOneWidget,
      );
    });
  });

  group('Responsive layout', () {
    testWidgets('dashboard does not overflow on a narrow screen', (
      tester,
    ) async {
      await _pumpDiscover(tester, size: const Size(360, 720));

      expect(find.byKey(const ValueKey('stat-count-matches')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Dashboard advice card', () {
    testWidgets('shows closing scholarships without a repeated alert', (
      tester,
    ) async {
      await _pumpDiscover(tester);

      expect(find.byKey(const ValueKey('eli-advice-card')), findsNothing);
      expect(find.text('Deadline Alert!'), findsNothing);
      expect(find.text('Closing Soon (2)'), findsOneWidget);
    });
  });
}
