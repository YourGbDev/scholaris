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
import 'package:scholaris/features/auth/presentation/match_hero.dart';
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

  /// Pumps the intro through the entrance and the Lottie match hero so the
  /// matching timeline has just been released. Returns with the matching
  /// timeline at ~0ms (its first tick has established the ticker start time).
  Future<void> pumpThroughHero(WidgetTester tester) async {
    await tester.pumpWidget(introHarness());
    await tester.pump();
    // Branding entrance settles first.
    await tester.pump(const Duration(milliseconds: kIntroEntranceTotalMs));
    // The hero only begins after the entrance is ready.
    await tester.pump();
    // Hero plays its full natural Lottie duration.
    await tester.pump(const Duration(milliseconds: kMatchHeroDurationMs));
    // Hero completion is delivered post-frame, then _matching.forward() is
    // deferred via a microtask, so two flush frames hand control over.
    await tester.pump();
    await tester.pump();
  }

  /// Advances [ms] of fake time in fixed small steps. The matching ticker (and
  /// the Lottie ticker) only make progress when frames are pumped individually,
  /// so a single large pump would leave the controller at its start value.
  Future<void> pumpSteps(
    WidgetTester tester,
    int ms, {
    int stepMs = 200,
  }) async {
    var remaining = ms;
    while (remaining > 0) {
      final step = remaining < stepMs ? remaining : stepMs;
      await tester.pump(Duration(milliseconds: step));
      remaining -= step;
    }
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
      await pumpThroughHero(tester);

      // The hero gates the matching timeline: nothing reveals until it has
      // completed. Just past the first reveal point: one opportunity visible.
      await pumpSteps(tester, 1500);
      expect(find.text('STEM Futures Grant'), findsOneWidget);
      expect(find.text('Luzon Merit Scholarship'), findsNothing);

      // Past the last reveal point: all three cards visible.
      await pumpSteps(tester, 2000);
      expect(find.text('STEM Futures Grant'), findsOneWidget);
      expect(find.text('Luzon Merit Scholarship'), findsOneWidget);
      expect(find.text('Future Educators Fund'), findsOneWidget);
      expect(find.text('Matching your academics…'), findsNothing);

      // Timeline complete: the final summary replaces the progress status.
      await pumpSteps(tester, 1500);
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
        // is gated to start only after the hero completes, and the CTA is the
        // reward at the end of that sequence, so it must stay gated until both
        // the hero and the matching timeline have finished.
        await tester.pump(const Duration(milliseconds: kIntroEntranceTotalMs));
        await tester.pump(); // flush hero start
        await tester.pump(const Duration(milliseconds: kMatchHeroDurationMs));
        await tester.pump(); // hero completion → post-frame onCompleted
        await tester.pump(); // microtask → matching.forward()
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Get started'),
              )
              .onPressed,
          isNull,
          reason: 'the CTA must wait for the matching sequence after the hero, not just the entrance',
        );

        // Run the matching timeline past the CTA reveal so it resolves.
        await pumpSteps(tester, 4200);

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

      // Branding entrance settles first; the hero plays its Lottie once, then
      // the matching timeline begins.
      await tester.pump(const Duration(milliseconds: kIntroEntranceTotalMs));
      await tester.pump(); // flush hero start
      await tester.pump(const Duration(milliseconds: kMatchHeroDurationMs));
      await tester
          .pump(); // flush hero completion → matching.forward() scheduled
      await tester.pump(); // matching.forward() executes, ticker arms

      expect(find.text('Reading your profile…'), findsOneWidget);

      // Past the first reveal point and the AnimatedSwitcher settle window:
      // the matching status is shown and the previous one is gone. Pump in
      // small steps so the matching ticker actually advances.
      await pumpSteps(tester, 1500);
      expect(find.text('Matching your academics…'), findsOneWidget);
      expect(find.text('Reading your profile…'), findsNothing);

      // Timeline complete: the final summary replaces the ranking status.
      await pumpSteps(tester, 2700);
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

  group('MatchHero', () {
    testWidgets('plays once and reports completion at its natural duration', (
      tester,
    ) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchHero(start: true, onCompleted: () => completed++),
          ),
        ),
      );
      await tester.pump(); // first frame; asset load starts
      await tester.pump(); // composition resolves and playback begins
      expect(completed, 0, reason: 'completion must wait for playback');

      // Pump in small steps so the Lottie ticker actually advances.
      await pumpSteps(tester, kMatchHeroDurationMs + 200);
      await tester.pump(); // post-frame delivery of onCompleted
      expect(completed, 1);

      // No Lottie, no settle: the hero is rendered by the Lottie asset.
      expect(find.byType(MatchHero), findsOneWidget);
    });

    testWidgets('reduced motion settles immediately into the settled state', (
      tester,
    ) async {
      useReducedMotion(tester);
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchHero(start: true, onCompleted: () => completed++),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(completed, 1, reason: 'reduced motion must not animate the hero');
      // The native settled state (graduation cap + check) is shown.
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('falls back to the native settled state when the asset fails', (
      tester,
    ) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchHero(
              start: true,
              assetPath: 'assets/animations/does_not_exist.json',
              onCompleted: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(); // errorBuilder fires and schedules onCompleted
      await tester.pump(); // post-frame delivery of onCompleted

      expect(completed, 1, reason: 'the flow must continue on asset failure');
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
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
