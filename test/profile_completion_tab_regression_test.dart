import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/dashboard/presentation/student_dashboard_screen.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/presentation/profile_setup_screen.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

import 'helpers/fake_profile_data_source.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Profile Setup Completion Navigation & Tab State Regression', () {
    testWidgets(
      'completing setup with Profile tab previously selected must explicitly land on Dashboard',
      (tester) async {
        tester.view.physicalSize = const Size(440, 956);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const userId = 'student-test-user';
        final dataSource = FakeProfileDataSource();

        // Seed step 1 & 2 completed state in the repository (incomplete setup)
        await dataSource.upsertProfile(userId, {
          'full_name': 'Maria Santos',
          'nationality': 'Filipino',
          'gender': 'female',
          'gpa': 90.0,
          'gpa_scale': 'percentage',
          'year_level': 2,
          'course': 'BS Computer Science',
          'school': 'University of the Philippines',
          'region': 'National Capital Region (NCR)',
          'monthly_family_income': 35000.0,
          'profile_setup_step': 3,
          'setup_complete': false,
        });

        final repository = ProfileRepository(
          dataSource: dataSource,
          currentUserId: () => userId,
        );

        final router = GoRouter(
          initialLocation: '/profile-setup/financial',
          routes: [
            GoRoute(
              path: '/profile-setup/financial',
              builder: (context, state) =>
                  const ProfileSetupScreen(step: 'financial'),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue(userId),
            profileRepositoryProvider.overrideWithValue(repository),
            profileSetupProvider.overrideWith(
              (ref, id) => ProfileSetupNotifier(repository),
            ),
          ],
        );
        addTearDown(container.dispose);

        // 1. Pre-condition: simulate an existing / restored Profile tab selection (tabIndex = 3)
        container.read(homeTabIndexProvider.notifier).selectTab(3);
        expect(
          container.read(homeTabIndexProvider),
          equals(3),
          reason: 'Profile tab must be initially selected to test survival across navigation',
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify we are on Step 3 (Financial Information)
        expect(find.text('Step 3 of 3'), findsOneWidget);
        expect(find.text('Complete Profile'), findsOneWidget);

        // 2. Complete setup through the real completion path
        final completeButton = find.text('Complete Profile');
        await tester.ensureVisible(completeButton);
        await tester.pumpAndSettle();
        await tester.tap(completeButton);

        // Pump through notifier.submit, SuccessOverlay animation, and context.go('/home')
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pumpAndSettle();

        // 3. VERIFY: Dashboard is visible on HomeScreen and tab index is reset to 0
        final tabIndex = container.read(homeTabIndexProvider);
        expect(
          tabIndex,
          equals(0),
          reason: 'Successful initial setup must reset homeTabIndexProvider to 0 (Dashboard)',
        );

        // Confirm StudentDashboardScreen is active
        expect(find.byType(StudentDashboardScreen), findsOneWidget);

        // 4. Confirm the saved profile in repository remains complete
        final savedProfile = await repository.fetchCurrent();
        expect(savedProfile, isNotNull);
        expect(savedProfile!.setupComplete, isTrue);

        // 5. Confirm restart still opens the correct home state
        final restartDecision = authRedirectDecision(
          location: '/splash',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: false,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: savedProfile.setupComplete,
        );
        expect(restartDecision, equals('/home'));

        final freshContainer = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue(userId),
            profileRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(freshContainer.dispose);

        expect(
          freshContainer.read(homeTabIndexProvider),
          equals(0),
          reason: 'Fresh launch starts on Dashboard tab (index 0)',
        );
      },
    );

    testWidgets(
      'normal tab switching and deep links preserve tab selections elsewhere',
      (tester) async {
        tester.view.physicalSize = const Size(440, 956);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Starts on Dashboard (tab 0)
        expect(container.read(homeTabIndexProvider), equals(0));

        // Switch to Discover (tab 1)
        container.read(homeTabIndexProvider.notifier).selectTab(1);
        await tester.pumpAndSettle();
        expect(container.read(homeTabIndexProvider), equals(1));

        // Switch to Tracker (tab 2)
        container.read(homeTabIndexProvider.notifier).selectTab(2);
        await tester.pumpAndSettle();
        expect(container.read(homeTabIndexProvider), equals(2));

        // Switch to Profile (tab 3)
        container.read(homeTabIndexProvider.notifier).selectTab(3);
        await tester.pumpAndSettle();
        expect(container.read(homeTabIndexProvider), equals(3));

        // Switch back to Dashboard (tab 0)
        container.read(homeTabIndexProvider.notifier).selectTab(0);
        await tester.pumpAndSettle();
        expect(container.read(homeTabIndexProvider), equals(0));
      },
    );
  });
}
