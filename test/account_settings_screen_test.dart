// Widget tests for Day 14 — the Account Settings screen.
//
// The screen is rendered inside a ProviderScope with:
//   * the auth session boundary overridden to a controllable notifier, so the
//     email / verification state comes through the REAL providers the app
//     uses (currentUserEmailProvider / emailConfirmedProvider);
//   * the account repository overridden to a fake-data-source-backed
//     repository, so resend and change-password flows run without network.
//
// No live Supabase involved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/account/presentation/account_settings_screen.dart';
import 'package:scholaris/features/account/providers/account_provider.dart';
import 'package:scholaris/features/account/repositories/account_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'helpers/fake_account_data_source.dart';

/// Controllable auth session notifier mirroring the real boundary's state
/// shape. The initial session is returned from build() so it is bound before
/// any widget reads it.
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

class _Harness {
  _Harness({bool emailConfirmed = true, String? email = 'a@b.com'})
      : auth = _TestAuthNotifier(
          userId: 'user-a',
          email: email,
          emailConfirmed: emailConfirmed,
        ) {
    dataSource = FakeAccountDataSource();
    container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(() => auth),
        accountRepositoryProvider.overrideWithValue(
          AccountRepository(
            dataSource: dataSource,
            currentUserId: () => 'user-a',
            currentUserEmail: () => email,
          ),
        ),
      ],
    );
    // Bind the overridden auth notifier before any widget reads it.
    container.read(authSessionProvider);
  }

  late final _TestAuthNotifier auth;
  late final FakeAccountDataSource dataSource;
  late final ProviderContainer container;

  Widget get screen => UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AccountSettingsScreen()),
      );

  void dispose() => container.dispose();
}

