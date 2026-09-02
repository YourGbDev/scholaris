// Day 16-17 tests: entrance motion toolkit, the intro screen (staggered brand
// entrance, sequential card reveals, narrated status transitions, end-of-
// sequence CTA lifecycle), the login screen's staggered entrance, and the
// /intro redirect decisions.
//
// All animation here is native Flutter (AnimationController + intervals), so
// tests can pump the virtual clock deterministically. Reduced-motion cases
// use FakeAccessibilityFeatures(disableAnimations: true) to prove the
// animation layer never blocks reaching the UI.
//
// No network is involved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/auth/presentation/intro_screen.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/shared/widgets/entrance.dart';

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

  /// Router harness mirroring the real app wiring: /intro is the start and
  /// /login is reachable through the CTA.
  Widget introHarness() {
    final router = GoRouter(
      initialLocation: '/intro',
      routes: [
        GoRoute(
          path: '/intro',
          builder: (context, state) => const IntroScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('StaggeredEntrance', () {
    testWidgets('staggered items all settle at full opacity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredEntrance(
              children: const [Text('first'), Text('second'), Text('third')],
            ),
          ),
        ),
      );

      await tester.pump(
        EntranceMotion.total + const Duration(milliseconds: 100),
      );

      final fades = tester.widgetList<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fades, isNotEmpty);
      for (final fade in fades) {
        expect(fade.opacity.value, 1.0);
      }
      expect(find.text('first'), findsOneWidget);
      expect(find.text('third'), findsOneWidget);
    });

    testWidgets('reduced motion renders the settled state on the first frame', (
      tester,
    ) async {
      useReducedMotion(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredEntrance(
              children: const [Text('first'), Text('second')],
            ),
          ),
        ),
      );
      // A single frame: the controller never runs, content is fully visible.
      await tester.pump();

      final fades = tester.widgetList<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fades, isNotEmpty);
      for (final fade in fades) {
        expect(fade.opacity.value, 1.0);
      }
    });
  });

  group('IntroScreen', () {
    testWidgets('renders brand, story copy, CTA and matching preview', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await tester.pumpWidget(introHarness());
      await tester.pump();

      expect(find.text('Scholaris'), findsOneWidget);
      expect(find.text('Find scholarships that fit you'), findsOneWidget);
      expect(find.text('Reading your profile…'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      // Nothing is revealed while the timeline is still in stage 0.
      expect(find.text('STEM Futures Grant'), findsNothing);
    });

    testWidgets('matching timeline resolves skeletons into opportunities', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await tester.pumpWidget(introHarness());
      await tester.pump();

      // The branding entrance (logo → wordmark → tagline → story → preview)
      // resolves first; only then does the matching timeline begin, so branding
      // and matching never overlap.
      await tester.pump(const Duration(milliseconds: kIntroEntranceTotalMs));

      // Just past the first reveal point: one opportunity visible.
      await tester.pump(const Duration(milliseconds: 750));
      expect(find.text('STEM Futures Grant'), findsOneWidget);
      expect(find.text('Luzon Merit Scholarship'), findsNothing);

      // Past the last reveal point but before completion: all three cards.
      await tester.pump(const Duration(milliseconds: 2100));
      expect(find.text('STEM Futures Grant'), findsOneWidget);
      expect(find.text('Luzon Merit Scholarship'), findsOneWidget);
      expect(find.text('Future Educators Fund'), findsOneWidget);
      expect(find.text('Matching your academics…'), findsNothing);

      // Timeline complete: the final summary replaces the progress status.
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.text('12 scholarships fit you'), findsOneWidget);
      expect(find.text('94%'), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);
    });

    testWidgets(
      'CTA stays gated until the matching sequence settles, then navigates',
      (tester) async {
        await useLargeSurface(tester);
        await tester.pumpWidget(introHarness());
        await tester.pump();

        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Get started'),
              )
              .onPressed,
          isNull,
          reason: 'the CTA must not be tappable mid-entrance',
        );

        // The entrance settling is no longer sufficient: the matching timeline
        // is gated to start only after the branding entrance settles, and the
        // CTA is the reward at the end of that sequence, so it must stay gated
        // until the timeline has finished.
        await tester.pump(const Duration(milliseconds: kIntroEntranceTotalMs));
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Get started'),
              )
              .onPressed,
          isNull,
          reason: 'the CTA must wait for the matching sequence, not just the entrance',
        );

        // Run the matching timeline past the CTA reveal so it resolves.
        await tester.pump(const Duration(milliseconds: 3600));

        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Get started'),
              )
              .onPressed,
          isNotNull,
          reason: 'the CTA becomes tappable once the matching sequence settles',
        );

        await tester.tap(find.text('Get started'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Welcome back'), findsOneWidget);
        expect(find.text('Log in'), findsOneWidget);
        // The Hero logo made it to the login screen (flight completed).
        expect(find.byType(Hero), findsOneWidget);
      },
    );

    testWidgets('status text transitions through distinct narrated stages', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await tester.pumpWidget(introHarness());
      await tester.pump();

      // Branding entrance settles first; the matching timeline starts in its
      // reading stage only after the entrance has fully resolved.
      await tester.pump(const Duration(milliseconds: kIntroEntranceTotalMs));
      expect(find.text('Reading your profile…'), findsOneWidget);

      // Past the first reveal point and the AnimatedSwitcher settle window:
      // the matching status is shown and the previous one is gone.
      await tester.pump(const Duration(milliseconds: 1050));
      expect(find.text('Matching your academics…'), findsOneWidget);
      expect(find.text('Reading your profile…'), findsNothing);

      // Timeline complete: the final summary replaces the ranking status.
      await tester.pump(const Duration(milliseconds: 3200));
      expect(find.text('12 scholarships fit you'), findsOneWidget);
      expect(find.text('Ranking opportunities…'), findsNothing);
    });

    testWidgets('reduced motion shows the settled intro immediately', (
      tester,
    ) async {
      await useLargeSurface(tester);
      useReducedMotion(tester);
      await tester.pumpWidget(introHarness());
      await tester.pump();

      // Matching timeline skipped to its end state.
      expect(find.text('12 scholarships fit you'), findsOneWidget);
      expect(find.text('STEM Futures Grant'), findsOneWidget);
      expect(find.text('Future Educators Fund'), findsOneWidget);
      // CTA enabled on the first frame.
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Get started'),
            )
            .onPressed,
        isNotNull,
      );
    });
  });

  group('LoginScreen entrance', () {
    testWidgets('renders the full form after the entrance settles', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump(
        EntranceMotion.total + const Duration(milliseconds: 100),
      );

      expect(find.text('Scholaris'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
    });

    testWidgets('reduced motion keeps the form immediately interactive', (
      tester,
    ) async {
      useReducedMotion(tester);
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email.'), findsOneWidget);
    });
  });

  group('authRedirectDecision: /intro', () {
    test('signed-out users may stay on /intro', () {
      expect(
        authRedirectDecision(
          location: '/intro',
          isLoggedIn: false,
          recoveryActive: false,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: false,
        ),
        isNull,
      );
    });

    test('signed-out users elsewhere are still sent to /login', () {
      expect(
        authRedirectDecision(
          location: '/home',
          isLoggedIn: false,
          recoveryActive: false,
          onAuthRoute: false,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: false,
        ),
        '/login',
      );
    });

    test('signed-in users never linger on /intro', () {
      // Profile complete → straight to home.
      expect(
        authRedirectDecision(
          location: '/intro',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: true,
        ),
        '/home',
      );
      // Profile still loading → holding room, never the intro.
      expect(
        authRedirectDecision(
          location: '/intro',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: true,
          profileComplete: false,
        ),
        '/splash',
      );
      // Incomplete profile → onboarding, never the intro.
      expect(
        authRedirectDecision(
          location: '/intro',
          isLoggedIn: true,
          recoveryActive: false,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: false,
        ),
        '/profile-setup/personal',
      );
    });

    test('an active recovery session still wins from /intro', () {
      expect(
        authRedirectDecision(
          location: '/intro',
          isLoggedIn: true,
          recoveryActive: true,
          onAuthRoute: true,
          onSetupRoute: false,
          profileLoading: false,
          profileComplete: true,
        ),
        '/reset-password',
      );
    });
  });
}
