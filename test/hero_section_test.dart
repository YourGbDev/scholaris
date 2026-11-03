import 'package:flutter/material.dart';
import 'package:scholaris/shared/widgets/greeting_mascot.dart';
import 'package:scholaris/shared/widgets/mascot_pose_view.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/load_app_fonts.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/dashboard/presentation/student_dashboard_screen.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

Widget _buildTestApp({
  StudentProfile? profile,
  Widget? child,
  List<Scholarship>? matches,
  bool matchesError = false,
  Future<List<Scholarship>>? pendingMatches,
  FakeApplicationDataSource? applications,
  Future<StudentProfile?>? profileFuture,
}) {
  final profileData = FakeProfileDataSource();
  if (profile != null) {
    profileData.rows['test-user'] = profile.toJson();
  } else {
    profileData.rows['test-user'] = const StudentProfile(
      id: 'test-user',
      fullName: 'Gilbert Santos',
      nationality: 'Filipino',
      region: 'NCR',
      gpa: 3.5,
      yearLevel: 3,
      course: 'BS IT',
      setupComplete: true,
    ).toJson();
  }

  return ProviderScope(
    overrides: [
      if (profileFuture != null)
        currentProfileProvider.overrideWith((ref) => profileFuture),
      if (pendingMatches != null)
        matchesProvider.overrideWith((ref) => pendingMatches)
      else if (matchesError)
        matchesProvider.overrideWith((ref) async => throw StateError('offline'))
      else if (matches != null)
        matchesProvider.overrideWith((ref) async => matches),
      currentUserIdProvider.overrideWith((ref) => 'test-user'),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: profileData,
          currentUserId: () => 'test-user',
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) =>
            ScholarshipRepository(dataSource: FakeScholarshipDataSource([])),
      ),
      bookmarkRepositoryProvider.overrideWith(
        (ref) => BookmarkRepository(
          dataSource: FakeBookmarkDataSource(),
          currentUserId: () => 'test-user',
        ),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: applications ?? FakeApplicationDataSource(),
          currentUserId: () => 'test-user',
        ),
      ),
    ],
    child: MaterialApp(home: child ?? const StudentDashboardScreen()),
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadAppFonts();
  });

  group('Student Dashboard next action', () {
    testWidgets(
      'failed profile does not leave a perpetual overview loading message',
      (tester) async {
        final profile = Completer<StudentProfile?>();
        await tester.pumpWidget(
          _buildTestApp(profileFuture: profile.future, matchesError: true),
        );
        profile.completeError(StateError('offline'));
        await tester.pumpAndSettle();
        expect(find.text('Matches unavailable'), findsOneWidget);
        expect(find.text('Getting your overview…'), findsNothing);
      },
    );
    testWidgets(
      'returning student keeps progress below the compact friendly welcome card',
      (tester) async {
        final applications = FakeApplicationDataSource();
        await applications.insertApplication('test-user', {
          'user_id': 'test-user',
          'scholarship_id': 'sch-dost',
          'status': 'submitted',
        });
        await tester.pumpWidget(_buildTestApp(applications: applications));
        await tester.pumpAndSettle();
        expect(find.text('Application Submitted'), findsOneWidget);
        expect(find.text('Explore matches'), findsOneWidget);
        expect(
          find.widgetWithText(TextButton, 'Explore matches'),
          findsOneWidget,
        );
        expect(find.text('Find your next opportunity.'), findsNothing);
        expect(find.byType(GreetingMascotPortrait), findsOneWidget);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('student-home-companion')))
              .width,
          136.5,
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('hero shows loading until matches arrive', (tester) async {
      final pending = Completer<List<Scholarship>>();
      await tester.pumpWidget(_buildTestApp(pendingMatches: pending.future));
      await tester.pump();
      expect(find.text('Finding matches…'), findsOneWidget);
      pending.complete(const []);
      await tester.pumpAndSettle();
      expect(find.text('0 scholarships match your profile.'), findsOneWidget);
    });
    testWidgets('hero does not show a fake zero when matches fail', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(matchesError: true));
      await tester.pumpAndSettle();
      expect(find.text('Matches unavailable'), findsOneWidget);
      expect(find.text('0 scholarships match your profile.'), findsNothing);
    });
    for (final size in [const Size(360, 800), const Size(440, 956)]) {
      testWidgets('live hero remains readable with large text at $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(_buildTestApp(matches: const []));
        await tester.pumpAndSettle();
        expect(find.text('0 scholarships match your profile.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('hero displays the actual match count, including zero', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(matches: const []));
      await tester.pumpAndSettle();
      expect(find.text('0 scholarships match your profile.'), findsOneWidget);
      final oneMatch = Scholarship(
        id: 'live-match',
        title: 'Sample',
        minGpa: 2,
        deadline: DateTime(2099),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_buildTestApp(matches: [oneMatch]));
      await tester.pumpAndSettle();
      expect(find.text('1 scholarship matches your profile.'), findsOneWidget);
    });
    testWidgets(
      'male student receives a personal greeting with a compact Ariel companion',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            profile: const StudentProfile(
              id: 'test-user',
              fullName: 'Gilbert Santos',
              gender: 'male',
              setupComplete: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final mascot = tester.widget<GreetingMascotPortrait>(
          find.byType(GreetingMascotPortrait),
        );
        expect(
          getMascotGreetingAssetPath(gender: mascot.gender),
          'assets/mascots/greetings/ariel.png',
        );

        // Verify Gilbert greeting is displayed
        expect(find.textContaining('Gilbert!'), findsOneWidget);
      },
    );

    testWidgets(
      'female student receives a personal greeting with a compact Ari companion',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            profile: const StudentProfile(
              id: 'test-user',
              fullName: 'Maria Santos',
              gender: 'female',
              setupComplete: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final mascot = tester.widget<GreetingMascotPortrait>(
          find.byType(GreetingMascotPortrait),
        );
        expect(
          getMascotGreetingAssetPath(gender: mascot.gender),
          'assets/mascots/greetings/ari.png',
        );

        expect(find.textContaining('Maria!'), findsOneWidget);
      },
    );

    testWidgets('renders floating pill nav bar on HomeScreen', (tester) async {
      await tester.pumpWidget(_buildTestApp(child: const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Tracker'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