Future<void> _pump(WidgetTester tester, _Harness h) async {
  await tester.pumpWidget(h.screen);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

TextFormField _fieldWidget(WidgetTester tester, String label) =>
    tester.widget<TextFormField>(_field(label));

/// Scrolls the (off-screen) submit button into view, then taps it.
Future<void> _tapUpdatePassword(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() {
    // Nothing to reset globally; harness containers are disposed per test.
  });

  group('account display', () {
    testWidgets('authenticated email is displayed', (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);

      await _pump(tester, h);

      expect(find.text('a@b.com'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Change password'), findsOneWidget);
    });

    testWidgets('verified account renders verified state without resend',
        (tester) async {
      final h = _Harness(emailConfirmed: true);
      addTearDown(h.dispose);

      await _pump(tester, h);

      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Not verified'), findsNothing);
      // No resend action for a verified account.
      expect(find.text('Resend verification email'), findsNothing);
    });

    testWidgets('unverified account renders unverified state with resend',
        (tester) async {
      final h = _Harness(emailConfirmed: false);
      addTearDown(h.dispose);

      await _pump(tester, h);

      expect(find.text('Not verified'), findsOneWidget);
      expect(find.text('Verified'), findsNothing);
      expect(find.text('Resend verification email'), findsOneWidget);
    });

    testWidgets('signed-out state renders unknown email placeholder',
        (tester) async {
      final h = _Harness(email: null);
      addTearDown(h.dispose);

      await _pump(tester, h);

      expect(find.text('Unknown'), findsOneWidget);
    });
  });

  group('resend verification', () {
    testWidgets('resend success shows confirmation', (tester) async {
      final h = _Harness(emailConfirmed: false);
      addTearDown(h.dispose);

      await _pump(tester, h);
      await tester.tap(find.text('Resend verification email'));
      await tester.pumpAndSettle();

      expect(h.dataSource.calls, ['resendVerificationEmail']);
      expect(h.dataSource.resendEmails, ['a@b.com']);
      expect(find.text('Verification email sent. Check your inbox.'),
          findsOneWidget);
    });

    testWidgets('resend failure shows friendly error', (tester) async {
      final h = _Harness(emailConfirmed: false)
        ..dataSource.resendError =
            const AuthException('rate limit exceeded');
      addTearDown(h.dispose);

      await _pump(tester, h);
      await tester.tap(find.text('Resend verification email'));
      await tester.pumpAndSettle();

      expect(
        find.text('Too many requests. Please wait a moment and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('resend shows loading state while in flight', (tester) async {
      final h = _Harness(emailConfirmed: false);
      addTearDown(h.dispose);
      h.dataSource.resendGate = Completer<void>();

      await _pump(tester, h);
      await tester.tap(find.text('Resend verification email'));
      await tester.pump();

      expect(find.text('Sending…'), findsOneWidget);
      // Button disabled while in flight.
      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Sending…'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNull);

      // Complete the operation.
      h.dataSource.resendGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Verification email sent. Check your inbox.'),
          findsOneWidget);
    });
  });

  group('password change — validation', () {
    testWidgets('empty form surfaces field errors and does not call the repo',
        (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);

      await _pump(tester, h);
      await _tapUpdatePassword(tester);
      await tester.pumpAndSettle();

      expect(find.text('Enter your current password.'), findsOneWidget);
      expect(find.text('Enter a new password.'), findsOneWidget);
      expect(find.text('Confirm your new password.'), findsOneWidget);
      expect(h.dataSource.calls, isEmpty);
    });

    testWidgets('password mismatch is reported and nothing is submitted',
        (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);

      await _pump(tester, h);
      await tester.enterText(
        _field('Current Password'),
        'old-password',
      );
      await tester.enterText(_field('New Password'), 'new-password-1');
      await tester.enterText(
        _field('Confirm New Password'),
        'different',
      );
      await _tapUpdatePassword(tester);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(h.dataSource.calls, isEmpty);
    });

    testWidgets('weak password is rejected locally', (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);

      await _pump(tester, h);
      await tester.enterText(_field('Current Password'), 'old');
      await tester.enterText(_field('New Password'), 'short');
      await tester.enterText(_field('Confirm New Password'), 'short');
      await _tapUpdatePassword(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters.'),
        findsOneWidget,
      );
      expect(h.dataSource.calls, isEmpty);
    });

    testWidgets('new password equal to current password is rejected locally',
        (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);

      await _pump(tester, h);
      await tester.enterText(_field('Current Password'), 'same-pass-1');
      await tester.enterText(_field('New Password'), 'same-pass-1');
      await tester.enterText(_field('Confirm New Password'), 'same-pass-1');
      await _tapUpdatePassword(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('New password must be different from your current password.'),
        findsOneWidget,
      );
      expect(h.dataSource.calls, isEmpty);
    });
  });

  group('password change — submission', () {
    testWidgets('successful change sequences reauth-then-update and shows '
        'success', (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);

      await _pump(tester, h);
      await tester.enterText(_field('Current Password'), 'old-pass');
      await tester.enterText(_field('New Password'), 'new-password');
      await tester.enterText(_field('Confirm New Password'),
          'new-password');
      await _tapUpdatePassword(tester);
      await tester.pumpAndSettle();

      expect(h.dataSource.calls, ['reauthenticate', 'updatePassword']);
      expect(find.text('Password updated successfully.'), findsOneWidget);
    });

    testWidgets('sensitive fields are cleared after success', (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);

      await _pump(tester, h);
      await tester.enterText(_field('Current Password'), 'old-pass');
      await tester.enterText(_field('New Password'), 'new-password');
      await tester.enterText(_field('Confirm New Password'),
          'new-password');
      await _tapUpdatePassword(tester);
      await tester.pumpAndSettle();

      expect(_fieldWidget(tester, 'Current Password').controller!.text,
          isEmpty);
      expect(_fieldWidget(tester, 'New Password').controller!.text, isEmpty);
      expect(_fieldWidget(tester, 'Confirm New Password').controller!.text,
          isEmpty);
    });

    testWidgets('incorrect current password shows friendly error and keeps '
        'fields', (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);
      h.dataSource.reauthenticateError =
          const AuthException('Invalid login credentials');

      await _pump(tester, h);
      await tester.enterText(_field('Current Password'), 'wrong-pass');
      await tester.enterText(_field('New Password'), 'new-password');
      await tester.enterText(_field('Confirm New Password'),
          'new-password');
      await _tapUpdatePassword(tester);
      await tester.pumpAndSettle();

      expect(find.text('Current password is incorrect.'), findsOneWidget);
      expect(find.text('Password updated successfully.'), findsNothing);
      // Update never happened; only reauth was attempted.
      expect(h.dataSource.calls, ['reauthenticate']);
      // Fields kept so the user can retry (current password editable).
      expect(_fieldWidget(tester, 'Current Password').controller!.text,
          'wrong-pass');
    });

    testWidgets('reauthentication failure (non-credential) shows generic '
        'friendly error', (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);
      h.dataSource.reauthenticateError = const AuthException('network down');

      await _pump(tester, h);
      await tester.enterText(_field('Current Password'), 'old-pass');
      await tester.enterText(_field('New Password'), 'new-password');
      await tester.enterText(_field('Confirm New Password'),
          'new-password');
      await _tapUpdatePassword(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('We couldn\'t complete that. Please try again.'),
        findsOneWidget,
      );
      expect(h.dataSource.updatePasswords, isEmpty);
    });

    testWidgets('password-update failure shows error and no success message',
        (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);
      h.dataSource.updatePasswordError = const AuthException(
        'Password should be at least 6 characters',
      );

      await _pump(tester, h);
      await tester.enterText(_field('Current Password'), 'old-pass');
      await tester.enterText(_field('New Password'), 'new-password');
      await tester.enterText(_field('Confirm New Password'),
          'new-password');
      await _tapUpdatePassword(tester);
      await tester.pumpAndSettle();

      expect(h.dataSource.calls, ['reauthenticate', 'updatePassword']);
      expect(
        find.text('Failed to change your password. Please try again.'),
        findsNothing,
      );
      // AuthException path → friendly mapping, not the raw server message.
      expect(
        find.text('Password must be at least 6 characters.'),
        findsOneWidget,
      );
      expect(find.text('Password updated successfully.'), findsNothing);
    });

    testWidgets('submission shows loading state while in flight',
        (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);
      h.dataSource.reauthenticateGate = Completer<void>();

      await _pump(tester, h);
      await tester.enterText(_field('Current Password'), 'old-pass');
      await tester.enterText(_field('New Password'), 'new-password');
      await tester.enterText(_field('Confirm New Password'),
          'new-password');
      await _tapUpdatePassword(tester);
      await tester.pump();

      // Button disabled while submitting; its label becomes a spinner.
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      h.dataSource.reauthenticateGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Password updated successfully.'), findsOneWidget);
    });

    testWidgets('password change preserves the authenticated session identity',
        (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);
      final sessionBefore = h.container.read(authSessionProvider);

      await _pump(tester, h);
      await tester.enterText(_field('Current Password'), 'old-pass');
      await tester.enterText(_field('New Password'), 'new-password');
      await tester.enterText(_field('Confirm New Password'), 'new-password');
      await _tapUpdatePassword(tester);
      await tester.pumpAndSettle();

      // The settings flow must never write or replace the auth session
      // boundary's state: same instance, same user, same email facts.
      final sessionAfter = h.container.read(authSessionProvider);
      expect(identical(sessionBefore, sessionAfter), isTrue);
      expect(sessionAfter!.userId, 'user-a');
      expect(sessionAfter.email, 'a@b.com');
      expect(sessionAfter.emailConfirmed, isTrue);
    });
  });
}
