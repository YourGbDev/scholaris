import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholaris/features/onboarding/controllers/onboarding_controller.dart';
import 'package:scholaris/features/onboarding/presentation/onboarding_screen.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

Future<void> pumpEntry(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('LOGIN STUB')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(theme: scholarisTheme(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> next(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding-next')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('welcome introduces Scholaris without promotional badges', (
    tester,
  ) async {
    await pumpEntry(tester);
    expect(find.text('Your next chapter starts here.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('intro-get-started-button')),
      findsOneWidget,
    );
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('GRANT ENGINE'), findsNothing);
  });
  testWidgets(
    'four features follow welcome with a distinct mascot and consistent controls',
    (tester) async {
      await pumpEntry(tester);
      await tester.tap(find.byKey(const ValueKey('intro-get-started-button')));
      await tester.pumpAndSettle();
      const titles = [
        'Find your scholarship',
        'See what fits your profile',
        'Know your next step',
        'Meet your scholarship companion',
      ];
      const poses = ['discover', 'match', 'track', 'companion'];
      for (var i = 0; i < titles.length; i++) {
        expect(find.text(titles[i]), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Image &&
                (w.image is AssetImage || w.image is ResizeImage) &&
                ((w.image is ResizeImage
                                ? (w.image as ResizeImage).imageProvider
                                : w.image)
                            as AssetImage)
                        .assetName ==
                    'assets/mascots/onboarding/${poses[i]}.png',
          ),
          findsOneWidget,
        );
        expect(find.text('${i + 1} of 4'), findsOneWidget);
        if (i < 3) await next(tester);
      }
      expect(find.text('Coming soon'), findsOneWidget);
      await next(tester);
      expect(find.text('LOGIN STUB'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kOnboardingSeenKey), isTrue);
      expect(prefs.getBool(kIntroSeenKey), isTrue);
    },
  );
  testWidgets(
    'skip and returning-user login persist completion before entering login',
    (tester) async {
      await pumpEntry(tester);
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN STUB'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool(kOnboardingSeenKey),
        isTrue,
      );
      await pumpEntry(tester);
      await tester.tap(find.byKey(const ValueKey('intro-get-started-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN STUB'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool(kOnboardingSeenKey),
        isTrue,
      );
    },
  );
  testWidgets(
    'reduced-motion controls and swipes preserve progress without completing',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpEntry(tester);
      await tester.tap(find.byKey(const ValueKey('intro-get-started-button')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('See what fits your profile'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Find your scholarship'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool(kOnboardingSeenKey),
        isNot(true),
      );
    },
  );
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(1024, 768), 1.0),
  ]) {
    testWidgets('all pages reflow at $size and text $scale', (tester) async {
      await pumpEntry(tester, size: size, scale: scale);
      final start = find.byKey(const ValueKey('intro-get-started-button'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      for (var page = 0; page < 4; page++) {
        expect(tester.takeException(), isNull);
        final button = find.byKey(const ValueKey('onboarding-next'));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
        if (page < 3) await next(tester);
      }
    });
  }
}
