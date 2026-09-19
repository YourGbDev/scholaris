// test/ias_security_test.dart
//
// IAS Module Security and Audit Unit Tests:
// - Password complexity rules (min 8 chars, uppercase, lowercase, number, special char).
// - Confirm password validation.
// - Progressive account lockout (3 failed: 5m, 4 failed: 15m, 5+ failed: 60m).
// - Audit logging event trail.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholaris/core/security/login_lockout_service.dart';
import 'package:scholaris/core/security/password_validator.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/auth/presentation/reset_password_screen.dart';
import 'package:scholaris/features/auth/presentation/signup_screen.dart';

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
}
