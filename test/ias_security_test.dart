// test/ias_security_test.dart
//
// IAS Module Security and Audit Unit Tests:
// - Password complexity rules (min 8 chars, uppercase, lowercase, number, special char).
// - Confirm password validation.
// - Progressive account lockout (3 failed: 5m, 4 failed: 15m, 5+ failed: 60m).
// - Audit logging event trail.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scholaris/core/security/login_lockout_service.dart';
import 'package:scholaris/core/security/password_validator.dart';
import 'package:scholaris/features/account/repositories/account_repository.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/auth/presentation/reset_password_screen.dart';
import 'package:scholaris/features/auth/presentation/signup_screen.dart';

class _MockAuthHttpClient extends http.BaseClient {
  final List<http.BaseRequest> requests = [];
  bool failSignOut = false;
  bool failUpdateUser = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final path = request.url.path;

    if (path.contains('/auth/v1/token')) {
      final sessionJson = jsonEncode({
        'access_token': 'mock.jwt.token',
        'token_type': 'bearer',
        'expires_in': 3600,
        'refresh_token': 'mock-refresh-token',
        'user': {
          'id': 'test-user-uuid',
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': 'student@scholaris.ph',
          'app_metadata': {'provider': 'email'},
          'user_metadata': {},
          'created_at': '2026-01-01T00:00:00Z',
        },
      });
      return http.StreamedResponse(
        Stream.value(utf8.encode(sessionJson)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.contains('/auth/v1/user')) {
      if (failUpdateUser) {
        final body = jsonEncode({'message': 'Failed user update', 'code': 400});
        return http.StreamedResponse(
          Stream.value(utf8.encode(body)),
          400,
          headers: {'content-type': 'application/json'},
        );
      }
      final userJson = jsonEncode({
        'id': 'test-user-uuid',
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'student@scholaris.ph',
        'app_metadata': {'provider': 'email'},
        'user_metadata': {},
        'created_at': '2026-01-01T00:00:00Z',
      });
      return http.StreamedResponse(
        Stream.value(utf8.encode(userJson)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.contains('/auth/v1/logout')) {
      if (failSignOut) {
        final body = jsonEncode({'message': 'Network timeout during revocation', 'code': 504});
        return http.StreamedResponse(
          Stream.value(utf8.encode(body)),
          504,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.StreamedResponse(
        Stream.value(utf8.encode('{}')),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode('{}')),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  group('IAS Password Validation', () {
    test('rejects empty password', () {
      expect(PasswordValidator.validatePassword(''), 'Enter a password.');
      expect(PasswordValidator.validatePassword(null), 'Enter a password.');
    });

    test('rejects short passwords (< 8 chars)', () {
      expect(PasswordValidator.validatePassword('Pass1!'),
          'Password must be at least 8 characters.');
    });

    test('rejects passwords missing required character classes', () {
      // Missing special char
      expect(
        PasswordValidator.validatePassword('Password123'),
        'Password must include uppercase, lowercase, number, and special character.',
      );
      // Missing uppercase
      expect(
        PasswordValidator.validatePassword('password123!'),
        'Password must include uppercase, lowercase, number, and special character.',
      );
      // Missing lowercase
      expect(
        PasswordValidator.validatePassword('PASSWORD123!'),
        'Password must include uppercase, lowercase, number, and special character.',
      );
      // Missing number
      expect(
        PasswordValidator.validatePassword('Password!@#'),
        'Password must include uppercase, lowercase, number, and special character.',
      );
    });

    test('accepts valid complex passwords', () {
      expect(PasswordValidator.validatePassword('Scholaris2026!'), isNull);
      expect(PasswordValidator.validatePassword('Admin@Pass123'), isNull);
      expect(PasswordValidator.validatePassword('P@ssw0rd!#\$'), isNull);
    });

    test('confirm password validation', () {
      expect(PasswordValidator.validateConfirmPassword('', 'Pass123!'),
          'Confirm your password.');
      expect(PasswordValidator.validateConfirmPassword('Different', 'Pass123!'),
          'Passwords do not match.');
      expect(PasswordValidator.validateConfirmPassword('Pass123!', 'Pass123!'),
          isNull);
    });
  });

  group('IAS Account Lockout & Backoff', () {
    final lockout = LoginLockoutService.instance;

    setUp(() {
      lockout.resetState();
    });

    test('1 and 2 failed attempts do not lock out account', () {
      const email = 'user@example.com';
      var status = lockout.recordFailedAttempt(email);
      expect(status.isLocked, isFalse);
      expect(status.failedAttempts, 1);

      status = lockout.recordFailedAttempt(email);
      expect(status.isLocked, isFalse);
      expect(status.failedAttempts, 2);
    });

    test('3 failed attempts triggers 5-minute lockout', () {
      const email = 'locked5m@example.com';
      lockout.recordFailedAttempt(email);
      lockout.recordFailedAttempt(email);
      final status = lockout.recordFailedAttempt(email);

      expect(status.isLocked, isTrue);
      expect(status.failedAttempts, 3);
      expect(status.remainingTime.inMinutes, 5);
      expect(status.lockoutMessage, contains('5m'));
    });

    test('4 failed attempts triggers 15-minute lockout', () {
      const email = 'locked15m@example.com';
      for (int i = 0; i < 3; i++) {
        lockout.recordFailedAttempt(email);
      }
      final status = lockout.recordFailedAttempt(email);

      expect(status.isLocked, isTrue);
      expect(status.failedAttempts, 4);
      expect(status.remainingTime.inMinutes, 15);
      expect(status.lockoutMessage, contains('15m'));
    });

    test('5+ failed attempts triggers 60-minute lockout', () {
      const email = 'locked60m@example.com';
      for (int i = 0; i < 4; i++) {
        lockout.recordFailedAttempt(email);
      }
      final status = lockout.recordFailedAttempt(email);

      expect(status.isLocked, isTrue);
      expect(status.failedAttempts, 5);
      expect(status.remainingTime.inMinutes, 60);
      expect(status.lockoutMessage, contains('60m'));
    });

    test('successful login resets failed attempts', () {
      const email = 'reset@example.com';
      lockout.recordFailedAttempt(email);
      lockout.recordFailedAttempt(email);
      expect(lockout.checkLockout(email).failedAttempts, 2);

      lockout.recordSuccessfulLogin(email);
      final check = lockout.checkLockout(email);
      expect(check.isLocked, isFalse);
      expect(check.failedAttempts, 0);
    });
  });

  group('IAS Audit Ledger Logging', () {
    final lockout = LoginLockoutService.instance;

    setUp(() {
      lockout.resetState();
    });

    test('records audit log events into memory ledger', () async {
      await lockout.logAuditEvent(
        action: 'user_created',
        targetType: 'user',
        targetId: 'usr-123',
        actorEmail: 'admin@scholaris.ph',
        actorRole: 'admin',
        details: {'role': 'student', 'name': 'Juan Dela Cruz'},
      );

      final logs = lockout.inMemoryAuditLogs;
      expect(logs.length, 1);
      expect(logs.first['action'], 'user_created');
      expect(logs.first['target_id'], 'usr-123');
      expect(logs.first['actor_role'], 'admin');
    });
  });

  group('IAS UI Security Integration Tests', () {
    final lockout = LoginLockoutService.instance;

    setUp(() {
      lockout.resetState();
    });

    testWidgets('LoginScreen displays lockout banner and disables button when locked',
        (tester) async {
      const email = 'locked@example.com';
      for (int i = 0; i < 3; i++) {
        lockout.recordFailedAttempt(email);
      }
      expect(lockout.checkLockout(email).isLocked, isTrue);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, email);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('lockout-active-banner')), findsOneWidget);
      expect(find.text('Account Temporarily Locked'), findsOneWidget);
      expect(find.text('Account Locked'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('LoginScreen displays warning banner on 1 or 2 failed attempts',
        (tester) async {
      const email = 'warn@example.com';
      lockout.recordFailedAttempt(email);
      expect(lockout.checkLockout(email).failedAttempts, 1);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, email);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('lockout-warning-banner')), findsOneWidget);
      expect(find.textContaining('Security Notice: 1 failed login attempt'), findsOneWidget);
    });

    testWidgets('SignupScreen renders password complexity checklist and indicators',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Password Complexity'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('Uppercase & lowercase letters'), findsOneWidget);
      expect(find.text('At least one number (0-9)'), findsOneWidget);
      expect(find.text('Special character (!@#\$%^&*)'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen renders 4-point requirement guidelines matching PasswordValidator',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SECURITY GUIDELINES'), findsOneWidget);
      expect(find.text('At least 8 characters long'), findsOneWidget);
      expect(find.text('Uppercase & lowercase letters'), findsOneWidget);
      expect(find.text('Includes at least one number (0-9)'), findsOneWidget);
      expect(find.text('Special character (!@#\$%^&*)'), findsOneWidget);
    });

    testWidgets('LoginScreen warning banner handles expired lockout without negative remaining count',
        (tester) async {
      const email = 'warn2@example.com';
      lockout.recordFailedAttempt(email);
      lockout.recordFailedAttempt(email);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, email);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('lockout-warning-banner')), findsOneWidget);
      expect(
        find.textContaining('1 attempt remaining before temporary account lockout'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('lockout-warning-banner')),
          matching: find.textContaining('-'),
        ),
        findsNothing,
      );
    });
  });

