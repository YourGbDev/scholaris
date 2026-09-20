import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

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
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

Widget _buildTestApp({
  StudentProfile? profile,
  Widget? child,
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
      currentUserIdProvider.overrideWith((ref) => 'test-user'),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: profileData,
          currentUserId: () => 'test-user',
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
          currentUserId: () => 'test-user',
        ),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: FakeApplicationDataSource(),
          currentUserId: () => 'test-user',
        ),
      ),
    ],
    child: MaterialApp(
      home: child ?? const StudentDashboardScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Student Dashboard Hero Section', () {
    testWidgets('displays male mascot by default or when gender is male',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        profile: const StudentProfile(
          id: 'test-user',
          fullName: 'Gilbert Santos',
          gender: 'male',
          setupComplete: true,
        ),
      ));
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsWidgets);

      final imageWidget = tester.widget<Image>(imageFinder.first);
      expect((imageWidget.image as AssetImage).assetName,
          'assets/images/mascot_male.png');

      // Verify Gilbert greeting is displayed
      expect(find.textContaining('Gilbert!'), findsOneWidget);

      // Verify speech bubble displays
      expect(find.textContaining('scholarship matches! 🎓'), findsOneWidget);
    });

    testWidgets('displays female mascot when gender is female', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        profile: const StudentProfile(
          id: 'test-user',
          fullName: 'Maria Santos',
          gender: 'female',
          setupComplete: true,
        ),
      ));
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsWidgets);

      final imageWidget = tester.widget<Image>(imageFinder.first);
      expect((imageWidget.image as AssetImage).assetName,
          'assets/images/mascot_female.png');

      expect(find.textContaining('Maria!'), findsOneWidget);
    });

    testWidgets('renders floating pill nav bar on HomeScreen', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: const HomeScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Tracker'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
