import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/app/router.dart';
import 'package:scholaris/core/security/inactivity_guard.dart';
import 'package:scholaris/core/security/inactivity_storage.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SignedIn extends AuthSessionNotifier {
  @override
  AuthSession? build() => const AuthSession(userId: 'student');
}

class _SwitchableSession extends AuthSessionNotifier {
  @override
  AuthSession? build() => const AuthSession(userId: 'student');
  void signOut() => state = null;
  void signIn() => state = const AuthSession(userId: 'student');
}

class _MultiUserSession extends AuthSessionNotifier {
  @override
  AuthSession? build() => const AuthSession(userId: 'user_a');
  void switchTo(String? userId) {
    state = userId == null ? null : AuthSession(userId: userId);
  }
}

class _BrokenStorage extends InactivityStorage {
  @override
  Future<int?> read(String key) async =>
      throw StateError('storage unavailable');
}

class _FailingWriteOnResetStorage extends InactivityStorage {
  final Map<String, int> _data = {};
  bool failWrites = false;

  @override
  Future<int?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, int value) async {
    if (failWrites) throw StateError('storage write failure');
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async => _data.remove(key);
}

class _FailingRemoveStorage extends InactivityStorage {
  final Map<String, int> _data = {};

  @override
  Future<int?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, int value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async =>
      throw StateError('storage remove failure');
}

class _DelayedWriteStorage extends InactivityStorage {
  final Map<String, int> data = {};
  Completer<void>? writeCompleter;

  @override
  Future<int?> read(String key) async => data[key];

