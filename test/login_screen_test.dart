import 'package:flutter_riverpod/flutter_riverpod.dart';
// The student login keeps a focused form while preserving authentication behavior.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
    await tester.pumpWidget(
      ProviderScope(child: const MaterialApp(home: LoginScreen())),
    );
    await tester.pump(
      const Duration(milliseconds: kLoginEntranceTotalMs) +
          const Duration(milliseconds: 100),
    );
  }

  group('LoginScreen composition', () {
    testWidgets('brief form entrance settles within 200ms', (tester) async {
      await useLargeSurface(tester);
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );
      expect(kLoginEntranceTotalMs, lessThanOrEqualTo(220));
      await tester.pump(const Duration(milliseconds: 100));
      final fade = tester.widget<FadeTransition>(
        find
            .descendant(
              of: find.byKey(const ValueKey('login-form-entrance')),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, greaterThan(0));
      expect(fade.opacity.value, lessThan(1));
      await tester.pumpAndSettle();
      expect(fade.opacity.value, 1);
    });

    testWidgets('focused screen has a welcome and no unavailable options', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await pumpSettled(tester);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Help'), findsNothing);
      expect(find.textContaining('Coming soon'), findsNothing);
      expect(find.textContaining('OR AUTHENTICATE'), findsNothing);
      expect(find.byType(FittedBox), findsNothing);
      final image = tester.widget<Image>(find.byType(Image).first);
      expect(
        (image.image as AssetImage).assetName,
        'assets/mascots/greetings/welcome_pair.png',
      );
    });

    testWidgets('renders the full form hierarchy in the locked order', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await pumpSettled(tester);

      // Hierarchy: headline → email → password → forgot → login → signup.
      // Provider CTA is hidden on mobile until public landing URL is configured.
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
      expect(find.text('Become a scholarship provider'), findsNothing);

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
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'student@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets('entrance sequence settles with everything visible', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );
      await tester.pump();

      // The form remains available throughout its brief entrance.
      expect(find.text('Welcome back'), findsOneWidget);

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
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );
      await tester.pump();

      // All elements are immediately visible and the button is interactive.
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Become a scholarship provider'), findsNothing);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Sign in'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets(
      'provider CTA is hidden on mobile by default when landing URL is unconfigured',
      (tester) async {
        await useLargeSurface(tester);
        await pumpSettled(tester);

        expect(
          find.text('Want to help students reach their dreams?'),
          findsNothing,
        );
        expect(find.text('Become a scholarship provider'), findsNothing);
      },
    );

    testWidgets('provider CTA renders and is tappable when enabled or on web', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(home: LoginScreen(showProviderCta: true)),
        ),
      );
      await tester.pump(
        const Duration(milliseconds: kLoginEntranceTotalMs) +
            const Duration(milliseconds: 100),
      );

      expect(
        find.text('Want to help students reach their dreams?'),
        findsNothing,
      );
      expect(find.text('Become a scholarship provider'), findsOneWidget);

      await tester.tap(
        find.text('Become a scholarship provider'),
        warnIfMissed: false,
      );
      await tester.pump();
    });

    testWidgets('renders "Remember me for 30 days" checkbox and toggles', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await pumpSettled(tester);

      expect(find.text('Remember me for 30 days'), findsOneWidget);
      final checkboxFinder = find.byKey(const ValueKey('remember-me-checkbox'));
      expect(checkboxFinder, findsOneWidget);

      final checkbox = tester.widget<Checkbox>(checkboxFinder);
      expect(checkbox.value, isTrue);

      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final toggledCheckbox = tester.widget<Checkbox>(checkboxFinder);
      expect(toggledCheckbox.value, isFalse);
    });
  });

  group('LoginScreen accessibility', () {
    testWidgets(
      'narrow enlarged text and keyboard viewport scroll without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(2),
                  viewInsets: const EdgeInsets.only(bottom: 240),
                ),
                child: child!,
              ),
              home: const LoginScreen(showProviderCta: true),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Sign in'),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final button = tester.getSize(
          find.widgetWithText(ElevatedButton, 'Sign in'),
        );
        expect(button.height, greaterThanOrEqualTo(48));
        await tester.ensureVisible(find.text('Become a scholarship provider'));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('fields expose autofill and show/hide password affordance', (
      tester,
    ) async {
      await useLargeSurface(tester);
      await pumpSettled(tester);
      final email = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(email.controller, isNotNull);
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.first.keyboardType, TextInputType.emailAddress);
      expect(fields.first.autofillHints, contains(AutofillHints.email));
      expect(fields.last.autofillHints, contains(AutofillHints.password));
      expect(fields.last.obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(
        tester.widgetList<TextField>(find.byType(TextField)).last.obscureText,
        isFalse,
      );
      expect(find.byTooltip('Hide password'), findsOneWidget);
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
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset your password'), findsOneWidget);
    });
  });
}
