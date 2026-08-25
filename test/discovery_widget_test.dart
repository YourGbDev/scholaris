// Widget tests for the Day 4 discovery experience: home shell tabs, the
// personalized Discover tab, Saved tab states, and the scholarship detail
// screen. Providers are overridden with in-memory fakes so no network is hit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
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

List<Map<String, dynamic>> _rows() => [
      {
        'id': 'sch-dost',
        'name': 'DOST-SEI Undergraduate Scholarship',
        'provider': 'Department of Science and Technology',
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
        'name': 'CHED Merit Scholarship (MSRS)',
        'provider': 'Commission on Higher Education',
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
    ];

ProviderScope _wrap({Widget? child, FakeBookmarkDataSource? bookmarks}) {
  final profileSource = FakeProfileDataSource();
  profileSource.upsertProfile('user-a', _student().toDbRow());

  return ProviderScope(
    overrides: [
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
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('HomeScreen shell', () {
    testWidgets('renders three navigation tabs', (tester) async {
      await tester.pumpWidget(_wrap(child: const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('switching to the Saved tab shows the empty state',
        (tester) async {
      await tester.pumpWidget(_wrap(child: const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(find.text('Nothing saved yet'), findsOneWidget);
    });

    testWidgets('switching to the Profile tab shows the profile summary',
        (tester) async {
      await tester.pumpWidget(_wrap(child: const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('Your matching profile'), findsOneWidget);
    });
  });

  group('DiscoverScreen', () {
    testWidgets('greets the student and shows personalized matches',
        (tester) async {
      await tester.pumpWidget(_wrap(child: const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Good to see you, Maria'), findsOneWidget);
      expect(find.text('Your Matches'), findsOneWidget);
      // Both seeded scholarships are eligible for this student profile.
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsOneWidget);
      // Explainability chips appear on matched cards.
      expect(find.text('GPA requirement'), findsWidgets);
      expect(find.text('In your region'), findsWidgets);
    });

    testWidgets('matches exclude scholarships below the GPA minimum',
        (tester) async {
      final rows = _rows();
      rows[1]['min_gpa'] = 3.5; // Student GPA is 3.2 → ineligible.

      final profileSource = FakeProfileDataSource();
      profileSource.upsertProfile('user-a', _student().toDbRow());

      await tester.pumpWidget(ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWith(
            (ref) => ProfileRepository(
              dataSource: profileSource,
              currentUserId: () => 'user-a',
            ),
          ),
          scholarshipRepositoryProvider.overrideWith(
            (ref) => ScholarshipRepository(
              dataSource: FakeScholarshipDataSource(rows),
            ),
          ),
          bookmarkRepositoryProvider.overrideWith(
            (ref) => BookmarkRepository(
              dataSource: FakeBookmarkDataSource(),
              currentUserId: () => 'user-a',
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsOneWidget);
    });
  });

  group('SavedScreen', () {
    testWidgets('shows bookmarked scholarships and hides others',
        (tester) async {
      final bookmarks = FakeBookmarkDataSource();
      await bookmarks.addBookmark('user-a', 'sch-ched');

      await tester.pumpWidget(_wrap(
        child: const HomeScreen(),
        bookmarks: bookmarks,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(find.text('CHED Merit Scholarship (MSRS)'), findsOneWidget);
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsNothing);
    });
  });

  group('ScholarshipDetailScreen', () {
    testWidgets('renders the key facts and eligibility from the initial item',
        (tester) async {
      final rows = _rows();
      final scholarship = Scholarship.fromJson(rows.first);

      await tester.pumpWidget(_wrap(
        child: ScholarshipDetailScreen(
          scholarshipId: 'sch-dost',
          initial: scholarship,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Eligibility'), findsOneWidget);
      expect(find.text('Min GPA 2.00'), findsOneWidget);
    });

    testWidgets('bookmark action saves the scholarship', (tester) async {
      final bookmarks = FakeBookmarkDataSource();
      final rows = _rows();
      final scholarship = Scholarship.fromJson(rows.first);

      await tester.pumpWidget(_wrap(
        child: ScholarshipDetailScreen(
          scholarshipId: 'sch-dost',
          initial: scholarship,
        ),
        bookmarks: bookmarks,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      await tester.pumpAndSettle();

      expect(await bookmarks.fetchScholarshipIds('user-a'), ['sch-dost']);
    });
  });
}
