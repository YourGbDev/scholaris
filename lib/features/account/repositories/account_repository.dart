// lib/features/account/repositories/account_repository.dart
//
// Repository for the self-service account surface: verification-email resend
// and the re-authentication-gated password change.
//
// SECURITY: every operation acts exclusively on the currently authenticated
// session's own identity. Passwords are passed through as opaque arguments to
// the data source and are never logged, persisted, or embedded in any thrown
// error.
//
// Re-authentication uses Supabase signInWithPassword, which re-validates the
// current password in place. For an already-signed-in user it refreshes the
// SAME identity's session (same user id); it does not sign the user out. The
// repository still guards the invariant: it refuses to update the password
// unless the re-authenticated identity matches the user the flow started for.
//
// The data source is injectable so tests can exercise the sequencing
// (reauthenticate → update password), the identity guard, and error paths
// without a real Supabase client.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/app/confirmation_redirect.dart';

/// Thrown when an operation requires a signed-in user but none exists.
class AccountNotAuthenticatedException implements Exception {
  const AccountNotAuthenticatedException();

  @override
  String toString() => 'You must be signed in to manage your account.';
}

/// Thrown when the active session no longer belongs to the user the password
/// change was started for. Defensive guard; never thrown in normal flows.
class AccountSessionChangedException implements Exception {
  const AccountSessionChangedException();

  @override
  String toString() => 'Your session changed. Please sign in and try again.';
}

/// Low-level Supabase auth operations for the account surface.
abstract class AccountDataSource {
  /// Re-authenticates [email] with [password] (the current password) and
  /// returns the user id of the validated session. Throws [AuthException]
  /// when the credentials are rejected (e.g. wrong current password).
  Future<String> reauthenticate({
    required String email,
    required String password,
  });

  /// Updates the signed-in user's password to [newPassword].
  Future<void> updatePassword({required String newPassword});

  /// Resends the signup-confirmation email to [email], returning the user to
  /// the app through the platform-aware verification redirect (Day 13
  /// contract, shared with the signup/verify-email flows).
  Future<void> resendVerificationEmail({required String email});
}

/// Production implementation backed by the shared Supabase client.
class SupabaseAccountDataSource implements AccountDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<String> reauthenticate({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final userId = response.session?.user.id;
    if (userId == null) {
      throw const AuthException('Re-authentication did not return a session.');
    }
    return userId;
  }

  @override
  Future<void> updatePassword({required String newPassword}) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

  @override
  Future<void> resendVerificationEmail({required String email}) =>
      _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: emailConfirmationRedirect,
      );
}

class AccountRepository {
  AccountRepository({
    AccountDataSource? dataSource,
    String? Function()? currentUserId,
    String? Function()? currentUserEmail,
  })  : _dataSource = dataSource ?? SupabaseAccountDataSource(),
        _currentUserId = currentUserId ??
            (() => Supabase.instance.client.auth.currentUser?.id),
        _currentUserEmail = currentUserEmail ??
            (() => Supabase.instance.client.auth.currentUser?.email);

  final AccountDataSource _dataSource;
  final String? Function() _currentUserId;
  final String? Function() _currentUserEmail;

  String? get currentUserId => _currentUserId();
  String? get currentUserEmail => _currentUserEmail();

  /// Changes the signed-in user's password. Sequencing is deliberate:
  ///
  ///   1. re-authenticate with the current password (validates ownership),
  ///   2. verify the re-authenticated identity is still the same user,
  ///   3. only then update the password.
  ///
  /// A failed re-authentication never reaches the password update, and the
  /// operation never touches the auth session boundary's written state.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final userId = _currentUserId();
    final email = _currentUserEmail();
    if (userId == null || email == null || email.isEmpty) {
      throw const AccountNotAuthenticatedException();
    }

    final verifiedUserId = await _dataSource.reauthenticate(
      email: email,
      password: currentPassword,
    );
    if (verifiedUserId != userId) {
      throw const AccountSessionChangedException();
    }

    await _dataSource.updatePassword(newPassword: newPassword);
  }

  /// Resends the verification email for the signed-in user's own address.
  Future<void> resendVerificationEmail() async {
    final email = _currentUserEmail();
    if (email == null || email.isEmpty) {
      throw const AccountNotAuthenticatedException();
    }
    await _dataSource.resendVerificationEmail(email: email);
  }
}
