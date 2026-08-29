// Widget tests for Day 8 discovery search/filter/sort UX: the search field,
// filter sheet, active filter chips/badge, count updates, deduplicated browse,
// and the empty / inline result states. Providers are overridden with in-memory
// fakes so no network is hit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/presentation/discovery_filter_sheet.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

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

/// Matches: DOST, CHED, NGO (all eligible for the student profile).
/// Browse: TESDA (Region VII), BARMM (BARMM) — region-restricted.
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
        'tags': const ['stem', 'stipend'],
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
        'id': 'sch-ngo',
        'name': 'NGO Stipend Award',
        'provider': 'UNICEF PH',
        'description': 'Monthly stipend for community student leaders.',
        'min_gpa': 2.0,
        'year_levels': [1, 2, 3, 4, 5],
        'eligible_courses': <String>[],
        'citizenship_required': 'any',
        'regions_eligible': <String>[],
        'max_income_bracket': 'any',
        'is_pwd_priority': false,
        'is_working_student_priority': false,
        'slots_available': 500,
        'deadline': _inDays(15).toIso8601String().split('T').first,
        'amount': 20000,
        'coverage_type': 'stipend',
        'tags': const ['community', 'stipend'],
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
        'deadline': _inDays(40).toIso8601String().split('T').first,
        'amount': 30000,
        'coverage_type': 'partial',
        'tags': const ['vocational'],
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
        'deadline': _inDays(25).toIso8601String().split('T').first,
        'amount': 40000,
        'coverage_type': 'full',
        'tags': const ['community'],
        'is_active': true,
      },
    ];

ProviderScope _wrap({Widget? child}) {
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
          dataSource: FakeBookmarkDataSource(),
          currentUserId: () => 'user-a',
        ),
      ),
    ],
    child: MaterialApp(home: child ?? const HomeScreen()),
  );
}

/// Pumps the Discover tab on a tall surface so every section — including the
/// browse section far below the fold — is built and findable.
Future<void> _pumpDiscover(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
}

Finder _inSheet(Finder inner) =>
    find.descendant(of: find.byType(DiscoveryFilterSheet), matching: inner);

Future<void> _openFilters(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.tune_rounded));
  await tester.pumpAndSettle();
}

Future<void> _selectInSheet(WidgetTester tester, Finder finder) async {
  await tester.tap(_inSheet(finder));
  await tester.pumpAndSettle();
}

Future<void> _closeSheet(WidgetTester tester) async {
  await tester.tap(_inSheet(find.text('Done')));
  await tester.pumpAndSettle();
}

