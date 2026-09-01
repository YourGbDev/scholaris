import 'dart:async';

import 'package:scholaris/features/account/repositories/account_repository.dart';

/// In-memory [AccountDataSource] for tests. Records every call (order matters
/// for the reauthenticate → updatePassword sequencing contract) and lets tests
/// inject failures or hold operations in flight. Recorded passwords exist only
/// so tests can assert the repository forwards the right values — the fake is
/// test-only and never part of app code.
class FakeAccountDataSource implements AccountDataSource {
  final List<String> calls = [];

  final List<String> reauthenticateEmails = [];
  final List<String> reauthenticatePasswords = [];
  final List<String> updatePasswords = [];
  final List<String> resendEmails = [];

  /// The user id [reauthenticate] reports as validated. Change it to simulate
  /// a session that swapped identity mid-flow (the repository must refuse).
  String reauthenticatedUserId = 'user-a';

  Object? reauthenticateError;
  Object? updatePasswordError;
  Object? resendError;

  Completer<void>? reauthenticateGate;
  Completer<void>? updatePasswordGate;
  Completer<void>? resendGate;

  @override
  Future<String> reauthenticate({
    required String email,
    required String password,
  }) async {
    calls.add('reauthenticate');
    reauthenticateEmails.add(email);
    reauthenticatePasswords.add(password);
    final gate = reauthenticateGate;
    if (gate != null) await gate.future;
    final error = reauthenticateError;
    if (error != null) throw error;
    return reauthenticatedUserId;
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    calls.add('updatePassword');
    updatePasswords.add(newPassword);
    final gate = updatePasswordGate;
    if (gate != null) await gate.future;
    final error = updatePasswordError;
    if (error != null) throw error;
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    calls.add('resendVerificationEmail');
    resendEmails.add(email);
    final gate = resendGate;
    if (gate != null) await gate.future;
    final error = resendError;
    if (error != null) throw error;
  }
}
