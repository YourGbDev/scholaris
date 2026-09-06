// Day 19 integration test: full ceremony → login flow.
//
// Exercises the end-to-end path:
//   /ceremony → GraduationCeremony plays → onCompleted → /login →
//   EmptyStage + login form

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/auth/presentation/ceremony_screen.dart';
import 'package:scholaris/features/auth/presentation/empty_stage.dart';
import 'package:scholaris/features/auth/presentation/graduation_ceremony.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

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

  testWidgets('ceremony → completion → login → empty stage → login form', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/ceremony',
      routes: [
        GoRoute(
          path: '/ceremony',
          builder: (context, state) => const CeremonyScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(); // Lottie load starts
    await tester.pump(); // composition resolves, forward()

    // Pump through the ceremony playback.
    await pumpSteps(tester, kCeremonyDurationMs + 500);
    await tester.pump(); // post-frame onCompleted
    await tester.pump(); // router processes context.go('/login')
    await tester.pump(); // login screen builds

    // The login screen should now be visible with:
    // - EmptyStage behind the form
    expect(find.byType(EmptyStage), findsOneWidget);
    // - The locked headline
    expect(find.text('Your future starts somewhere.'), findsOneWidget);
    // - Standard login fields
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
