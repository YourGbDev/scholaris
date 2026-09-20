import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/intro/presentation/intro_screen.dart';
import 'package:scholaris/features/onboarding/controllers/onboarding_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _onboardingMarker = 'ONBOARDING STUB';
const String _loginMarker = 'LOGIN STUB';

GoRouter _testRouter() => GoRouter(
      initialLocation: '/intro',
      routes: [
        GoRoute(
          path: '/intro',
          builder: (context, state) => const IntroScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text(_onboardingMarker))),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text(_loginMarker))),
        ),
      ],
    );

Future<void> _pumpIntro(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: _testRouter(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('IntroScreen UI Elements', () {
    testWidgets('renders all required elements and no dots or skip', (tester) async {
      await _pumpIntro(tester);

      // 1. Scholaris brand lockup
      expect(find.text('Scholaris'), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);

      // 2. Blob illustration
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final Image imageWidget = tester.widget(imageFinder);
      expect(
        (imageWidget.image as AssetImage).assetName,
        'assets/images/intro_scene.png',
      );

      // 3. Headline & subtext
      expect(find.text('Your Dream,\nOur Mission.'), findsOneWidget);
      expect(
        find.text(
          'Scholaris helps Filipino students find the scholarship they truly deserve.',
        ),
        findsOneWidget,
      );

      // 4. CTAs
      expect(find.byKey(const ValueKey('intro-get-started-button')), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(find.byKey(const ValueKey('intro-sign-in-button')), findsOneWidget);
      expect(find.text('Already have an account? Sign In.'), findsOneWidget);

      // 5. Explicitly NO dot indicators, NO skip button
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('tapping Get Started marks intro_seen and navigates to onboarding',
        (tester) async {
      await _pumpIntro(tester);

      final getStarted = find.byKey(const ValueKey('intro-get-started-button'));
      expect(getStarted, findsOneWidget);

      await tester.tap(getStarted);
      await tester.pumpAndSettle();

      expect(find.text(_onboardingMarker), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kIntroSeenKey), isTrue);
    });

    testWidgets('tapping Sign In marks intro_seen and onboarding_seen and navigates to login',
        (tester) async {
      await _pumpIntro(tester);

      final signIn = find.byKey(const ValueKey('intro-sign-in-button'));
      expect(signIn, findsOneWidget);

      await tester.tap(signIn);
      await tester.pumpAndSettle();

      expect(find.text(_loginMarker), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kIntroSeenKey), isTrue);
      expect(prefs.getBool(kOnboardingSeenKey), isTrue);
    });
  });

  group('IntroScreen Viewport Responsiveness', () {
    for (final size in [
      const Size(360, 800),
      const Size(390, 844),
      const Size(440, 956),
      const Size(1024, 768),
    ]) {
      testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpIntro(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('onboardingRedirectDecision with introSeen', () {
    test('when introSeen is false, first launch funnels to /intro', () {
      expect(
        onboardingRedirectDecision(
          authDecision: '/login',
          location: '/splash',
          onboardingLoading: false,
          onboardingSeen: false,
          introSeen: false,
        ),
        '/intro',
      );
      expect(
        onboardingRedirectDecision(
          authDecision: null,
          location: '/login',
          onboardingLoading: false,
          onboardingSeen: false,
          introSeen: false,
        ),
        '/intro',
      );
      expect(
        onboardingRedirectDecision(
          authDecision: '/login',
          location: '/intro',
          onboardingLoading: false,
          onboardingSeen: false,
          introSeen: false,
        ),
        isNull,
      );
    });

    test('when introSeen is true and onboardingSeen is false, funnels to /onboarding', () {
      expect(
        onboardingRedirectDecision(
          authDecision: '/login',
          location: '/splash',
          onboardingLoading: false,
          onboardingSeen: false,
          introSeen: true,
        ),
        '/onboarding',
      );
      expect(
        onboardingRedirectDecision(
          authDecision: '/login',
          location: '/onboarding',
          onboardingLoading: false,
          onboardingSeen: false,
          introSeen: true,
        ),
        isNull,
      );
    });
  });
}