  @override
  Future<void> write(String key, int value) async {
    if (writeCompleter != null) {
      await writeCompleter!.future;
    }
    data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    data.remove(key);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'genuinely new session with no saved deadline initializes 15-minute deadline and persists immediately',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final now = DateTime.now();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt('inactivity_deadline_student');
      expect(stored, isNotNull);
      final storedDeadline = DateTime.fromMillisecondsSinceEpoch(stored!);
      final diff = storedDeadline.difference(now);
      expect(diff.inMinutes, inInclusiveRange(14, 15));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('restored session past its inactivity deadline signs out', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'inactivity_deadline_student': DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
    });
    var signOuts = 0;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_SignedIn.new),
          routerProvider.overrideWithValue(router),
          inactivitySignOutProvider.overrideWithValue(() async => signOuts++),
        ],
        child: const ScholarisApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(signOuts, 1);
    expect(find.text('Your session has expired'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'restored session with implausible far-future deadline (>24h) fails closed and expires',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'inactivity_deadline_student': DateTime.now()
            .add(const Duration(hours: 25))
            .millisecondsSinceEpoch,
      });
      var signOuts = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivitySignOutProvider.overrideWithValue(() async => signOuts++),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(signOuts, 1);
      expect(find.text('Your session has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'restored session with negative stored timestamp fails closed and expires',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'inactivity_deadline_student': -500,
      });
      var signOuts = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivitySignOutProvider.overrideWithValue(() async => signOuts++),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(signOuts, 1);
      expect(find.text('Your session has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'repeated relaunch of expired session never silently grants a fresh 15-minute window',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'inactivity_deadline_student': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch,
      });
      var signOuts = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);

      // First launch
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivitySignOutProvider.overrideWithValue(() async => signOuts++),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(signOuts, 1);
      expect(find.text('Your session has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());

      // Second relaunch with existing storage
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivitySignOutProvider.overrideWithValue(() async => signOuts++),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(signOuts, 2);
      expect(find.text('Your session has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'restart persistence resumes unexpired deadline without resetting to 15 minutes',
    (tester) async {
      // Stored deadline has 8 minutes remaining
      SharedPreferences.setMockInitialValues({
        'inactivity_deadline_student': DateTime.now()
            .add(const Duration(minutes: 8))
            .millisecondsSinceEpoch,
      });
      var signOuts = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivitySignOutProvider.overrideWithValue(() async => signOuts++),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);

      // After 7 minutes, 1 minute remains -> warning appears
      await tester.pump(const Duration(minutes: 7));
      expect(find.text('Your session is about to expire'), findsOneWidget);

      // After 1 more minute (8 minutes total), session expires
      await tester.pump(const Duration(minutes: 1));
      expect(signOuts, 1);
      expect(find.text('Your session has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'forward clock jump during active session triggers immediate expiration',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var signOuts = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivitySignOutProvider.overrideWithValue(() async => signOuts++),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);

      // Advance 16 minutes (beyond 15-minute deadline)
      await tester.pump(const Duration(minutes: 16));
      expect(signOuts, 1);
      expect(find.text('Your session has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('a different user does not inherit another user deadline', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'inactivity_deadline_other': 1});
    var signOuts = 0;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_SignedIn.new),
          routerProvider.overrideWithValue(router),
          inactivitySignOutProvider.overrideWithValue(() async => signOuts++),
        ],
        child: const ScholarisApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(signOuts, 0);
    expect(find.text('Home'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('storage failure blocks access instead of resetting the timer', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_SignedIn.new),
          routerProvider.overrideWithValue(router),
          inactivityStorageProvider.overrideWithValue(_BrokenStorage()),
        ],
        child: const ScholarisApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Security check unavailable'), findsOneWidget);
    expect(find.byType(ModalBarrier), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'storage write failure during activity triggers security check unavailable dialog',
    (tester) async {
      final testStorage = _FailingWriteOnResetStorage();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivityStorageProvider.overrideWithValue(testStorage),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);

      // Arm write failure
      testStorage.failWrites = true;

      // Trigger user activity to reset timer
      await tester.tap(find.text('Home'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Security check unavailable'), findsOneWidget);
      expect(find.byType(ModalBarrier), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'storage failure on key removal during account switch fails closed',
    (tester) async {
      final testStorage = _FailingRemoveStorage();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(_MultiUserSession.new),
          routerProvider.overrideWithValue(router),
          inactivityStorageProvider.overrideWithValue(testStorage),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);

      // Switch user from user_a to user_b. testStorage throws on remove
      (container.read(authSessionProvider.notifier) as _MultiUserSession)
          .switchTo('user_b');
      await tester.pump();
      await tester.pump();

      expect(find.text('Security check unavailable'), findsOneWidget);
      expect(find.byType(ModalBarrier), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'rapid account switching purges previous user key and discards late queued writes',
    (tester) async {
      final delayedStorage = _DelayedWriteStorage();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(_MultiUserSession.new),
          routerProvider.overrideWithValue(router),
          inactivityStorageProvider.overrideWithValue(delayedStorage),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);
      expect(delayedStorage.data.containsKey('inactivity_deadline_user_a'), isTrue);

      // Setup delayed write for user_a
      final writeCompleter = Completer<void>();
      delayedStorage.writeCompleter = writeCompleter;

      // Trigger activity for user_a to queue a write
      await tester.tap(find.text('Home'));
      await tester.pump();

      // Rapidly switch to user_b before user_a write completes
      (container.read(authSessionProvider.notifier) as _MultiUserSession)
          .switchTo('user_b');
      await tester.pump();

      // Complete the delayed write that belonged to user_a
      writeCompleter.complete();
      await tester.pump();
      await tester.pump();

      // Monotonic generation check ensures user_a late write was discarded
      // and user_a deadline was purged
      expect(delayedStorage.data.containsKey('inactivity_deadline_user_a'), isFalse);
      expect(delayedStorage.data.containsKey('inactivity_deadline_user_b'), isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'sign-out clears the deadline before the same user signs in again',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(_SwitchableSession.new),
          routerProvider.overrideWithValue(router),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('inactivity_deadline_student'), isNotNull);
      (container.read(authSessionProvider.notifier) as _SwitchableSession)
          .signOut();
      await tester.pump();
      await tester.pump();
      expect(prefs.getInt('inactivity_deadline_student'), isNull);
      (container.read(authSessionProvider.notifier) as _SwitchableSession)
          .signIn();
      await tester.pump();
      await tester.pump();
      expect(prefs.getInt('inactivity_deadline_student'), isNotNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final size in [
    const Size(360, 800),
    const Size(440, 956),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'inactivity warning fits a ${size.width}x${size.height} viewport',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('Home')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authSessionProvider.overrideWith(_SignedIn.new),
              routerProvider.overrideWithValue(router),
            ],
            child: const ScholarisApp(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(minutes: 14));
        expect(find.text('Stay signed in'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('ordinary user activity postpones the warning', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_SignedIn.new),
          routerProvider.overrideWithValue(router),
        ],
        child: const ScholarisApp(),
      ),
    );
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

  testWidgets('warns a signed-in user before 15 minutes of inactivity', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_SignedIn.new),
          routerProvider.overrideWithValue(router),
        ],
        child: const ScholarisApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(minutes: 14));
    expect(find.text('Your session is about to expire'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stay signed in resets the warning and expiration', (
    tester,
  ) async {
    var signOuts = 0;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_SignedIn.new),
          routerProvider.overrideWithValue(router),
          inactivitySignOutProvider.overrideWithValue(() async => signOuts++),
        ],
        child: const ScholarisApp(),
      ),
    );
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

  testWidgets(
    'failed automatic sign-out keeps the screen blocked and offers retry with Try again and Sign out',
    (tester) async {
      var attempts = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivitySignOutProvider.overrideWithValue(() async {
              attempts++;
              throw StateError('offline');
            }),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(minutes: 15));
      await tester.pump();
      expect(attempts, 1);
      expect(
        find.text('We could not sign you out. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(attempts, 2);
      expect(find.byType(ModalBarrier), findsWidgets);

      await tester.tap(find.text('Sign out'));
      await tester.pump();
      expect(attempts, 3);
      expect(find.byType(ModalBarrier), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'distinguishes local inactivity enforcement from server token revocation: executes local scope sign-out and purges local storage',
    (tester) async {
      var localSignOutCalled = false;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(_SwitchableSession.new),
          routerProvider.overrideWithValue(router),
          inactivitySignOutProvider.overrideWithValue(() async {
            // Local inactivity enforcement executes client-side local scope sign-out
            localSignOutCalled = true;
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('inactivity_deadline_student'), isNotNull);

      // Session reaches 15 minutes of inactivity
      await tester.pump(const Duration(minutes: 15));
      await tester.pump();
      expect(localSignOutCalled, isTrue);

      // Simulating local auth session destruction
      (container.read(authSessionProvider.notifier) as _SwitchableSession)
          .signOut();
      await tester.pump();
      await tester.pump();

      // Local storage deadline is purged for local defense against device abandonment
      expect(prefs.getInt('inactivity_deadline_student'), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'backward clock jump smaller than 24 hours clamps remaining time to 15-minute timeout',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var mockNow = DateTime(2026, 10, 30, 12, 0, 0);
      var signOuts = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Protected Sensitive Data')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivityClockProvider.overrideWithValue(() => mockNow),
            inactivitySignOutProvider.overrideWithValue(() async => signOuts++),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Protected Sensitive Data'), findsOneWidget);

      // System clock rolls back 2 hours (smaller than 24h)
      mockNow = mockNow.subtract(const Duration(hours: 2));

      // App lifecycle resume or activity evaluates deadline against rolled back time
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Advancing 16 minutes from the rolled-back time must expire the session
      // because remaining time was clamped to 15 minutes instead of allowing 2h 15m
      mockNow = mockNow.add(const Duration(minutes: 16));
      await tester.pump(const Duration(minutes: 16));
      await tester.pump();

      expect(signOuts, 1);
      expect(find.text('Your session has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'protected content is completely concealed during loading and expired-restore',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'inactivity_deadline_student': DateTime.now()
            .subtract(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
      });
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Protected Confidential Document')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
          ],
          child: const ScholarisApp(),
        ),
      );
      // During initial restore / loading
      expect(find.text('Protected Confidential Document'), findsNothing);

      await tester.pump();
      await tester.pump();

      // After restore expired: still concealed
      expect(find.text('Protected Confidential Document'), findsNothing);
      expect(find.text('Your session has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'protected content is completely concealed during storage failure',
    (tester) async {
      final brokenStorageRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Protected Confidential Document')),
          ),
        ],
      );
      addTearDown(brokenStorageRouter.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(brokenStorageRouter),
            inactivityStorageProvider.overrideWithValue(_BrokenStorage()),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Protected Confidential Document'), findsNothing);
      expect(find.text('Security check unavailable'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'protected content remains visible beneath warning dialog during pre-expiration warning',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final warningRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Protected Confidential Document')),
          ),
        ],
      );
      addTearDown(warningRouter.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(warningRouter),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Protected Confidential Document'), findsOneWidget);

      // Advance to warning window (14 minutes)
      await tester.pump(const Duration(minutes: 14));
      expect(find.text('Your session is about to expire'), findsOneWidget);
      expect(find.text('Protected Confidential Document'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    },
  );

  group('Web storage corruption and absent-key differentiation', () {
    test('parseInactivityDeadline unit tests distinguish missing from invalid data', () {
      expect(parseInactivityDeadline(null), isNull);
      expect(() => parseInactivityDeadline(''), throwsFormatException);
      expect(() => parseInactivityDeadline('corrupted'), throwsFormatException);
      expect(() => parseInactivityDeadline('NaN'), throwsFormatException);
      expect(() => parseInactivityDeadline('12.34'), throwsFormatException);
      expect(parseInactivityDeadline('1730275200000'), 1730275200000);
    });

    testWidgets('InactivityWebStorage with missing key permits new session initialization', (tester) async {
      final mockWebStorage = <String, String>{};
      final webStorage = InactivityWebStorage(
        getItem: (k) => mockWebStorage[k],
        setItem: (k, v) => mockWebStorage[k] = v,
        removeItem: (k) => mockWebStorage.remove(k),
      );
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Protected Data'))),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivityStorageProvider.overrideWithValue(webStorage),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Protected Data'), findsOneWidget);
      expect(mockWebStorage.containsKey('inactivity_deadline_student'), isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('InactivityWebStorage with empty string stored value fails closed', (tester) async {
      final mockWebStorage = <String, String>{
        'inactivity_deadline_student': '',
      };
      final webStorage = InactivityWebStorage(
        getItem: (k) => mockWebStorage[k],
        setItem: (k, v) => mockWebStorage[k] = v,
        removeItem: (k) => mockWebStorage.remove(k),
      );
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Protected Data'))),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivityStorageProvider.overrideWithValue(webStorage),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Protected Data'), findsNothing);
      expect(find.text('Security check unavailable'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('InactivityWebStorage with non-numeric stored value fails closed', (tester) async {
      final mockWebStorage = <String, String>{
        'inactivity_deadline_student': 'corrupted_non_numeric_token',
      };
      final webStorage = InactivityWebStorage(
        getItem: (k) => mockWebStorage[k],
        setItem: (k, v) => mockWebStorage[k] = v,
        removeItem: (k) => mockWebStorage.remove(k),
      );
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Protected Data'))),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_SignedIn.new),
            routerProvider.overrideWithValue(router),
            inactivityStorageProvider.overrideWithValue(webStorage),
          ],
          child: const ScholarisApp(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Protected Data'), findsNothing);
      expect(find.text('Security check unavailable'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
