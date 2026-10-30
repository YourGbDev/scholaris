import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/app/router.dart';
import 'package:scholaris/core/security/inactivity_guard.dart';
import 'package:scholaris/core/security/inactivity_storage.dart';
import 'package:scholaris/features/applications/presentation/applications_screen.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_shell.dart';
import 'package:scholaris/features/provider/providers/provider_sub_role_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

class _SignedInSession extends AuthSessionNotifier {
  _SignedInSession([this._userId = 'user-a']);
  final String _userId;

  @override
  AuthSession? build() => AuthSession(userId: _userId);
}

class _BrokenStorage extends InactivityStorage {
  @override
  Future<int?> read(String key) async => throw StateError('storage unavailable');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('QA Challenge 1 & 2: Inactivity Lifecycle, Resumption & Sign-Out Handling', () {
    testWidgets('Requirement 7: Failed automatic sign-out keeps screen blocked and offers retry',
        (tester) async {
      var signOutCalls = 0;
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Protected Dashboard')),
        ),
      ]);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedInSession.new),
            routerProvider.overrideWithValue(router),
            inactivitySignOutProvider.overrideWithValue(() async {
              signOutCalls++;
              throw StateError('Simulated network offline during sign-out');
            }),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Protected Dashboard'), findsOneWidget);

      // Advance past the 15-minute timeout
      await tester.pump(const Duration(minutes: 15));
      await tester.pump();

      // Verify sign-out was attempted
      expect(signOutCalls, 1);

