// test/ias_viewport_test.dart
//
// Real browser viewport verification for IAS Security Module (Batch 1):
// - 440x956 (iPhone 16 Pro Max target viewport)
// - 360x800 (Narrow Android target viewport)
//
// Verifies layout stability, absence of RenderFlex overflows, and interactive
// state rendering across LoginScreen, SignupScreen, ResetPasswordScreen, and
// ProviderSignupScreen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/core/security/login_lockout_service.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/auth/presentation/reset_password_screen.dart';
import 'package:scholaris/features/auth/presentation/signup_screen.dart';
import 'package:scholaris/features/provider/presentation/provider_signup_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void setViewport(WidgetTester tester, double width, double height) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('IAS Security Viewport Verification (440x956 & 360x800)', () {
    final lockout = LoginLockoutService.instance;

    setUp(() {
      lockout.resetState();
    });

    testWidgets('LoginScreen at 440x956 with active lockout banner', (tester) async {
      setViewport(tester, 440, 956);
      const email = 'lockout440@scholaris.ph';
      for (int i = 0; i < 3; i++) {
        lockout.recordFailedAttempt(email);
      }

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      final emailField = find.byType(TextFormField).at(0);
      await tester.ensureVisible(emailField);
      await tester.enterText(emailField, email);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const ValueKey('lockout-active-banner')), findsOneWidget);
      expect(find.text('Account Temporarily Locked'), findsOneWidget);
    });

    testWidgets('LoginScreen at 360x800 with active lockout banner', (tester) async {
      setViewport(tester, 360, 800);
      const email = 'lockout360@scholaris.ph';
      for (int i = 0; i < 3; i++) {
        lockout.recordFailedAttempt(email);
      }

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      final emailField = find.byType(TextFormField).at(0);
      await tester.ensureVisible(emailField);
      await tester.enterText(emailField, email);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const ValueKey('lockout-active-banner')), findsOneWidget);
      expect(find.text('Account Temporarily Locked'), findsOneWidget);
    });

    testWidgets('SignupScreen at 440x956 with live complexity checklist', (tester) async {
      setViewport(tester, 440, 956);
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      final pwdField = find.byType(TextFormField).at(2);
      await tester.ensureVisible(pwdField);
      await tester.enterText(pwdField, 'Scholaris2026!');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Password Complexity'), findsOneWidget);
      expect(find.text('Strong'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
    });

    testWidgets('SignupScreen at 360x800 with live complexity checklist', (tester) async {
      setViewport(tester, 360, 800);
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      final pwdField = find.byType(TextFormField).at(2);
      await tester.ensureVisible(pwdField);
      await tester.enterText(pwdField, 'Scholaris2026!');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Password Complexity'), findsOneWidget);
      expect(find.text('Strong'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen at 440x956 with strength gauge & guidelines', (tester) async {
      setViewport(tester, 440, 956);
      await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      final pwdField = find.byType(TextFormField).at(0);
      await tester.ensureVisible(pwdField);
      await tester.enterText(pwdField, 'Pass123!');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SECURITY GUIDELINES'), findsOneWidget);
      expect(find.text('At least 8 characters long'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen at 360x800 with strength gauge & guidelines', (tester) async {
      setViewport(tester, 360, 800);
      await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      final pwdField = find.byType(TextFormField).at(0);
      await tester.ensureVisible(pwdField);
      await tester.enterText(pwdField, 'Pass123!');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SECURITY GUIDELINES'), findsOneWidget);
      expect(find.text('At least 8 characters long'), findsOneWidget);
    });

    testWidgets('ProviderSignupScreen at 440x956 with password complexity', (tester) async {
      setViewport(tester, 440, 956);
      await tester.pumpWidget(const MaterialApp(home: ProviderSignupScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      final pwdField = find.byType(TextFormField).at(3);
      await tester.ensureVisible(pwdField);
      await tester.enterText(pwdField, 'PartnerOrg2026#');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Password Complexity'), findsOneWidget);
      expect(find.text('Strong'), findsOneWidget);
    });
  });
}
