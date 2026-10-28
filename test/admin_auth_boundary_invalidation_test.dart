// test/admin_auth_boundary_invalidation_test.dart
//
// Independent QA verification suite for Admin Provider Auth Boundary Invalidation.
// Verifies actual admin providers across auth boundary transitions:
// 1. Signed out resolves empty/no data for adminUsersProvider, adminApplicantsProvider, adminAuditLogsProvider.
// 2. Signed in resolves data for authorized session across all providers.
// 3. Signed out transition clears container / resolves empty with no cached data.
// 4. New user initializes fresh state without retaining old user data.
// 5. In-flight stale completion completing after logout does not leak data.
// 6. Direct A-to-B account switch with pending in-flight request isolates state.
//
// Student: Gilbert Bulado (#71)
// Evaluators: Mr. Ian Celmar A. Avila, MIT & Mr. Roel Daniot, MSIT
// Role: QA (ai/qa)
// Contract: SPECIALIST_CONTRACT.md (v2.6)

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/admin/presentation/admin_applicants_provider.dart';
import 'package:scholaris/features/admin/presentation/admin_audit_logs_provider.dart';
import 'package:scholaris/features/admin/presentation/admin_users_provider.dart';
import 'package:scholaris/features/admin/repositories/admin_audit_log_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

import 'helpers/fake_profile_data_source.dart';

/// A controllable [AuthSessionNotifier] to drive sign-in and sign-out transitions.
class _ControllableAuthNotifier extends AuthSessionNotifier {
  _ControllableAuthNotifier({String? initialUserId}) : _current = initialUserId;
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

/// Controllable data source to test in-flight asynchronous completions for profiles.
class _ControllableProfileDataSource extends FakeProfileDataSource {
  Completer<List<Map<String, dynamic>>>? inFlightCompleter;

  @override
  Future<List<Map<String, dynamic>>> fetchAllProfiles() async {
    if (inFlightCompleter != null) {
      return inFlightCompleter!.future;
    }
    return super.fetchAllProfiles();
  }
}

/// Controllable data source to test in-flight asynchronous completions for audit logs.
class _ControllableAuditLogDataSource implements AuditLogDataSource {
  final List<Map<String, dynamic>> rows = [];
  Completer<List<Map<String, dynamic>>>? inFlightCompleter;