  group('IAS Section C4: Session Invalidation on Password Update', () {
    late _MockAuthHttpClient mockHttp;
    late SupabaseAccountDataSource dataSource;

    setUp(() async {
      mockHttp = _MockAuthHttpClient();
      try {
        await Supabase.instance.dispose();
      } catch (_) {}
      await Supabase.initialize(
        url: 'https://mock-ias.supabase.co',
        publishableKey: 'mock-anon-key',
        httpClient: mockHttp,
      );
      await Supabase.instance.client.auth.setSession('mock-refresh-token');
      dataSource = SupabaseAccountDataSource();
    });

    tearDown(() async {
      try {
        await Supabase.instance.dispose();
      } catch (_) {}
    });

    test('updatePassword invokes updateUser and revokes other sessions via SignOutScope.others', () async {
      await dataSource.updatePassword(newPassword: 'Scholaris2026!#');

      final userReq = mockHttp.requests.firstWhere(
        (r) => r.url.path.contains('/auth/v1/user'),
      );
      expect(userReq.method, 'PUT');

      final logoutReq = mockHttp.requests.firstWhere(
        (r) => r.url.path.contains('/auth/v1/logout'),
      );
      expect(logoutReq.method, 'POST');
      expect(logoutReq.url.queryParameters['scope'], 'others');
    });

    test('updatePassword handles session revocation failure non-fatally without throwing', () async {
      mockHttp.failSignOut = true;

      await expectLater(
        dataSource.updatePassword(newPassword: 'ComplexPassword2026!'),
        completes,
      );

      final logoutReq = mockHttp.requests.firstWhere(
        (r) => r.url.path.contains('/auth/v1/logout'),
      );
      expect(logoutReq.url.queryParameters['scope'], 'others');
    });

    test('updatePassword propagates primary updateUser failure without attempting revocation', () async {
      mockHttp.failUpdateUser = true;

      await expectLater(
        dataSource.updatePassword(newPassword: 'FailedPassword2026!'),
        throwsA(isA<AuthException>()),
      );

      final logoutRequests = mockHttp.requests.where(
        (r) => r.url.path.contains('/auth/v1/logout'),
      );
      expect(logoutRequests, isEmpty);
    });

    test('AccountRepository.changePassword re-authenticates and revokes other sessions', () async {
      final repository = AccountRepository(
        dataSource: dataSource,
        currentUserId: () => 'test-user-uuid',
        currentUserEmail: () => 'student@scholaris.ph',
      );

      final result = await repository.changePassword(
        currentPassword: 'CurrentPassword2026!',
        newPassword: 'NewComplexPassword2026!',
      );

      expect(result, isTrue);
      expect(repository.lastRevocationSucceeded, isTrue);

      final userReq = mockHttp.requests.firstWhere(
        (r) => r.url.path.contains('/auth/v1/user'),
      );
      expect(userReq.method, 'PUT');

      final logoutReq = mockHttp.requests.firstWhere(
        (r) => r.url.path.contains('/auth/v1/logout'),
      );
      expect(logoutReq.method, 'POST');
      expect(logoutReq.url.queryParameters['scope'], 'others');
    });

    test('AccountRepository.changePassword succeeds and honestly reports false when revocation fails', () async {
      mockHttp.failSignOut = true;

      final repository = AccountRepository(
        dataSource: dataSource,
        currentUserId: () => 'test-user-uuid',
        currentUserEmail: () => 'student@scholaris.ph',
      );

      final result = await repository.changePassword(
        currentPassword: 'CurrentPassword2026!',
        newPassword: 'NewComplexPassword2026!',
      );

      // Primary password change succeeds
      expect(result, isFalse);
      expect(repository.lastRevocationSucceeded, isFalse);
      expect(dataSource.lastRevocationSucceeded, isFalse);

      final userReq = mockHttp.requests.firstWhere(
        (r) => r.url.path.contains('/auth/v1/user'),
      );
      expect(userReq.method, 'PUT');

      final logoutReq = mockHttp.requests.firstWhere(
        (r) => r.url.path.contains('/auth/v1/logout'),
      );
      expect(logoutReq.method, 'POST');
      expect(logoutReq.url.queryParameters['scope'], 'others');
    });

    test('AccountRepository.changePassword halts before update and revocation when re-authentication fails', () async {
      mockHttp.requests.clear();
      // Test when currentUser is not authenticated
      final unauthenticatedRepo = AccountRepository(
        dataSource: dataSource,
        currentUserId: () => null,
        currentUserEmail: () => null,
      );

      await expectLater(
        unauthenticatedRepo.changePassword(
          currentPassword: 'WrongPassword!',
          newPassword: 'NewPassword123!',
        ),
        throwsA(isA<AccountNotAuthenticatedException>()),
      );

      final userRequests = mockHttp.requests.where(
        (r) => r.url.path.contains('/auth/v1/user'),
      );
      expect(userRequests, isEmpty);

      final logoutRequests = mockHttp.requests.where(
        (r) => r.url.path.contains('/auth/v1/logout'),
      );
      expect(logoutRequests, isEmpty);
    });

    testWidgets('ResetPasswordScreen._onSubmit updates password and revokes other sessions via SignOutScope.others',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'Scholaris2026!#');
      await tester.enterText(textFields.at(1), 'Scholaris2026!#');
      await tester.pump();

      expect(find.text('Passwords match'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      final updateBtn = find.widgetWithText(ElevatedButton, 'Reset Password');
      expect(updateBtn, findsOneWidget);

      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      final userReq = mockHttp.requests.firstWhere(
        (r) => r.url.path.contains('/auth/v1/user'),
      );
      expect(userReq.method, 'PUT');

      final logoutReq = mockHttp.requests.firstWhere(
        (r) => r.url.path.contains('/auth/v1/logout'),
      );
      expect(logoutReq.method, 'POST');
      expect(logoutReq.url.queryParameters['scope'], 'others');
    });

    testWidgets('ResetPasswordScreen._onSubmit handles revocation failure non-fatally and completes password update',
        (tester) async {
      mockHttp.failSignOut = true;
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Scholaris2026!#');
      await tester.enterText(textFields.at(1), 'Scholaris2026!#');
      await tester.pump();

      final updateBtn = find.widgetWithText(ElevatedButton, 'Reset Password');
      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pump();

      // Verify primary update was dispatched and committed
      final userReq = mockHttp.requests.firstWhere(
        (r) => r.url.path.contains('/auth/v1/user'),
      );
      expect(userReq.method, 'PUT');

      // Verify revocation was attempted via SignOutScope.others
      final logoutReq = mockHttp.requests.firstWhere(
        (r) => r.url.path.contains('/auth/v1/logout'),
      );
      expect(logoutReq.method, 'POST');
      expect(logoutReq.url.queryParameters['scope'], 'others');

      // Pump through SuccessOverlay duration (auto-dismiss)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify visible warning SnackBar is surfaced honestly when revocation fails
      expect(
        find.textContaining('Other active sessions could not be signed out'),
        findsOneWidget,
      );
    });

    testWidgets('ResetPasswordScreen._onSubmit primary update failure shows error, no success overlay, and skips revocation',
        (tester) async {
      mockHttp.failUpdateUser = true;
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Scholaris2026!#');
      await tester.enterText(textFields.at(1), 'Scholaris2026!#');
      await tester.pump();

      final updateBtn = find.widgetWithText(ElevatedButton, 'Reset Password');
      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // Zero logout requests dispatched
      final logoutRequests = mockHttp.requests.where(
        (r) => r.url.path.contains('/auth/v1/logout'),
      );
      expect(logoutRequests, isEmpty);

      // Warning snackbar is never shown
      expect(
        find.textContaining('Other active sessions could not be signed out'),
        findsNothing,
      );

      // Friendly error message appears in snackbar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Failed user update'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen reactive password-match indicators at 360x800 standard text',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Scholaris2026!#');
      await tester.enterText(textFields.at(1), 'Scholaris2026!#');
      await tester.pump();

      // Verify match indicator is reactive and visible
      expect(find.text('Passwords match'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
