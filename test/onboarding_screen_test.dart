// Widget tests for the first-launch onboarding screen.
//
// Covers the composition (illustration, Poppins title, Open Sans subtitle,
// dots, circular next button, full-width CTA, skip, log-in link), the
// once-only persistence contract (completing / skipping / logging in all
// flip `onboarding_seen` before navigating to login), and the absence of
// overflow at every required breakpoint.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scholaris/features/onboarding/controllers/onboarding_controller.dart';
import 'package:scholaris/features/onboarding/presentation/onboarding_screen.dart';

const String _loginMarker = 'LOGIN STUB';

/// Finds the [LottieBuilder] loading [asset] (e.g. onboarding_slide1.json).
Finder _lottieAsset(String asset) => find.byWidgetPredicate(
  (w) =>
      w is LottieBuilder &&
      w.lottie is AssetLottie &&
      (w.lottie as AssetLottie).assetName == asset,
);

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text(_loginMarker))),
    ),
  ],
);

/// Pumps onboarding inside its router harness with a fresh prefs store.
Future<void> _pumpOnboarding(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('first slide shows illustration, copy, dots, next and skip', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    expect(find.text('Find Your Scholarship'), findsOneWidget);
    expect(
      find.text('Hundreds of opportunities matched to your profile'),
      findsOneWidget,
    );
    expect(
      _lottieAsset('assets/animations/onboarding_slide1.json'),
      findsOneWidget,
    );

    // Dots: one active pill + two inactive dots.
    expect(find.byType(AnimatedContainer), findsNWidgets(3));

    // Circular next button present; Get Started / log-in link absent.
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('next advances through all three slides', (tester) async {
    await _pumpOnboarding(tester);

    // Slide 1 → 2.
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Smart Matching'), findsOneWidget);
    expect(
      _lottieAsset('assets/animations/selection list clients.json'),
      findsOneWidget,
    );
    expect(find.text('Skip'), findsOneWidget);

    // Slide 2 → 3.
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Apply with Ease'), findsOneWidget);
    expect(
      _lottieAsset('assets/animations/onboarding_slide3.json'),
      findsOneWidget,
    );

    // Last slide: full-width CTA + log-in link, no skip, no circular next.
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.textContaining('Already have an account?'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
  });

  testWidgets('swiping left advances the slides', (tester) async {
    await _pumpOnboarding(tester);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Smart Matching'), findsOneWidget);
  });

  testWidgets('Get Started persists the flag and lands on login', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    // Reach the last slide.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text(_loginMarker), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kOnboardingSeenKey), isTrue);
  });

  testWidgets('Skip completes onboarding without visiting every slide', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text(_loginMarker), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kOnboardingSeenKey), isTrue);
  });

  testWidgets('"Log in" link on the last slide completes onboarding', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.textContaining('Already have an account?'));
    await tester.pumpAndSettle();

    expect(find.text(_loginMarker), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kOnboardingSeenKey), isTrue);
  });

  group('Responsive layout', () {
    for (final (label, width, height) in [
      ('phone 360x800', 360.0, 800.0),
      ('phone 390x844', 390.0, 844.0),
      ('tablet 1024x768', 1024.0, 768.0),
      ('desktop 1280x900', 1280.0, 900.0),
    ]) {
      testWidgets('no overflow on any slide at $label', (tester) async {
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pumpOnboarding(tester);
        expect(tester.takeException(), isNull);

        // Slide 2.
        await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Slide 3 (full-width CTA + log-in link — the densest slide).
        await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Get Started'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