  @override
  Future<List<Map<String, dynamic>>> fetchAuditLogs() async {
    if (inFlightCompleter != null) {
      return inFlightCompleter!.future;
    }
    return List<Map<String, dynamic>>.from(rows);
  }
}

void main() {
  group('Admin Auth Boundary Invalidation (adminUsersProvider, adminApplicantsProvider, adminAuditLogsProvider)', () {
    late _ControllableAuthNotifier authNotifier;
    late _ControllableProfileDataSource profileDataSource;
    late _ControllableAuditLogDataSource auditDataSource;
    late ProfileRepository profileRepo;
    late AdminAuditLogRepository auditRepo;
    late ProviderContainer container;

    setUp(() {
      authNotifier = _ControllableAuthNotifier(initialUserId: null);
      profileDataSource = _ControllableProfileDataSource();
      profileDataSource.upsertProfile('student-1', {
        'id': 'student-1',
        'full_name': 'Gilbert Bulado',
        'role': 'student',
        'region': 'Region VII',
        'gpa': 3.85,
        'year_level': 4,
        'course': 'BS Information Technology',
      });
      profileDataSource.upsertProfile('admin-1', {
        'id': 'admin-1',
        'full_name': 'System Administrator',
        'role': 'admin',
        'region': 'NCR',
        'gpa': 4.0,
        'year_level': 1,
        'course': 'Administration',
      });

      auditDataSource = _ControllableAuditLogDataSource();
      auditDataSource.rows.add({
        'id': 'log-1',
        'actor_id': 'admin-1',
        'action': 'admin_login',
        'target_type': 'session',
        'details': {'ip': '127.0.0.1'},
        'created_at': DateTime.now().toIso8601String(),
      });

      profileRepo = ProfileRepository(
        dataSource: profileDataSource,
        currentUserId: () => authNotifier.state?.userId,
      );

      auditRepo = AdminAuditLogRepository(dataSource: auditDataSource);

      container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(() => authNotifier),
          profileRepositoryProvider.overrideWithValue(profileRepo),
          adminAuditLogRepositoryProvider.overrideWithValue(auditRepo),
        ],
      );
      // Force auth provider element to mount in container
      container.read(authSessionProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('1. Signed out resolves empty/no data for all admin providers', () async {
      // Auth state is initially null (signed out)
      expect(container.read(authSessionProvider), isNull);
      expect(container.read(currentUserIdProvider), isNull);

      final users = await container.read(adminUsersProvider.future);
      expect(users, isEmpty, reason: 'adminUsersProvider must resolve empty when signed out');

      final applicants = await container.read(adminApplicantsProvider.future);
      expect(applicants, isEmpty, reason: 'adminApplicantsProvider must resolve empty when signed out');

      final auditLogs = await container.read(adminAuditLogsProvider.future);
      expect(auditLogs, isEmpty, reason: 'adminAuditLogsProvider must resolve empty when signed out');
    });

    test('2. Signed in resolves data for authorized session across all providers', () async {
      authNotifier.signIn('admin-1');
      expect(container.read(currentUserIdProvider), equals('admin-1'));

      final users = await container.read(adminUsersProvider.future);
      expect(users.length, equals(2));
      expect(users.any((u) => u.fullName == 'Gilbert Bulado'), isTrue);
      expect(users.any((u) => u.fullName == 'System Administrator'), isTrue);

      final applicants = await container.read(adminApplicantsProvider.future);
      expect(applicants.length, equals(1));
      expect(applicants.first.fullName, equals('Gilbert Bulado'));

      final auditLogs = await container.read(adminAuditLogsProvider.future);
      expect(auditLogs.length, equals(1));
      expect(auditLogs.first.action, equals('admin_login'));
    });

    test('3. Signed out transition clears container / resolves empty across all providers', () async {
      // Step A: Sign in as admin and populate provider cache
      authNotifier.signIn('admin-1');
      final usersSignedIn = await container.read(adminUsersProvider.future);
      expect(usersSignedIn.length, equals(2));

      final applicantsSignedIn = await container.read(adminApplicantsProvider.future);
      expect(applicantsSignedIn.length, equals(1));

      final auditSignedIn = await container.read(adminAuditLogsProvider.future);
      expect(auditSignedIn.length, equals(1));

      // Step B: Sign out transition occurs
      authNotifier.signOut();
      expect(container.read(authSessionProvider), isNull);
      expect(container.read(currentUserIdProvider), isNull);

      // Step C: Verify providers clear cache and resolve empty immediately
      final usersAfterSignOut = await container.read(adminUsersProvider.future);
      expect(usersAfterSignOut, isEmpty, reason: 'Container must not retain cached admin users after sign-out');

      final applicantsAfterSignOut = await container.read(adminApplicantsProvider.future);
      expect(applicantsAfterSignOut, isEmpty, reason: 'Container must not retain cached admin applicants after sign-out');

      final auditAfterSignOut = await container.read(adminAuditLogsProvider.future);
      expect(auditAfterSignOut, isEmpty, reason: 'Container must not retain cached admin audit logs after sign-out');
    });

    test('4. New user initializes fresh state without retaining old user data', () async {
      // Step A: Admin 1 signs in and views Directory 1
      authNotifier.signIn('admin-1');
      final usersA = await container.read(adminUsersProvider.future);
      expect(usersA.length, equals(2));

      // Step B: Admin 1 logs out
      authNotifier.signOut();
      expect(await container.read(adminUsersProvider.future), isEmpty);

      // Step C: Directory changes while signed out
      await profileDataSource.deleteProfile('student-1');
      profileDataSource.upsertProfile('student-2', {
        'id': 'student-2',
        'full_name': 'Maria Clara',
        'role': 'student',
        'region': 'Region IV-A',
        'gpa': 3.90,
        'year_level': 3,
        'course': 'BS Computer Science',
      });

      // Step D: Admin 2 logs in
      authNotifier.signIn('admin-2');
      final usersB = await container.read(adminUsersProvider.future);
      expect(usersB.length, equals(2));
      expect(usersB.any((u) => u.fullName == 'Gilbert Bulado'), isFalse, reason: 'Must not retain old user data from Admin 1');
      expect(usersB.any((u) => u.fullName == 'Maria Clara'), isTrue, reason: 'Must load fresh state for Admin 2');

      final applicantsB = await container.read(adminApplicantsProvider.future);
      expect(applicantsB.length, equals(1));
      expect(applicantsB.first.fullName, equals('Maria Clara'));
    });

    test('5. In-flight stale completion completing after logout does not leak data', () async {
      // Step A: Admin signs in
      authNotifier.signIn('admin-1');

      // Step B: Set up in-flight asynchronous completers
      final profileCompleter = Completer<List<Map<String, dynamic>>>();
      final auditCompleter = Completer<List<Map<String, dynamic>>>();
      profileDataSource.inFlightCompleter = profileCompleter;
      auditDataSource.inFlightCompleter = auditCompleter;

      // Invalidate to trigger fresh fetches that hang on completers
      container.invalidate(adminUsersProvider);
      container.invalidate(adminApplicantsProvider);
      container.invalidate(adminAuditLogsProvider);

      // Trigger read execution
      container.read(adminUsersProvider);
      container.read(adminApplicantsProvider);
      container.read(adminAuditLogsProvider);

      // Step C: User logs out WHILE request is still in-flight
      authNotifier.signOut();
      expect(container.read(currentUserIdProvider), isNull);

      // Step D: In-flight requests complete AFTER logout with confidential data
      profileCompleter.complete([
        {
          'id': 'secret-1',
          'full_name': 'Confidential Record',
          'role': 'student',
        }
      ]);
      auditCompleter.complete([
        {
          'id': 'secret-log-1',
          'actor_id': 'secret-admin',
          'action': 'confidential_operation',
          'target_type': 'record',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      profileDataSource.inFlightCompleter = null;
      auditDataSource.inFlightCompleter = null;

      // Step E: Verify provider state in container does NOT leak completed in-flight data
      final usersFinal = await container.read(adminUsersProvider.future);
      expect(usersFinal, isEmpty, reason: 'Stale in-flight completion must not leak into signed-out container');

      final applicantsFinal = await container.read(adminApplicantsProvider.future);
      expect(applicantsFinal, isEmpty, reason: 'Stale in-flight completion must not leak into signed-out container');

      final auditFinal = await container.read(adminAuditLogsProvider.future);
      expect(auditFinal, isEmpty, reason: 'Stale in-flight completion must not leak into signed-out container');
    });

    test('6. Direct A-to-B account switch with pending in-flight request isolates state', () async {
      // Step A: User A ('admin-1') signs in
      authNotifier.signIn('admin-1');

      // Step B: Set up an in-flight completer for User A's fetch
      final completerA = Completer<List<Map<String, dynamic>>>();
      profileDataSource.inFlightCompleter = completerA;

      container.invalidate(adminUsersProvider);
      container.read(adminUsersProvider);

      // Step C: Switch directly from User A to User B ('admin-2') while request is in-flight
      profileDataSource.inFlightCompleter = null; // Clear so User B gets regular data
      await profileDataSource.deleteProfile('student-1');
      profileDataSource.upsertProfile('student-2', {
        'id': 'student-2',
        'full_name': 'Maria Clara',
        'role': 'student',
        'region': 'Region IV-A',
        'gpa': 3.90,
        'year_level': 3,
        'course': 'BS Computer Science',
      });

      authNotifier.signIn('admin-2');
      expect(container.read(currentUserIdProvider), equals('admin-2'));

      // Step D: User A's in-flight request now completes with User A's confidential record
      completerA.complete([
        {
          'id': 'user-a-secret',
          'full_name': 'Confidential User A Profile',
          'role': 'student',
        }
      ]);

      // Step E: Verify User B reads only fresh data, never User A's stale in-flight completion
      final usersB = await container.read(adminUsersProvider.future);
      expect(usersB.any((u) => u.fullName == 'Confidential User A Profile'), isFalse,
          reason: 'In-flight completion for User A must not leak to User B');
      expect(usersB.any((u) => u.fullName == 'Maria Clara'), isTrue,
          reason: 'User B must receive fresh state');
    });

    test('7. Repository failure during auth transition remains AsyncError without uncaught zone errors, and container disposal is safe', () async {
      // Step A: Admin signs in
      authNotifier.signIn('admin-1');

      // Step B: Set up an in-flight completer that will fail
      final failureCompleter = Completer<List<Map<String, dynamic>>>();
      profileDataSource.inFlightCompleter = failureCompleter;

      container.invalidate(adminUsersProvider);
      final asyncBefore = container.read(adminUsersProvider);
      expect(asyncBefore.isLoading, isTrue);

      // Step C: Auth transition occurs while fetch is failing
      authNotifier.signOut();
      expect(container.read(currentUserIdProvider), isNull);

      // Fail the in-flight network request with an exception
      failureCompleter.completeError(Exception('Network connection dropped'));
      profileDataSource.inFlightCompleter = null;

      // Allow microtasks to settle
      await Future<void>.delayed(Duration.zero);

      // Step D: Verify provider safely resolves to empty list on sign-out rather than crashing
      final users = await container.read(adminUsersProvider.future);
      expect(users, isEmpty, reason: 'Provider must resolve to empty on sign-out rather than propagating in-flight error');

      // Step E: Verify repository failure while signed in captures as AsyncError without uncaught zone errors
      authNotifier.signIn('admin-1');
      final failCompleter2 = Completer<List<Map<String, dynamic>>>();
      profileDataSource.inFlightCompleter = failCompleter2;

      container.invalidate(adminUsersProvider);
      final errorFuture = container.read(adminUsersProvider.future);

      failCompleter2.completeError(Exception('Database timeout'));
      profileDataSource.inFlightCompleter = null;

      // The future rejects with the repository exception
      await expectLater(errorFuture, throwsA(isA<Exception>()));

      // And the provider AsyncValue holds AsyncError cleanly
      final errorState = container.read(adminUsersProvider);
      expect(errorState.hasError, isTrue);
      expect(errorState.error.toString(), contains('Database timeout'));

      // Step F: Container disposal is safe even with in-flight failure
      final testContainer = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(() => authNotifier),
          profileRepositoryProvider.overrideWithValue(profileRepo),
        ],
      );
      final hangCompleter = Completer<List<Map<String, dynamic>>>();
      hangCompleter.future.catchError((_) => <Map<String, dynamic>>[]);
      profileDataSource.inFlightCompleter = hangCompleter;
      testContainer.read(adminUsersProvider);

      // Disposing container while in-flight completes safely
      expect(() => testContainer.dispose(), returnsNormally);
      hangCompleter.completeError(Exception('Aborted'));
      profileDataSource.inFlightCompleter = null;
    });
  });
}
