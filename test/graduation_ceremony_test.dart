// Day 19 tests: the GraduationCeremony widget lifecycle and the CeremonyScreen
// navigation hand-off. The ceremony Lottie asset (scholaris_ceremony.json — a
// minimal placeholder for build/test) is bundled, but tests also inject
// alternate or nonexistent paths to exercise failure paths.
//
// No network is involved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/auth/presentation/ceremony_screen.dart';
import 'package:scholaris/features/auth/presentation/graduation_ceremony.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void useReducedMotion(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  /// Advances [ms] of fake time in fixed small steps so the Lottie ticker
  /// actually makes progress.
  Future<void> pumpSteps(WidgetTester tester, int ms,
      {int stepMs = 200}) async {
    var remaining = ms;
    while (remaining > 0) {
      final step = remaining < stepMs ? remaining : stepMs;
      await tester.pump(Duration(milliseconds: step));
      remaining -= step;
    }
  }

  group('GraduationCeremony', () {
    testWidgets('plays once and reports completion at its natural duration', (
      tester,
    ) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraduationCeremony(
              assetPath: kCeremonyAsset,
              onCompleted: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(); // first frame; asset load starts
      await tester.pump(); // composition resolves and playback begins
      expect(completed, 0, reason: 'completion must wait for playback');

      // Pump in small steps so the Lottie ticker actually advances.
      await pumpSteps(tester, kCeremonyDurationMs + 500);
      await tester.pump(); // post-frame delivery of onCompleted
      expect(completed, 1);
    });

    testWidgets('completion fires exactly once', (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraduationCeremony(onCompleted: () => completed++),
          ),
        ),
      );
      await tester.pump(); // load starts
      await tester.pump(); // composition resolves
      await pumpSteps(tester, kCeremonyDurationMs + 500);
      await tester.pump(); // post-frame delivery
      expect(completed, 1);

      // Pump more time — completion must not fire again.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(completed, 1);
    });

    testWidgets('reduced motion skips playback and completes immediately', (
      tester,
    ) async {
      useReducedMotion(tester);
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraduationCeremony(onCompleted: () => completed++),
          ),
        ),
      );
      // didChangeDependencies fires and schedules post-frame completion.
      await tester.pump();
      await tester.pump();

      expect(completed, 1, reason: 'reduced motion must not play the ceremony');
    });

    testWidgets('asset failure completes without a fallback', (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraduationCeremony(
              assetPath: 'assets/animations/does_not_exist.json',
              onCompleted: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(); // errorBuilder fires and schedules onCompleted
      await tester.pump(); // post-frame delivery

      expect(completed, 1, reason: 'the flow must continue on asset failure');
    });

    testWidgets('disposal does not crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraduationCeremony(onCompleted: () {}),
          ),
        ),
      );
      await tester.pump(); // load starts
      await tester.pump(); // composition resolves, forward()
      // Dispose mid-playback by replacing the widget tree.
      await tester.pumpWidget(const MaterialApp(home: Text('disposed')));
      // No exception should have been thrown.
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposed widget does not invoke completion', (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraduationCeremony(onCompleted: () => completed++),
          ),
        ),
      );
      await tester.pump(); // load starts
      await tester.pump(); // composition resolves, forward()
      // Dispose before the ceremony finishes.
      await tester.pumpWidget(const MaterialApp(home: Text('disposed')));
      await tester.pump();

      expect(completed, 0,
          reason: 'completion must not fire after disposal');
    });
  });

  group('CeremonyScreen', () {
    testWidgets('completion navigates to /login', (tester) async {
      final router = GoRouter(
        initialLocation: '/ceremony',
        routes: [
          GoRoute(
            path: '/ceremony',
            builder: (context, state) => const CeremonyScreen(
              assetPath: 'assets/animations/does_not_exist.json',
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(); // ceremony errorBuilder fires → onCompleted scheduled
      await tester.pump(); // onCompleted post-frame → context.go('/login')
      await tester.pump(); // router processes navigation
      await tester.pump(); // login screen renders

      expect(find.text('Your future starts somewhere.'), findsOneWidget);
    });
  });
}
