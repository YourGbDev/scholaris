// Repository tests for Day 14 — the account surface.
//
// Exercises the re-authentication-gated password change and the verification
// resend through the fake data source: exact sequencing, identity guard,
// friendliness of failures, and that no operation proceeds without a signed-in
// session. No network and no live Supabase involved.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/account/repositories/account_repository.dart';
import 'helpers/fake_account_data_source.dart';

void main() {
  group('AccountRepository — changePassword', () {
    late FakeAccountDataSource dataSource;
    late AccountRepository repo;
    String? signedInUserId;
    String? signedInEmail;

    setUp(() {
      dataSource = FakeAccountDataSource();
      signedInUserId = 'user-a';
      signedInEmail = 'a@b.com';
      repo = AccountRepository(
        dataSource: dataSource,
        currentUserId: () => signedInUserId,
        currentUserEmail: () => signedInEmail,
      );
    });

    test('rejects weak new passwords without contacting authentication', () async {
      await expectLater(
        repo.changePassword(currentPassword: 'old-password', newPassword: 'weak'),
        throwsA(isA<ArgumentError>()),
      );
      expect(dataSource.calls, isEmpty);
    });

    test('sequences reauthenticate BEFORE updatePassword', () async {
      await repo.changePassword(
        currentPassword: 'old-password',
        newPassword: 'New-password1!',
      );

      expect(dataSource.calls, ['reauthenticate', 'updatePassword']);
      expect(dataSource.reauthenticateEmails, ['a@b.com']);
      expect(dataSource.reauthenticatePasswords, ['old-password']);
      expect(dataSource.updatePasswords, ['New-password1!']);
    });

    test('reauthentication failure never reaches the password update',
        () async {
      dataSource.reauthenticateError = const AuthException(
        'Invalid login credentials',
      );

      await expectLater(
        repo.changePassword(
          currentPassword: 'wrong',
          newPassword: 'New-password1!',
        ),
        throwsA(isA<AuthException>()),
      );

      expect(dataSource.calls, ['reauthenticate']);
      expect(dataSource.updatePasswords, isEmpty);
    });

    test('wrong current password propagates for the UI to map friendly text',
        () async {
      dataSource.reauthenticateError = const AuthException(
        'Invalid login credentials',
      );

      await expectLater(
        repo.changePassword(
          currentPassword: 'not-my-password',
          newPassword: 'New-password1!',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Invalid login credentials',
          ),
        ),
      );
    });

    test('password-update failure surfaces after successful reauthentication',
        () async {
      dataSource.updatePasswordError = const AuthException(
        'Password should be at least 6 characters',
      );

      await expectLater(
        repo.changePassword(
          currentPassword: 'old-password',
          newPassword: 'New-password1!',
        ),
        throwsA(isA<AuthException>()),
      );

      // Re-auth DID happen; only the update failed.
      expect(dataSource.calls, ['reauthenticate', 'updatePassword']);
    });

    test('reauth resolving to a different user aborts before updatePassword',
        () async {
      // Simulate the (unexpected) case where re-authentication validated a
      // different identity than the flow started with.
      dataSource.reauthenticatedUserId = 'user-b';

      await expectLater(
        repo.changePassword(
          currentPassword: 'old-password',
          newPassword: 'New-password1!',
        ),
        throwsA(isA<AccountSessionChangedException>()),
      );

      expect(dataSource.calls, ['reauthenticate']);
      expect(dataSource.updatePasswords, isEmpty);
    });

    test('account switch during reauthentication prevents password update', () async {
      dataSource.reauthenticateGate = Completer<void>();
      final pending = repo.changePassword(
        currentPassword: 'old-password',
        newPassword: 'New-password1!',
      );
      signedInUserId = 'user-b';
      dataSource.reauthenticateGate!.complete();
      await expectLater(pending, throwsA(isA<AccountSessionChangedException>()));
      expect(dataSource.updatePasswords, isEmpty);
    });

    test('signed-out user cannot change a password', () async {
      signedInUserId = null;
      signedInEmail = null;

      await expectLater(
        repo.changePassword(
          currentPassword: 'old-password',
          newPassword: 'New-password1!',
        ),
        throwsA(isA<AccountNotAuthenticatedException>()),
      );

      expect(dataSource.calls, isEmpty);
    });

    test('reauth failure never exposes the password in the exception text',
        () async {
      dataSource.reauthenticateError = const AuthException('boom');

      Object? caught;
      try {
        await repo.changePassword(
          currentPassword: 'super-secret-current',
          newPassword: 'Super-secret-new1!',
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<AuthException>());
      expect(caught.toString(), isNot(contains('super-secret')));
    });
  });

  group('AccountRepository — resendVerificationEmail', () {
    late FakeAccountDataSource dataSource;
    late AccountRepository repo;
    String? signedInEmail;

    setUp(() {
      dataSource = FakeAccountDataSource();
      signedInEmail = 'a@b.com';
      repo = AccountRepository(
        dataSource: dataSource,
        currentUserId: () => 'user-a',
        currentUserEmail: () => signedInEmail,
      );
    });

    test('resends to the signed-in user\'s own email', () async {
      await repo.resendVerificationEmail();

      expect(dataSource.calls, ['resendVerificationEmail']);
      expect(dataSource.resendEmails, ['a@b.com']);
    });

    test('signed-out user cannot resend', () async {
      signedInEmail = null;

      await expectLater(
        repo.resendVerificationEmail(),
        throwsA(isA<AccountNotAuthenticatedException>()),
      );
      expect(dataSource.calls, isEmpty);
    });

    test('auth failure from the data source propagates for friendly mapping',
        () async {
      dataSource.resendError = const AuthException('rate limit exceeded');

      await expectLater(
        repo.resendVerificationEmail(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  test('email change stops if the signed-in identity changes during reauthentication', () async {
    final source = FakeAccountDataSource()..reauthenticateGate = Completer<void>();
    var userId = 'user-a';
    final repository = AccountRepository(
      dataSource: source,
      currentUserId: () => userId,
      currentUserEmail: () => 'a@b.com',
    );
    final pending = repository.requestEmailChange(currentPassword: 'password', newEmail: 'new@example.com');
    userId = 'user-b';
    source.reauthenticateGate!.complete();
    await expectLater(pending, throwsA(isA<AccountSessionChangedException>()));
    expect(source.requestedEmails, isEmpty);
  });
}
