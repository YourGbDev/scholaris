// test/codex_auth_transition_review_test.dart
//
// Targeted empirical verification suite for Codex Local Pass:
// 1. Pageless route / dialog removal on GoRouter auth redirect.
// 2. Fixture reproduction (not production router proof): Admin shell holding room behavior during role resolution.
// 3. Admin cache persistence in ProviderContainer across auth invalidation.
//
// Student: Gilbert Bulado (#71)
// Evaluators: Mr. Ian Celmar A. Avila, MIT & Mr. Roel Daniot, MSIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/admin/presentation/admin_applicants_provider.dart';
import 'package:scholaris/features/admin/presentation/admin_users_provider.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';

class _TestAuthNotifier extends AuthSessionNotifier {
  _TestAuthNotifier({String? initialUserId}) : _current = initialUserId;
  String? _current;

  @override
  AuthSession? build() =>
      _current == null ? null : AuthSession(userId: _current!);

  void signIn(String userId) {
    _current = userId;
    state = AuthSession(userId: userId);
  }

  void signOut() {
    _current = null;
    state = null;
  }
}

void main() {
  group('Empirical Check 1: Pageless Route (Dialog / Bottom Sheet) on GoRouter Redirect', () {
    testWidgets('Flutter automatically unmounts dialog when GoRouter replaces owning page', (tester) async {
      bool isLoggedIn = true;
      late GoRouter router;

      router = GoRouter(
        initialLocation: '/home',
        redirect: (context, state) {
          if (!isLoggedIn && state.matchedLocation != '/login') {
            return '/login';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: ctx,
                        builder: (_) => const AlertDialog(
                          title: Text('Active Review Dialog'),
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Login Screen Content')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Open Dialog'), findsOneWidget);

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('Active Review Dialog'), findsOneWidget);

      // Trigger signed-out transition
      isLoggedIn = false;
      router.refresh();
      await tester.pumpAndSettle();

      final dialogPresent = find.text('Active Review Dialog').evaluate().isNotEmpty;
      final loginPresent = find.text('Login Screen Content').evaluate().isNotEmpty;

      debugPrint('[TEST 1 RESULT] dialogPresent=$dialogPresent loginPresent=$loginPresent');

      expect(loginPresent, isTrue);
      // Confirmed: Flutter Navigator automatically removes pageless routes when the owning page route is replaced
      expect(dialogPresent, isFalse);
    });

    testWidgets('Flutter automatically unmounts bottom sheet when GoRouter replaces owning page', (tester) async {
      bool isLoggedIn = true;
      late GoRouter router;

      router = GoRouter(
        initialLocation: '/home',
        redirect: (context, state) {
          if (!isLoggedIn && state.matchedLocation != '/login') {
            return '/login';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: ctx,
                        builder: (_) => const SizedBox(
                          height: 200,
                          child: Center(child: Text('Active Modal Bottom Sheet')),
                        ),
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Login Screen Content')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Active Modal Bottom Sheet'), findsOneWidget);

      // Trigger signed-out transition
      isLoggedIn = false;
      router.refresh();
      await tester.pumpAndSettle();

      final sheetPresent = find.text('Active Modal Bottom Sheet').evaluate().isNotEmpty;
      final loginPresent = find.text('Login Screen Content').evaluate().isNotEmpty;

      debugPrint('[TEST 1B RESULT] sheetPresent=$sheetPresent loginPresent=$loginPresent');
      expect(loginPresent, isTrue);
      expect(sheetPresent, isFalse);
    });
  });

  group('Fixture Reproduction 2: Deep Link Holding Room on /admin-home', () {
    testWidgets('Holding logic fixture reproduction (no router edits): models premature mount while role resolves', (tester) async {
      final roleCompleter = Completer<String>();
      bool adminScreenMounted = false;
      bool studentHomeMounted = false;

      final router = GoRouter(
        initialLocation: '/admin-home',
        redirect: (context, state) {
          final location = state.matchedLocation;

          // Scholaris router.dart holding logic (lines 722-726)
          if (location == AdminRoute.home && !roleCompleter.isCompleted) {
            return null; // holding on /admin-home while role resolves
          }

          if (roleCompleter.isCompleted) {
            final role = 'student'; // Resolves as non-admin
            return authRedirectDecision(
              location: location,
              isLoggedIn: true,
              recoveryActive: false,
              onAuthRoute: false,
              onSetupRoute: false,
              profileLoading: false,
              profileComplete: true,
              role: role,
            );
          }

          return null;
        },
        routes: [
          GoRoute(
            path: '/admin-home',
            builder: (context, state) {
              adminScreenMounted = true;
              return const Scaffold(
                body: Center(child: Text('Admin Shell View')),
              );
            },
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) {
              studentHomeMounted = true;
              return const Scaffold(
                body: Center(child: Text('Student Home View')),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      // While roleCompleter is in-flight, /admin-home is returned by GoRouter
      debugPrint('[TEST 2 IN FLIGHT] adminMounted=$adminScreenMounted studentMounted=$studentHomeMounted');
      expect(adminScreenMounted, isTrue, reason: 'Holding on route (return null) causes GoRouter to mount target route');
      expect(find.text('Admin Shell View'), findsOneWidget);

      // Now role finishes resolving as student:
      roleCompleter.complete('student');
      router.refresh();
      await tester.pumpAndSettle();

      debugPrint('[TEST 2 RESOLVED] adminMounted=$adminScreenMounted studentMounted=$studentHomeMounted');
      expect(find.text('Admin Shell View'), findsNothing);
      expect(find.text('Student Home View'), findsOneWidget);
    });
  });

  group('Empirical Check 3: Admin Cache Invalidation in ProviderContainer', () {
    test('adminUsersProvider and adminApplicantsProvider clear data in container across authSessionProvider sign-out', () async {
      final authNotifier = _TestAuthNotifier(initialUserId: 'admin-uuid-1');
      final fakeProfileData = FakeProfileDataSource();
      fakeProfileData.upsertProfile('student-1', {
        'full_name': 'Gilbert Bulado',
        'role': 'student',
      });

      final fakeProfileRepo = ProfileRepository(
        dataSource: fakeProfileData,
        currentUserId: () => authNotifier.state?.userId,
      );

      final fakeAppData = FakeApplicationDataSource();
      final fakeAppRepo = ApplicationRepository(
        dataSource: fakeAppData,
        currentUserId: () => authNotifier.state?.userId,
      );

      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(() => authNotifier),
          profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
          applicationRepositoryProvider.overrideWithValue(fakeAppRepo),
        ],
      );
      addTearDown(container.dispose);

      // 1. Initial State: Signed in as Admin
      expect(container.read(authSessionProvider)?.userId, equals('admin-uuid-1'));

      // Read adminUsersProvider and adminApplicantsProvider
      final initialProfiles = await container.read(adminUsersProvider.future);
      expect(initialProfiles.length, equals(1));
      expect(initialProfiles.first.fullName, equals('Gilbert Bulado'));

      final initialApplicants = await container.read(adminApplicantsProvider.future);
      expect(initialApplicants.length, equals(1));

      // 2. Admin signs out: session boundary sets state = null
      authNotifier.signOut();
      expect(container.read(authSessionProvider), isNull);
      expect(container.read(currentUserIdProvider), isNull);

      // User-scoped provider (applicationsProvider) recomputes to empty
      final apps = await container.read(applicationsProvider.future);
      expect(apps, isEmpty, reason: 'applicationsProvider watches currentUserIdProvider and clears on sign-out');

      // Admin providers are read again:
      final adminProfilesAfterSignOut = await container.read(adminUsersProvider.future);
      debugPrint('[TEST 3 RESULT] adminProfilesAfterSignOut count=${adminProfilesAfterSignOut.length}');

      final adminApplicantsAfterSignOut = await container.read(adminApplicantsProvider.future);

      // Regression Assertion: In-memory cache is NOT retained in ProviderContainer across sign-out
      expect(adminProfilesAfterSignOut, isEmpty, reason: 'adminUsersProvider must resolve empty when signed out');
      expect(adminApplicantsAfterSignOut, isEmpty, reason: 'adminApplicantsProvider must resolve empty when signed out');
    });
  });
}
