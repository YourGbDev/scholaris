// Widget tests for Day 14 — the Profile tab surface.
//
// Covers the Account Settings entry point (rendered, and pushing the
// AccountSettingsScreen through the app's standard Navigator-push pattern)
// and the corrected profile-load failure state: an ErrorView with a working
// retry, not an EmptyView.
//
// No live Supabase involved: the profile provider and the account repository
// are overridden, and the auth session boundary is a controllable notifier.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/account/presentation/account_settings_screen.dart';
import 'package:scholaris/features/account/providers/account_provider.dart';
import 'package:scholaris/features/account/repositories/account_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/presentation/profile_tab_screen.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'helpers/fake_account_data_source.dart';

/// Controllable auth session notifier; initial state comes from build() so it
/// is bound before any widget reads it.
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

StudentProfile _profile() => const StudentProfile(
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

Widget _harness({
  required Future<StudentProfile?> Function() profileFactory,
}) {
  final auth = _TestAuthNotifier(
    userId: 'user-a',
    email: 'a@b.com',
    emailConfirmed: true,
  );
  return UncontrolledProviderScope(
    container: ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(() => auth),
        currentUserIdProvider.overrideWithValue('user-a'),
        currentProfileProvider.overrideWith((ref) => profileFactory()),
        accountRepositoryProvider.overrideWithValue(
          AccountRepository(
            dataSource: FakeAccountDataSource(),
            currentUserId: () => 'user-a',
            currentUserEmail: () => 'a@b.com',
          ),
        ),
      ],
    ),
    child: const MaterialApp(home: ProfileTabScreen()),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders the Account Settings entry', (tester) async {
    await tester.pumpWidget(_harness(profileFactory: () async => _profile()));
    await tester.pumpAndSettle();

    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('Email, verification and password'), findsOneWidget);
  });

  testWidgets('tapping the entry opens AccountSettingsScreen',
      (tester) async {
    await tester.pumpWidget(_harness(profileFactory: () async => _profile()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account Settings'));
    await tester.pumpAndSettle();

    // The pushed screen shows the account email and verification status.
    expect(find.byType(AccountSettingsScreen), findsOneWidget);
    expect(find.text('a@b.com'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);

    // Back returns to the Profile tab content.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.byType(AccountSettingsScreen), findsNothing);
  });

  testWidgets('profile load failure renders ErrorView, not EmptyView',
      (tester) async {
    await tester.pumpWidget(_harness(
      profileFactory: () async => throw Exception('profiles down'),
    ));
    await tester.pumpAndSettle();

    // Established ErrorView conventions: heading + retry affordance.
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('We could not load your profile.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    // The old (incorrect) EmptyView presentation must be gone.
    expect(find.text('Profile unavailable'), findsNothing);
  });

  testWidgets('retry re-fetches the profile and recovers', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(_harness(profileFactory: () async {
      attempts++;
      if (attempts == 1) throw Exception('profiles down');
      return _profile();
    }));
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
  });
}
