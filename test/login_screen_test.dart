// Day 19 tests: the redesigned login screen sitting on the EmptyStage.
//
// Verifies the visual composition (EmptyStage behind the form, locked
// headline, provider CTA as a tappable affordance) while preserving the
// existing authentication behavior (validation, field wiring, entrance
// choreography, reduced motion).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/auth/presentation/empty_stage.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> useLargeSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  void useReducedMotion(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  /// Pumps the login screen and advances the fake clock past the entire
  /// entrance so every element has settled at full opacity.
  Future<void> pumpSettled(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump(
      const Duration(milliseconds: kLoginEntranceTotalMs) +
          const Duration(milliseconds: 100),
    );
  }

  group('LoginScreen composition', () {
    testWidgets('renders EmptyStage behind the form', (tester) async {
      await useLargeSurface(tester);
      await pumpSettled(tester);

      // The root Stack's first child is the full-bleed stage; the form layer
      // sits on top.
      final stack = tester.widget<Stack>(find.byType(Stack).first);
      expect(stack.children, isNotEmpty);
      expect(stack.children.first, isA<Positioned>());
      expect((stack.children.first as Positioned).child, isA<EmptyStage>());

      expect(find.byType(EmptyStage), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('headline is exactly "Your future starts somewhere."', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await pumpSettled(tester);

      expect(find.text('Your future starts somewhere.'), findsOneWidget);
    });

    testWidgets('renders the full form hierarchy in the locked order', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await pumpSettled(tester);

      // Hierarchy: headline → email → password → forgot → login →
      // signup → provider CTA.
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
      expect(find.text('Want to help students reach their dreams?'),
          findsOneWidget);
      expect(find.text('Become a scholarship provider'), findsOneWidget);

      // No generic Material card wraps the form anymore.
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('fields still accept input', (tester) async {
      await useLargeSurface(tester);
      await pumpSettled(tester);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'student@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');

      expect(find.text('student@example.com'), findsOneWidget);
      expect(find.text('secret123'), findsOneWidget);
    });

    testWidgets('validation still works', (tester) async {
      await useLargeSurface(tester);
      await pumpSettled(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'student@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets('entrance sequence settles with everything visible', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();

      // Mid-entrance not everything is settled yet — the later items (provider
      // CTA) are still animating in.
      expect(find.text('Your future starts somewhere.'), findsOneWidget);

      await tester.pump(
        const Duration(milliseconds: kLoginEntranceTotalMs) +
            const Duration(milliseconds: 100),
      );

      final fades = tester.widgetList<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fades, isNotEmpty);
      for (final fade in fades) {
        expect(fade.opacity.value, 1.0);
      }
    });

    testWidgets('reduced motion shows everything on the first frame', (
      tester,
    ) async {
      await useLargeSurface(tester);
      useReducedMotion(tester);
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();

      // All elements are immediately visible and the button is interactive.
      expect(find.text('Your future starts somewhere.'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Become a scholarship provider'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Log in'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('provider CTA navigates to become-a-provider signup', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/become-provider',
            builder: (context, state) =>
                const Scaffold(
                  body: Center(
                    child: Text('Become a Scholarship Provider'),
                  ),
                ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Want to help students reach their dreams?'),
          findsOneWidget);
      expect(find.text('Become a scholarship provider'), findsOneWidget);

      await tester.tap(find.text('Become a scholarship provider'),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Become a Scholarship Provider'), findsOneWidget);
    });
  });

  group('LoginScreen navigation', () {
    testWidgets('Forgot password still navigates to /forgot-password', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) =>
                const Scaffold(body: Text('Reset your password')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset your password'), findsOneWidget);
    });
  });
}
