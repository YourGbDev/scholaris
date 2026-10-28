import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/app/router.dart';
import 'package:scholaris/core/security/inactivity_guard.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/main.dart';

class _SignedIn extends AuthSessionNotifier {
  @override
  AuthSession? build() => const AuthSession(userId: 'student');
}

void main() {
  for (final size in [const Size(360, 800), const Size(440, 956), const Size(1280, 800)]) {
    testWidgets('inactivity warning fits a ${size.width}x${size.height} viewport', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Home'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_SignedIn.new),
          routerProvider.overrideWithValue(router),
        ],
        child: const ScholarisApp(),
      ));
      await tester.pump();
      await tester.pump(const Duration(minutes: 14));
      expect(find.text('Stay signed in'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('ordinary user activity postpones the warning', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Home'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(_SignedIn.new),
        routerProvider.overrideWithValue(router),
      ],
      child: const ScholarisApp(),
    ));
    await tester.pump();
    await tester.pump(const Duration(minutes: 10));
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));
    expect(find.text('Your session is about to expire'), findsNothing);
    await tester.pump(const Duration(minutes: 9));
    expect(find.text('Your session is about to expire'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('warns a signed-in user before 15 minutes of inactivity',
      (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Home'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(_SignedIn.new),
        routerProvider.overrideWithValue(router),
      ],
      child: const ScholarisApp(),
    ));
    await tester.pump();
    await tester.pump(const Duration(minutes: 14));
    expect(find.text('Your session is about to expire'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stay signed in resets the warning and expiration', (tester) async {
    var signOuts = 0;
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Home'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(_SignedIn.new),
        routerProvider.overrideWithValue(router),
        inactivitySignOutProvider.overrideWithValue(() async => signOuts++),
      ],
      child: const ScholarisApp(),
    ));
    await tester.pump();
    await tester.pump(const Duration(minutes: 14));
    await tester.tap(find.text('Stay signed in'));
    await tester.pump();
    await tester.pump(const Duration(minutes: 1));
    expect(signOuts, 0);
    expect(find.text('Your session is about to expire'), findsNothing);
    await tester.pump(const Duration(minutes: 13));
    expect(find.text('Your session is about to expire'), findsOneWidget);
    await tester.pump(const Duration(minutes: 1));
    expect(signOuts, 1);
    expect(find.text('Your session has expired'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed automatic sign-out keeps the screen blocked and offers retry',
      (tester) async {
    var attempts = 0;
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Home'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(_SignedIn.new),
        routerProvider.overrideWithValue(router),
        inactivitySignOutProvider.overrideWithValue(() async {
          attempts++;
          throw StateError('offline');
        }),
      ],
      child: const ScholarisApp(),
    ));
    await tester.pump();
    await tester.pump(const Duration(minutes: 15));
    await tester.pump();
    expect(attempts, 1);
    expect(find.text('We could not sign you out. Please try again.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.byType(ModalBarrier), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });
}