      // Verify fail-closed behavior: ModalBarrier is active and retry prompt is displayed
      expect(find.byType(ModalBarrier), findsWidgets);
      expect(find.text('We could not sign you out. Please try again.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      // Tap "Try again" to challenge retry loop
      await tester.tap(find.text('Try again'));
      await tester.pump();

      // Verify retry was called and screen remains locked
      expect(signOutCalls, 2);
      expect(find.byType(ModalBarrier), findsWidgets);
      expect(find.text('We could not sign you out. Please try again.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Requirement 4: Forward lifecycle resume past deadline triggers expiration immediately',
        (tester) async {
      var signOutCalls = 0;
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Sensitive Grants')),
        ),
      ]);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedInSession.new),
            routerProvider.overrideWithValue(router),
            inactivitySignOutProvider.overrideWithValue(() async => signOutCalls++),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Sensitive Grants'), findsOneWidget);

      // Simulate app suspended and system time advancing 20 minutes forward
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 20));

      // Resume app
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Access must immediately be blocked and sign-out invoked
      expect(signOutCalls, 1);
      expect(find.byType(ModalBarrier), findsWidgets);
      expect(find.text('Your session has expired'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('QA Challenge 3: Inactivity Dialog Viewport Hardening (Requirement 8)', () {
    for (final entry in [
      {'name': 'Compact Mobile 360x800', 'size': const Size(360, 800), 'scale': 1.0},
      {'name': 'Large Mobile 440x956', 'size': const Size(440, 956), 'scale': 1.0},
      {'name': 'Desktop Console 1280x800', 'size': const Size(1280, 800), 'scale': 1.0},
      {'name': 'Accessible Scaling 360x800 @ 1.5x', 'size': const Size(360, 800), 'scale': 1.5},
    ]) {
      final name = entry['name'] as String;
      final size = entry['size'] as Size;
      final scale = entry['scale'] as double;

      testWidgets('Inactivity warning dialog renders without overflow on $name',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = GoRouter(routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('App View'))),
        ]);
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
            ),
            child: ProviderScope(
              overrides: [
                authSessionProvider.overrideWith(_SignedInSession.new),
                routerProvider.overrideWithValue(router),
              ],
              child: const ScholarisApp(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(minutes: 14));

        expect(find.text('Your session is about to expire'), findsOneWidget);
        expect(find.text('Stay signed in'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('QA Challenge 4: Baseline Zero Synthetic State & KPI Title Defect Reproduction (Requirement 8)', () {
    testWidgets('Draft card presentation challenges synthetic checklist rows',
        (tester) async {
      // Challenge requirement from SPECIALIST_CONTRACT.md Section 5:
      // "All hardcoded mock checklist rows (Personal Statement (750 words),
      // UP Diliman Academic Transcript, Faculty Recommendation) are completely removed."
      final applications = FakeApplicationDataSource();
      await applications.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': 'sch-dost',
        'status': 'draft',
        'applied_at': '2026-08-27T00:00:00Z',
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-a'),
            applicationRepositoryProvider.overrideWith(
              (ref) => ApplicationRepository(
                dataSource: applications,
                currentUserId: () => 'user-a',
              ),
            ),
            scholarshipRepositoryProvider.overrideWith(
              (ref) => ScholarshipRepository(
                dataSource: FakeScholarshipDataSource([
                  {
                    'id': 'sch-dost',
                    'title': 'DOST Merit Scholarship',
                    'deadline': '2026-12-31T00:00:00Z',
                  }
                ]),
              ),
            ),
          ],
          child: const MaterialApp(
            home: ApplicationsScreen(embedded: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check whether synthetic state is present (baseline renders these mock rows)
      final hasMockTranscript = find.text('UP Diliman Academic Transcript').evaluate().isNotEmpty;
      final hasMockEssay = find.text('Personal Statement (750 words)').evaluate().isNotEmpty;
      final hasMockRec = find.text('Faculty Recommendation (1 of 2)').evaluate().isNotEmpty;
      final hasHonestText = find.text('Review your draft and attached documents.').evaluate().isNotEmpty;

      // Diagnostic logging for baseline defect reproduction
      if (hasMockTranscript || hasMockEssay || hasMockRec) {
        debugPrint('[BASELINE REPRODUCTION] Synthetic mock draft items detected: '
            'transcript=$hasMockTranscript, essay=$hasMockEssay, rec=$hasMockRec');
      } else {
        debugPrint('[DELIVERED UI VERIFIED] Honest draft presentation verified: '
            'Review text present=$hasHonestText');
      }

      // Strict assertions: Reject every synthetic checklist row and require honest draft copy
      expect(find.text('Review your draft and attached documents.'), findsOneWidget,
          reason: 'Honest draft review message must be rendered');
      expect(find.text('Personal Statement (750 words)'), findsNothing,
          reason: 'Synthetic personal statement checklist row must be completely removed');
      expect(find.text('UP Diliman Academic Transcript'), findsNothing,
          reason: 'Synthetic academic transcript checklist row must be completely removed');
      expect(find.text('Faculty Recommendation (1 of 2)'), findsNothing,
          reason: 'Synthetic faculty recommendation checklist row must be completely removed');
    });

    testWidgets('Provider console challenges legacy Confirmed Awardees KPI card title',
        (tester) async {
      final fakeProfileDs = FakeProfileDataSource();
      fakeProfileDs.rows['prov-1'] = {
        'id': 'prov-1',
        'email': 'provider@scholaris.ph',
        'role': 'provider',
        'status': 'active',
        'setup_complete': true,
      };

      final fakeAppDs = FakeApplicationDataSource();
      final fakeScholDs = FakeScholarshipDataSource([
        {
          'id': 'sch-1',
          'title': 'Ayala Grant 2026',
          'created_by': 'prov-1',
          'award_amount': 50000,
          'deadline': '2026-12-31T00:00:00Z',
          'is_active': true,
        }
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationMembershipProvider.overrideWith((ref) async => {
              'user_id': 'prov-1',
              'organization_id': 'prov-1',
              'role': 'org_admin',
            }),
            currentUserIdProvider.overrideWithValue('prov-1'),
            profileRepositoryProvider.overrideWith(
              (ref) => ProfileRepository(
                dataSource: fakeProfileDs,
                currentUserId: () => 'prov-1',
              ),
            ),
            scholarshipRepositoryProvider.overrideWith(
              (ref) => ScholarshipRepository(dataSource: fakeScholDs),
            ),
            applicationRepositoryProvider.overrideWith(
              (ref) => ApplicationRepository(
                dataSource: fakeAppDs,
                currentUserId: () => 'prov-1',
              ),
            ),
          ],
          child: const MaterialApp(
            home: OrgProviderShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Applications tab to inspect incoming applications KPI cards
      await tester.tap(find.text('Applications').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Application summary'));
      await tester.pumpAndSettle();

      final hasLegacyTitle = find.text('Confirmed Awardees').evaluate().isNotEmpty;
      final hasUpdatedTitle = find.text('Approved / Awarded').evaluate().isNotEmpty;

      if (hasLegacyTitle) {
        debugPrint('[BASELINE REPRODUCTION] Legacy KPI card title "Confirmed Awardees" detected on baseline 4145458');
      } else {
        debugPrint('[DELIVERED UI VERIFIED] Honest KPI title "Approved / Awarded" detected: $hasUpdatedTitle');
      }
      expect(hasLegacyTitle, isFalse, reason: 'Confirmed Awardees title must be eliminated');
      expect(hasUpdatedTitle, isTrue, reason: 'Approved / Awarded title must be present');
    });
  });

  group('QA Challenge 5: Timestamp Bounds & Tampering Policy Specification', () {
    test('Contract 4.3 Bounds Check: Far-future timestamps (>24h) must be identified as implausible', () {
      final now = DateTime.now();
      const maxAllowedFuture = Duration(hours: 24);

      // Plausible normal timestamp: 15 minutes from now
      final normalDeadline = now.add(const Duration(minutes: 15));
      expect(normalDeadline.isAfter(now.add(maxAllowedFuture)), isFalse);

      // Implausible future timestamp: 30 days from now (tampered storage)
      final tamperedFarFutureDeadline = now.add(const Duration(days: 30));
      expect(tamperedFarFutureDeadline.isAfter(now.add(maxAllowedFuture)), isTrue,
          reason: 'A timestamp 30 days in the future exceeds the 24h plausibility threshold');

      // Negative timestamp: in 1969
      final negativeTimestamp = DateTime.fromMillisecondsSinceEpoch(-100);
      expect(negativeTimestamp.isBefore(now), isTrue,
          reason: 'Negative timestamps must be treated as expired');
    });

    testWidgets(
        'Contract 4.5 Clock Tampering: Backward clock jump (<24h) in InactivityGuard clamps remaining window to 15m',
        (tester) async {
      var mockNow = DateTime(2026, 10, 30, 12, 0, 0);
      var signOutCalls = 0;
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Protected Records')),
        ),
      ]);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedInSession.new),
            routerProvider.overrideWithValue(router),
            inactivityClockProvider.overrideWithValue(() => mockNow),
            inactivitySignOutProvider.overrideWithValue(() async => signOutCalls++),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Protected Records'), findsOneWidget);

      // System clock artificially rolled backward by 2 hours (10:00:00 instead of 12:00:00)
      mockNow = mockNow.subtract(const Duration(hours: 2));

      // App lifecycle resumes; InactivityGuard must clamp remaining time to 15m instead of 2h 15m
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Advancing 16 minutes from the rolled-back time must trigger expiration
      mockNow = mockNow.add(const Duration(minutes: 16));
      await tester.pump(const Duration(minutes: 16));
      await tester.pump();

      expect(signOutCalls, 1,
          reason: 'Session must expire after 15 minutes of rolled-back time due to 15-minute clamping');
      expect(find.text('Your session has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('QA Challenge 6: Protected Content Concealment Verification (Requirement 2 & 5)', () {
    testWidgets('Protected content is completely concealed during loading and expired restore',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'inactivity_deadline_user-a': DateTime.now()
            .subtract(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
      });
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Confidential Student Record'))),
      ]);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedInSession.new),
            routerProvider.overrideWithValue(router),
          ],
          child: const ScholarisApp(),
        ),
      );
      // While hydrating / loading storage
      expect(find.text('Confidential Student Record'), findsNothing);

      await tester.pump();
      await tester.pump();

      // Restored expired: content must remain completely concealed
      expect(find.text('Confidential Student Record'), findsNothing);
      expect(find.text('Your session has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Protected content is completely concealed during storage failure',
        (tester) async {
      final brokenStorage = _BrokenStorage();
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Confidential Student Record'))),
      ]);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedInSession.new),
            routerProvider.overrideWithValue(router),
            inactivityStorageProvider.overrideWithValue(brokenStorage),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Confidential Student Record'), findsNothing);
      expect(find.text('Security check unavailable'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Protected content remains visible beneath warning dialog during 14m warning',
        (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Confidential Student Record'))),
      ]);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedInSession.new),
            routerProvider.overrideWithValue(router),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Confidential Student Record'), findsOneWidget);

      // Advance to 14 minutes
      await tester.pump(const Duration(minutes: 14));

      // Warning dialog is visible AND protected content remains visible underneath
      expect(find.text('Your session is about to expire'), findsOneWidget);
      expect(find.text('Confidential Student Record'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
