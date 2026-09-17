// test/logout_confirmation_dialog_test.dart
//
// Tests the shared logout confirmation dialog and verifies that tapping sign out
// in Profile, Account Settings, and Provider Console prompts the user before
// executing the sign-out action.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/account/presentation/account_settings_screen.dart';
import 'package:scholaris/features/account/providers/account_provider.dart';
import 'package:scholaris/features/account/repositories/account_repository.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/presentation/profile_tab_screen.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/provider/presentation/provider_home_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';

import 'helpers/fake_account_data_source.dart';
import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

class _TestAuthNotifier extends AuthSessionNotifier {
  _TestAuthNotifier({
    required this.userId,
    required this.email,
    required this.emailConfirmed,
  });

  final String userId;
  final String? email;
  final bool emailConfirmed;

  @override
  AuthSession? build() => AuthSession(
        userId: userId,
        email: email,
        emailConfirmed: emailConfirmed,
      );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('showLogoutConfirmationDialog unit/widget tests', () {
    testWidgets('renders dialog title, message, Cancel and Log Out actions',
        (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showLogoutConfirmationDialog(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Log out'), findsOneWidget);
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      expect(find.byKey(const ValueKey('logout-cancel')), findsOneWidget);
      expect(find.byKey(const ValueKey('logout-confirm')), findsOneWidget);

      // Tap Cancel -> dialog pops with false
      await tester.tap(find.byKey(const ValueKey('logout-cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out?'), findsNothing);
      expect(dialogResult, isFalse);

      // Re-open and tap Log Out -> dialog pops with true
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('logout-confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out?'), findsNothing);
      expect(dialogResult, isTrue);
    });
  });

  group('Logout confirmation in Profile and Settings', () {
    testWidgets('ProfileTabScreen sign out prompts confirmation dialog',
        (tester) async {
      final profileSource = FakeProfileDataSource();
      profileSource.upsertProfile(
        'user-a',
        const StudentProfile(
          id: 'user-a',
          fullName: 'Juan Dela Cruz',
          nationality: 'Filipino',
          region: 'NCR',
          gpa: 3.2,
          yearLevel: 2,
          course: 'BS Computer Science',
          setupComplete: true,
        ).toDbRow(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-a'),
            profileRepositoryProvider.overrideWith(
              (ref) => ProfileRepository(
                dataSource: profileSource,
                currentUserId: () => 'user-a',
              ),
            ),
            applicationsProvider.overrideWith(() => _EmptyApplicationsNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProfileTabScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final signOutBtn = find.byKey(const ValueKey('profile-logout-button'));
      await tester.ensureVisible(signOutBtn);
      await tester.pumpAndSettle();

      expect(signOutBtn, findsOneWidget);

      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('logout-cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out?'), findsNothing);
      expect(signOutBtn, findsOneWidget);
    });

    testWidgets('AccountSettingsScreen Log Out button prompts confirmation dialog',
        (tester) async {
      final auth = _TestAuthNotifier(
        userId: 'user-a',
        email: 'user@up.edu.ph',
        emailConfirmed: true,
      );
      final accountSource = FakeAccountDataSource();

      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(() => auth),
          accountRepositoryProvider.overrideWithValue(
            AccountRepository(
              dataSource: accountSource,
              currentUserId: () => 'user-a',
              currentUserEmail: () => 'user@up.edu.ph',
            ),
          ),
        ],
      );
      container.read(authSessionProvider);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AccountSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoutBtn = find.byKey(const ValueKey('settings-logout-button'));
      await tester.scrollUntilVisible(
        logoutBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('logout-cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out?'), findsNothing);
    });

    testWidgets('ProviderHomeScreen AppBar sign out prompts confirmation dialog',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('prov-1'),
            applicationRepositoryProvider.overrideWith(
              (ref) => ApplicationRepository(
                dataSource: FakeApplicationDataSource(),
                currentUserId: () => 'prov-1',
              ),
            ),
            scholarshipRepositoryProvider.overrideWith(
              (ref) => ScholarshipRepository(
                dataSource: FakeScholarshipDataSource(),
              ),
            ),
            profileRepositoryProvider.overrideWith(
              (ref) => ProfileRepository(
                dataSource: FakeProfileDataSource(),
                currentUserId: () => 'prov-1',
              ),
            ),
          ],
          child: const MaterialApp(
            home: ProviderHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoutBtn = find.byTooltip('Sign out');
      expect(logoutBtn, findsOneWidget);

      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('logout-cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out?'), findsNothing);
    });
  });
}

class _EmptyApplicationsNotifier extends ApplicationsNotifier {
  @override
  Future<List<Application>> build() async => [];
}
