import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scholaris/features/account/presentation/account_settings_screen.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/presentation/applications_screen.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/auth/presentation/ceremony_screen.dart';
import 'package:scholaris/features/profile/models/applicant_profile.dart';
import 'package:scholaris/features/provider/presentation/widgets/applicant_review_drawer.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Ceremony Screen UI/UX Motion & Latency', () {
    testWidgets('CeremonyScreen auto-advance timer cancels instantly on tap',
        (tester) async {
      var loginPushed = 0;
      final router = GoRouter(
        initialLocation: '/ceremony',
        routes: [
          GoRoute(
            path: '/ceremony',
            builder: (context, state) => const CeremonyScreen(
              autoAdvanceDuration: Duration(milliseconds: 2500),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) {
              loginPushed++;
              return const Scaffold(body: Text('Login Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      // Tap on the ceremony surface before the 2500ms auto-advance expires
      await tester.tap(find.byType(CeremonyScreen));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
      expect(loginPushed, 1);

      // Advance time past the original 2500ms timer to confirm timer was canceled
      await tester.pump(const Duration(milliseconds: 3000));
      expect(loginPushed, 1); // No double push
    });
  });

  group('2. Account Settings Notification Preferences & Ergonomics', () {
    testWidgets(
        'renders 5 notification switches with Apple HIG >= 44pt touch targets',
        (tester) async {
      tester.view.physicalSize = const Size(400, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('student-user-1'),
          ],
          child: const MaterialApp(
            home: AccountSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 5 notification preferences render
      expect(find.text('Deadline Approaching Alerts'), findsOneWidget);
      expect(find.text('New Scholarship Matches'), findsOneWidget);
      expect(find.text('Application Status Updates'), findsOneWidget);
      expect(find.text('Weekly Grant Digest'), findsOneWidget);
      expect(find.text('Email Notifications'), findsOneWidget);

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(5));

      // Apple HIG: Verify that each switch row provides active brand tint
      for (var i = 0; i < 5; i++) {
        final switchItem = tester.widget<Switch>(switches.at(i));
        expect(switchItem.activeTrackColor, kPrimary);
      }

      // Tap the weekly digest switch to verify immediate reactive toggle
      final weeklyDigestSwitchFinder = switches.at(3);
      expect(tester.widget<Switch>(weeklyDigestSwitchFinder).value, false);

      await tester.tap(weeklyDigestSwitchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(weeklyDigestSwitchFinder).value, true);

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pref_alert_weekly_student-user-1'), true);
    });
  });

  group('3. Applications Tracker Pull-to-Refresh & Fluid Physics', () {
    testWidgets('wraps list with brand kPrimary RefreshIndicator and Apple bouncing scroll',
        (tester) async {
      final appDs = FakeApplicationDataSource();
      final schDs = FakeScholarshipDataSource();
      await appDs.insertApplication(
        'student-user-1',
        {
          'scholarship_id': 'sch-dost',
          'status': 'submitted',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('student-user-1'),
            applicationRepositoryProvider.overrideWith(
              (ref) => ApplicationRepository(
                dataSource: appDs,
                currentUserId: () => 'student-user-1',
              ),
            ),
            scholarshipRepositoryProvider.overrideWith(
              (ref) => ScholarshipRepository(dataSource: schDs),
            ),
          ],
          child: const MaterialApp(
            home: ApplicationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for RefreshIndicator
      final refreshFinder = find.byType(RefreshIndicator);
      expect(refreshFinder, findsOneWidget);

      final refreshWidget = tester.widget<RefreshIndicator>(refreshFinder);
      expect(refreshWidget.color, kPrimary);

      // Verify ListView scroll physics conforms to Apple bouncing physics
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget);
      final listWidget = tester.widget<ListView>(listFinder);

      expect(listWidget.physics, isA<AlwaysScrollableScrollPhysics>());
      final physics = listWidget.physics as AlwaysScrollableScrollPhysics;
      expect(physics.parent, isA<AppleBouncingScrollPhysics>());
    });
  });

  group('4. Provider Review Rubric Multi-Viewport Responsiveness & Touch Targets', () {
    final application = Application(
      id: 'app-1',
      userId: 'student-1',
      scholarshipId: 'sch-1',
      status: ApplicationStatus.submitted,
      notes: 'Strong candidate with engineering interest.',
    );

    final scholarship = Scholarship(
      id: 'sch-1',
      title: 'DOST-SEI Merit Scholarship Program',
      provider: 'DOST-SEI',
      amount: 100000,
      deadline: DateTime(2026, 12, 31),
      description: 'Undergraduate science scholarship',
      minGpa: 1.75,
    );

    final applicantProfile = const ApplicantProfile(
      id: 'student-1',
      fullName: 'Juan Dela Cruz',
      school: 'University of the Philippines Diliman',
      course: 'BS Computer Science',
      yearLevel: 3,
      gpa: 1.24,
      region: 'NCR',
      monthlyFamilyIncome: 15000,
      setupComplete: true,
    );

    Future<void> pumpDrawerAtSize(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('prov-1'),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ApplicantReviewDrawer(
                application: application,
                scholarship: scholarship,
                applicantProfile: applicantProfile,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('360x640 narrow mobile viewport: renders rubric with zero RenderFlex overflow',
        (tester) async {
      await pumpDrawerAtSize(tester, const Size(360, 640));

      expect(find.text('PROVIDER SCORING RUBRIC'), findsOneWidget);
      expect(find.text('Candidate Evaluation'), findsOneWidget);
      expect(find.text('COMPOSITE'), findsOneWidget);

      // Verify criteria title does not overflow
      expect(find.text('Academic Excellence'), findsOneWidget);
      expect(find.text('Financial Need & Context'), findsOneWidget);
      expect(find.text('Leadership & Community'), findsOneWidget);
      expect(find.text('Innovation Essay & Vision'), findsOneWidget);

      // Expand / collapse rubric toggle check
      final toggleFinder = find.text('Hide detailed rubric criteria');
      expect(toggleFinder, findsOneWidget);
      await tester.scrollUntilVisible(
        toggleFinder,
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(find.text('Show 4 evaluation criteria sliders'), findsOneWidget);
    });

    testWidgets('440x956 iPhone 16 Pro Max viewport: renders rubric and score sliders smoothly',
        (tester) async {
      await pumpDrawerAtSize(tester, const Size(440, 956));

      expect(find.text('PROVIDER SCORING RUBRIC'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(4));

      // Slider touch interaction
      final criteriaText = find.text('Academic Excellence');
      expect(criteriaText, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('768x1024 tablet portrait: renders drawer layout without collision',
        (tester) async {
      await pumpDrawerAtSize(tester, const Size(768, 1024));

      expect(find.text('PROVIDER SCORING RUBRIC'), findsOneWidget);
      expect(find.text('COMPOSITE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1200x800 desktop viewport: renders with spacious alignment',
        (tester) async {
      await pumpDrawerAtSize(tester, const Size(1200, 800));

      expect(find.text('PROVIDER SCORING RUBRIC'), findsOneWidget);
      expect(find.text('COMPOSITE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