Future<void> _typeSearch(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('search field', () {
    testWidgets('renders the search field and filter button', (tester) async {
      await _pumpDiscover(tester);

      expect(find.text('Search scholarships'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('typing narrows matches and browse', (tester) async {
      await _pumpDiscover(tester);

      await _typeSearch(tester, 'DOST');

      expect(find.text('DOST-SEI Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship'), findsNothing);
      expect(find.text('NGO Stipend Award'), findsNothing);
      expect(find.text('Browse all scholarships'), findsNothing);
    });

    testWidgets('clearing the search restores both sections', (tester) async {
      await _pumpDiscover(tester);

      await _typeSearch(tester, 'DOST');
      expect(find.text('CHED Merit Scholarship'), findsNothing);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship'), findsOneWidget);
      expect(find.text('NGO Stipend Award'), findsOneWidget);
      expect(find.text('Browse all scholarships'), findsOneWidget);
    });
  });

  group('filter sheet', () {
    testWidgets('opens the filter bottom sheet', (tester) async {
      await _pumpDiscover(tester);

      await _openFilters(tester);

      expect(find.text('Filters'), findsOneWidget);
      expect(_inSheet(find.text('Done')), findsOneWidget);
      expect(_inSheet(find.text('Highest amount')), findsOneWidget);
    });

    testWidgets('selecting a filter narrows matches', (tester) async {
      await _pumpDiscover(tester);

      await _openFilters(tester);
      await _selectInSheet(tester, find.text('Mid'));
      await _closeSheet(tester);

      // CHED is low-only income → excluded under mid.
      expect(find.text('CHED Merit Scholarship'), findsNothing);
      expect(find.text('DOST-SEI Scholarship'), findsOneWidget);
      expect(find.text('NGO Stipend Award'), findsOneWidget);
    });

    testWidgets('shows an active filter badge', (tester) async {
      await _pumpDiscover(tester);

      expect(find.text('1'), findsNothing);

      await _openFilters(tester);
      await _selectInSheet(tester, find.text('Mid'));
      await _closeSheet(tester);

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders removable active filter chips', (tester) async {
      await _pumpDiscover(tester);

      await _openFilters(tester);
      await _selectInSheet(tester, find.text('Mid'));
      await _closeSheet(tester);

      expect(find.text('Income: Mid'), findsOneWidget);
    });

    testWidgets('removing an individual chip restores results',
        (tester) async {
      await _pumpDiscover(tester);

      await _openFilters(tester);
      await _selectInSheet(tester, find.text('Mid'));
      await _closeSheet(tester);

      expect(find.text('CHED Merit Scholarship'), findsNothing);

      await tester.tap(find.descendant(
        of: find.byKey(const ValueKey('filter-chip-Income: Mid')),
        matching: find.byIcon(Icons.close),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Income: Mid'), findsNothing);
      expect(find.text('CHED Merit Scholarship'), findsOneWidget);
    });

    testWidgets('clear-all resets every active filter', (tester) async {
      await _pumpDiscover(tester);

      await _openFilters(tester);
      await _selectInSheet(tester, find.text('Mid'));
      await _selectInSheet(tester, find.text('Full coverage'));
      await _closeSheet(tester);

      // Coverage full → NGO (stipend) drops out of matches.
      expect(find.text('NGO Stipend Award'), findsNothing);
      expect(find.text('Income: Mid'), findsOneWidget);
      expect(find.text('Full coverage'), findsOneWidget);

      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      expect(find.text('Income: Mid'), findsNothing);
      expect(find.text('Full coverage'), findsNothing);
      expect(find.text('NGO Stipend Award'), findsOneWidget);
      expect(find.text('Browse all scholarships'), findsOneWidget);
    });
  });

  group('counts and dedup', () {
    testWidgets('match count updates to the filtered count', (tester) async {
      await _pumpDiscover(tester);

      await _openFilters(tester);
      await _selectInSheet(tester, find.text('Full coverage'));
      await _closeSheet(tester);

      // Matches become DOST + CHED (NGO is stipend).
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('browse count caption updates', (tester) async {
      await _pumpDiscover(tester);

      expect(find.text('Showing 2 scholarships'), findsOneWidget);

      await _openFilters(tester);
      await _selectInSheet(tester, find.text('Full coverage'));
      await _closeSheet(tester);

      // Browse keeps only BARMM (TESDA is partial coverage).
      expect(find.text('Showing 1 scholarships'), findsOneWidget);
      expect(find.text('BARMM Study Grant'), findsOneWidget);
      expect(find.text('TESDA Skills Grant'), findsNothing);
    });

    testWidgets('browse stays deduplicated from matches', (tester) async {
      await _pumpDiscover(tester);

      await _typeSearch(tester, 'CHED');

      // CHED is a match — it must appear exactly once and never be re-added to
      // a browse section.
      expect(find.text('CHED Merit Scholarship'), findsOneWidget);
      expect(find.text('Browse all scholarships'), findsNothing);
    });

    testWidgets('filtered matches preserve reason chips', (tester) async {
      await _pumpDiscover(tester);

      await _typeSearch(tester, 'DOST');

      expect(find.text('DOST-SEI Scholarship'), findsOneWidget);
      expect(find.text('Why this matches you'), findsOneWidget);
      expect(find.text('Your GPA qualifies'), findsWidgets);
      expect(find.text('Your location is eligible'), findsWidgets);
    });
  });

  group('empty states', () {
    testWidgets('shows the full empty state when everything is filtered out',
        (tester) async {
      await _pumpDiscover(tester);

      await _typeSearch(tester, 'nonexistentquery');

      expect(find.text('No scholarships found'), findsOneWidget);
      expect(find.text('Clear search & filters'), findsOneWidget);
    });

    testWidgets('clears from the empty state', (tester) async {
      await _pumpDiscover(tester);

      await _typeSearch(tester, 'nonexistentquery');
      expect(find.text('No scholarships found'), findsOneWidget);

      await tester.tap(find.text('Clear search & filters'));
      await tester.pumpAndSettle();

      expect(find.text('No scholarships found'), findsNothing);
      expect(find.text('DOST-SEI Scholarship'), findsOneWidget);
    });

    testWidgets('matches empty but browse nonempty shows an inline note',
        (tester) async {
      await _pumpDiscover(tester);

      // "grant" matches only browse items (TESDA, BARMM).
      await _typeSearch(tester, 'grant');

      expect(find.text('Your Matches'), findsOneWidget);
      expect(find.text('No scholarships found'), findsNothing);
      expect(
        find.text(
          'No scholarships in your matches match the current search and filters.',
        ),
        findsOneWidget,
      );
      expect(find.text('Showing 2 scholarships'), findsOneWidget);
    });
  });
}
