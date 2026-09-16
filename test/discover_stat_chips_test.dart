// test/discover_stat_chips_test.dart
//
// Widget tests for DiscoverScreen upgraded features:
// 1. Quick-stat chips navigation (Saved -> tab 1, Applied -> tab 2).
// 2. Matching power bar tap opens MatchingPowerSheet modal.
// 3. Active application status alert banner rendering and navigation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/presentation/matching_power_sheet.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

class _TestApplicationsNotifier extends ApplicationsNotifier {
  _TestApplicationsNotifier(this._initial);
  final List<Application> _initial;

  @override
  Future<List<Application>> build() async => _initial;
}

StudentProfile _student() => const StudentProfile(
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

ProviderScope _wrap({
  required Widget child,
  List<Application> applications = const [],
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
          dataSource: FakeScholarshipDataSource([]),
        ),
      ),
      bookmarkRepositoryProvider.overrideWith(
        (ref) => BookmarkRepository(
          dataSource: FakeBookmarkDataSource(),
          currentUserId: () => 'user-a',
        ),
      ),
      applicationsProvider.overrideWith(
        () => _TestApplicationsNotifier(applications),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('DiscoverScreen Upgraded Dashboard Interactions', () {
    testWidgets('tapping Bookmarked chip switches homeTabIndex to 1',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap(child: const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      final bookmarkedChip = find.byKey(const ValueKey('stat-chip-saved'));
      expect(bookmarkedChip, findsOneWidget);

      await tester.tap(bookmarkedChip);
      await tester.pump(const Duration(milliseconds: 500));

      // Home tab index should be 1 (Saved screen active)
      final element = tester.element(find.byType(HomeScreen));
      final container = ProviderScope.containerOf(element);
      expect(container.read(homeTabIndexProvider), equals(1));
    });

    testWidgets('tapping Applied chip switches homeTabIndex to 2',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap(child: const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      final appliedChip = find.byKey(const ValueKey('stat-chip-applied'));
      expect(appliedChip, findsOneWidget);

      await tester.tap(appliedChip);
      await tester.pump(const Duration(milliseconds: 500));

      final element = tester.element(find.byType(HomeScreen));
      final container = ProviderScope.containerOf(element);
      expect(container.read(homeTabIndexProvider), equals(2));
    });

    testWidgets('tapping hero matching power bar opens MatchingPowerSheet modal',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap(child: const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      final powerBar = find.byKey(const ValueKey('hero-matching-power-bar'));
      expect(powerBar, findsOneWidget);

      await tester.tap(powerBar);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MatchingPowerSheet), findsOneWidget);
      expect(find.text('Matching Power Diagnostics'), findsOneWidget);
      expect(find.byKey(const ValueKey('matching-power-cta-button')), findsOneWidget);
    });

    testWidgets('active application renders alert banner and navigates on tap',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const activeApp = Application(
        id: 'app-review-1',
        userId: 'user-a',
        scholarshipId: 'sch-1',
        status: ApplicationStatus.underReview,
      );

      await tester.pumpWidget(
        _wrap(
          child: const HomeScreen(),
          applications: [activeApp],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final alertBanner =
          find.byKey(const ValueKey('hero-application-alert-banner'));
      expect(alertBanner, findsOneWidget);
      expect(find.text('Application Under Review'), findsOneWidget);

      await tester.tap(alertBanner);
      await tester.pump(const Duration(milliseconds: 500));

      final element = tester.element(find.byType(HomeScreen));
      final container = ProviderScope.containerOf(element);
      expect(container.read(homeTabIndexProvider), equals(2));
    });
  });
}
