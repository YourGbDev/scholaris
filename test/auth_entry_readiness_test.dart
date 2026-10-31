import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/providers/dashboard_provider.dart';
import 'package:scholaris/features/splash/presentation/splash_screen.dart';

import 'student_detail_tour_test.dart' as fixture;

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/schools/providers/school_provider.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';

import 'package:scholaris/features/dashboard/presentation/student_dashboard_screen.dart';

class MutableSession extends AuthSessionNotifier {
  @override
  AuthSession? build() => null;
  void login() => state = const AuthSession(userId: 'a');
}

class SignedSession extends AuthSessionNotifier {
  @override
  AuthSession? build() => const AuthSession(userId: 'a');
}

class DoneSplash extends SplashCompletedNotifier {
  @override
  bool build() => true;
}

StudentProfile student() => const StudentProfile(
  id: 'a',
  fullName: 'Gb',
  gender: 'male',
  nationality: 'Filipino',
  region: 'NCR',
  gpa: 3.2,
  yearLevel: 2,
  course: 'BSCS',
  setupComplete: true,
);
void main() {
  testWidgets('summary remains unknown until a complete snapshot is ready', (
    tester,
  ) async {
    final gate = Completer<DashboardInfo>();
    await tester.pumpWidget(
      fixture.wrap(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) => gate.future),
            matchesProvider.overrideWith((ref) async => []),
            scholarshipsProvider.overrideWith((ref) async => []),
          ],
          child: const StudentDashboardScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('stat-count-saved'))).data,
      '—',
    );
    gate.complete(
      const DashboardInfo(
        matchCount: 0,
        closingSoonCount: 2,
        savedCount: 1,
        appliedCount: 3,
        pendingApplicationCount: 3,
        closingSoonScholarships: [],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('stat-count-saved'))).data,
      '1',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('stat-count-applied')))
          .data,
      '3',
    );
  });
  test(
    'profile completeness shares the provided current profile snapshot',
    () async {
      final c = ProviderContainer(
        overrides: [
          currentProfileProvider.overrideWith((ref) async => student()),
        ],
      );
      addTearDown(c.dispose);
      expect(await c.read(profileCompleteProvider.future), true);
    },
  );
  testWidgets('authenticated login remains busy while the profile resolves', (
    tester,
  ) async {
    final gate = Completer<StudentProfile?>();
    await tester.pumpWidget(
      fixture.wrap(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(() => SignedSession()),
            currentProfileProvider.overrideWith((ref) => gate.future),
          ],
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('auth-entry-busy')), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    gate.complete(student());
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'real router holds Login until profile is ready then lands only on Home',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_seen': true,
        'intro_seen': true,
        'student_tour_v1_a': true,
      });
      final auth = MutableSession();
      final gate = Completer<StudentProfile?>();
      late ProviderContainer c;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolsProvider.overrideWith((ref) async => []),
            applicationRepositoryProvider.overrideWith(
              (ref) => ApplicationRepository(
                dataSource: FakeApplicationDataSource(),
                currentUserId: () => null,
              ),
            ),
            bookmarkRepositoryProvider.overrideWith(
              (ref) => BookmarkRepository(
                dataSource: FakeBookmarkDataSource(),
                currentUserId: () => null,
              ),
            ),
            authSessionProvider.overrideWith(() => auth),
            currentUserIdProvider.overrideWith(
              (ref) => ref.watch(authSessionProvider)?.userId,
            ),
            currentProfileProvider.overrideWith((ref) {
              final id = ref.watch(currentUserIdProvider);
              return id == null ? Future.value(null) : gate.future;
            }),
            scholarshipsProvider.overrideWith((ref) async => []),
            matchesProvider.overrideWith((ref) async => []),
            splashCompletedProvider.overrideWith(() => DoneSplash()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              c = ProviderScope.containerOf(context);
              return MaterialApp.router(
                routerConfig: ref.watch(routerProvider),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final router = c.read(routerProvider);
      router.go('/login');
      await tester.pumpAndSettle();
      final landings = <String>[];
      router.routerDelegate.addListener(
        () => landings.add(router.routerDelegate.currentConfiguration.uri.path),
      );
      auth.login();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(find.byKey(const ValueKey('auth-entry-busy')), findsOneWidget);
      gate.complete(student());
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(find.byType(LoginScreen), findsNothing);
      expect(
        landings.where((path) => path.startsWith('/profile-setup')),
        isEmpty,
      );
      expect(landings.where((path) => path == '/home').length, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
