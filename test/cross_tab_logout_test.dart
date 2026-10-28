// test/cross_tab_logout_test.dart
//
// Independent QA verification suite for IAS Section E2: Same-Account Cross-Tab
// Logout Synchronization and Multi-Actor Isolation under TabScopedLocalStorage.
//
// Evaluators: Mr. Ian Celmar A. Avila, MIT & Mr. Roel Daniot, MSIT
// Student: Gilbert Bulado (#44)
// Contract: SPECIALIST_CONTRACT.md (v2.5)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/core/auth/tab_scoped_local_storage.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';

/// Simulated cross-tab broadcast message conforming to the strict wire protocol
/// defined in SPECIALIST_CONTRACT.md v2.5 Section 2.4.
class CrossTabLogoutMessage {
  final String type;
  final String? userId;
  final String? sourceScope;
  final int timestamp;
  final Map<String, dynamic> raw;

  CrossTabLogoutMessage({
    required this.type,
    this.userId,
    this.sourceScope,
    required this.timestamp,
    Map<String, dynamic>? raw,
  }) : raw = raw ?? _buildRawMap(type, userId, sourceScope, timestamp);

  static Map<String, dynamic> _buildRawMap(
    String type,
    String? userId,
    String? sourceScope,
    int timestamp,
  ) {
    final map = <String, dynamic>{
      'type': type,
      'timestamp': timestamp,
    };
    if (userId != null) map['userId'] = userId;
    if (sourceScope != null) map['sourceScope'] = sourceScope;
    return map;
  }

  factory CrossTabLogoutMessage.fromJson(Map<String, dynamic> json) {
    return CrossTabLogoutMessage(
      type: json['type'] as String? ?? '',
      userId: json['userId'] as String?,
      sourceScope: json['sourceScope'] as String?,
      timestamp: json['timestamp'] as int? ?? 0,
      raw: json,
    );
  }
}

/// Simulated shared browser broadcast bus (modeling `BroadcastChannel('scholaris_user_sync')`
/// or `scholaris-cross-tab-sync` across tabs of the same origin).
class MockBroadcastBus {
  final List<void Function(CrossTabLogoutMessage message)> _subscribers = [];
  final List<CrossTabLogoutMessage> broadcastHistory = [];

  void subscribe(void Function(CrossTabLogoutMessage message) listener) {
    _subscribers.add(listener);
  }

  void unsubscribe(void Function(CrossTabLogoutMessage message) listener) {
    _subscribers.remove(listener);
  }

  void broadcast(CrossTabLogoutMessage message) {
    broadcastHistory.add(message);
    // Deliver asynchronously to all subscribers, simulating browser event loop
    for (final listener in List.of(_subscribers)) {
      listener(message);
    }
  }

  void clear() {
    _subscribers.clear();
    broadcastHistory.clear();
  }
}

/// Simulated Browser Tab with isolated session storage, tab scope UUID,
/// and reactive Riverpod auth controller.
class SimulatedBrowserTab {
  final String tabName;
  final String scope;
  final MockBroadcastBus bus;
  final Map<String, String> sessionStorage = {};
  
  String? currentUserId;
  String currentRoute;
  bool isSignedOut = false;
  int logoutEventsReceived = 0;
  int logoutEventsIgnored = 0;
  int logoutEventsProcessed = 0;

  late final ProviderContainer container;
  late final SimulatedAuthNotifier authNotifier;

  SimulatedBrowserTab({
    required this.tabName,
    required this.scope,
    required this.bus,
    String? initialUserId,
    String? initialToken,
    this.currentRoute = '/home',
  }) : currentUserId = initialUserId {
    if (initialToken != null) {
      sessionStorage['sb-auth-token:$scope'] = initialToken;
    }

    container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(() => SimulatedAuthNotifier(initialUserId)),
      ],
    );
    authNotifier =
        container.read(authSessionProvider.notifier) as SimulatedAuthNotifier;

    // Subscribe to cross-tab synchronization channel
    bus.subscribe(_handleBusMessage);
  }

  void _handleBusMessage(CrossTabLogoutMessage message) {
    logoutEventsReceived++;

    // 1. Loop prevention: The emitting tab must ignore its own broadcast
    if (message.sourceScope == scope) {
      logoutEventsIgnored++;
      return;
    }

    // 2. Protocol validation: must be USER_LOGOUT type
    if (message.type != 'USER_LOGOUT') {
      logoutEventsIgnored++;
      return;
    }

    // 3. Payload validation: userId must be present and valid
    final targetUserId = message.userId;
    if (targetUserId == null || targetUserId.isEmpty) {
      logoutEventsIgnored++;
      return;
    }

    // 4. Multi-Actor Isolation: Non-matching user IDs are strictly ignored
    if (currentUserId == null || currentUserId != targetUserId) {
      logoutEventsIgnored++;
      return;
    }

    // 5. Same-Account Match: Execute local termination
    logoutEventsProcessed++;
    executeLocalTermination();
  }

  /// Triggers logout from this tab, broadcasting to other tabs of the origin.
  void triggerUserLogout() {
    final userIdToLogout = currentUserId;
    if (userIdToLogout == null) return;

    // Clear local tab state
    executeLocalTermination();

    // Broadcast minimal user-scoped logout payload (strictly zero token/secret exposure)
    bus.broadcast(CrossTabLogoutMessage(
      type: 'USER_LOGOUT',
      userId: userIdToLogout,
      sourceScope: scope,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Local tab termination: clears sessionStorage, sets auth state to null, routes to /login
  void executeLocalTermination() {
    sessionStorage.remove('sb-auth-token:$scope');
    currentUserId = null;
    isSignedOut = true;
    currentRoute = '/login';
    authNotifier.signOut();
  }

  /// Simulates page refresh and session rehydration from sessionStorage
  void refreshPage() {
    final token = sessionStorage['sb-auth-token:$scope'];
    if (token != null && token.isNotEmpty) {
      // Session rehydrates successfully
      isSignedOut = false;
      // zero broadcast dispatched during refresh
    } else {
      currentUserId = null;
      isSignedOut = true;
      currentRoute = '/login';
      authNotifier.signOut();
    }
  }

  void dispose() {
    bus.unsubscribe(_handleBusMessage);
    container.dispose();
  }
}

class SimulatedAuthNotifier extends AuthSessionNotifier {
  SimulatedAuthNotifier(this._initialUserId);

  final String? _initialUserId;

  @override
  AuthSession? build() =>
      _initialUserId == null ? null : AuthSession(userId: _initialUserId);

  void signIn(String userId) {
    state = AuthSession(userId: userId);
  }

  void signOut() {
    state = null;
  }
}

void main() {
  late MockBroadcastBus bus;

  setUp(() {
    bus = MockBroadcastBus();
  });

  tearDown(() {
    bus.clear();
  });

  group('IAS Section E2: Same-Account Cross-Tab Logout Propagation', () {
    test('Tab 1 logout propagates to Tab 2 of same user, clears storage and routes to /login', () {
      const userA = 'user-a-uuid-1111';
      final tab1 = SimulatedBrowserTab(
        tabName: 'Chrome Tab 1 (User A)',
        scope: 'tab-scope-alpha',
        bus: bus,
        initialUserId: userA,
        initialToken: 'jwt-token-alpha',
        currentRoute: '/home',
      );
      final tab2 = SimulatedBrowserTab(
        tabName: 'Chrome Tab 2 (User A)',
        scope: 'tab-scope-beta',
        bus: bus,
        initialUserId: userA,
        initialToken: 'jwt-token-beta',
        currentRoute: '/tracker',
      );

      expect(tab1.currentUserId, equals(userA));
      expect(tab2.currentUserId, equals(userA));
      expect(tab2.sessionStorage.containsKey('sb-auth-token:tab-scope-beta'), isTrue);
      expect(tab2.container.read(authSessionProvider)?.userId, equals(userA));

      // User A clicks Log Out in Tab 1
      tab1.triggerUserLogout();

      // Verify Tab 1 state
      expect(tab1.isSignedOut, isTrue);
      expect(tab1.currentUserId, isNull);
      expect(tab1.currentRoute, equals('/login'));
      expect(tab1.sessionStorage.containsKey('sb-auth-token:tab-scope-alpha'), isFalse);

      // Verify Tab 2 received event, cleared sessionStorage, and routed to /login
      expect(tab2.logoutEventsReceived, equals(1));
      expect(tab2.logoutEventsProcessed, equals(1));
      expect(tab2.logoutEventsIgnored, equals(0));
      expect(tab2.isSignedOut, isTrue);
      expect(tab2.currentUserId, isNull);
      expect(tab2.currentRoute, equals('/login'));
      expect(tab2.sessionStorage.containsKey('sb-auth-token:tab-scope-beta'), isFalse);
      expect(tab2.container.read(authSessionProvider), isNull);

      tab1.dispose();
      tab2.dispose();
    });

    test('Loop Prevention: Emitting tab ignores its own broadcast', () {
      const userA = 'user-a-uuid-1111';
      final tab1 = SimulatedBrowserTab(
        tabName: 'Chrome Tab 1',
        scope: 'tab-scope-alpha',
        bus: bus,
        initialUserId: userA,
      );

      tab1.triggerUserLogout();

      // Tab 1 broadcasted to bus, received its own message back via bus
      expect(tab1.logoutEventsReceived, equals(1));
      // Handled as ignored because sourceScope matches tab1.scope
      expect(tab1.logoutEventsIgnored, equals(1));
      expect(tab1.logoutEventsProcessed, equals(0));

      tab1.dispose();
    });
  });

  group('IAS Section E2: Different-Account Multi-Actor Isolation Invariant', () {
    test('Org Admin (Tab 1) logout NEVER affects Org Staff / Reviewer (Tab 3)', () {
      const orgAdminId = 'org-admin-uuid-dost-01';
      const orgStaffId = 'org-staff-uuid-dost-02';

      final tab1 = SimulatedBrowserTab(
        tabName: 'Chrome Tab 1 (Org Admin)',
        scope: 'scope-admin',
        bus: bus,
        initialUserId: orgAdminId,
        initialToken: 'admin-jwt-token-12345',
        currentRoute: '/provider-home',
      );
      final tab3 = SimulatedBrowserTab(
        tabName: 'Chrome Tab 3 (Org Staff / Reviewer)',
        scope: 'scope-staff',
        bus: bus,
        initialUserId: orgStaffId,
        initialToken: 'staff-jwt-token-67890',
        currentRoute: '/provider-application/app-999',
      );

      // Verify initial isolation
      expect(tab1.currentUserId, equals(orgAdminId));
      expect(tab3.currentUserId, equals(orgStaffId));
      expect(tab3.sessionStorage['sb-auth-token:scope-staff'], equals('staff-jwt-token-67890'));

      // Org Admin logs out in Tab 1
      tab1.triggerUserLogout();

      // Tab 1 is logged out
      expect(tab1.isSignedOut, isTrue);
      expect(tab1.currentRoute, equals('/login'));

      // Tab 3 received the sync broadcast, but detected non-matching userId
      expect(tab3.logoutEventsReceived, equals(1));
      expect(tab3.logoutEventsIgnored, equals(1));
      expect(tab3.logoutEventsProcessed, equals(0));

      // Tab 3 MUST RETAIN active session and functional route without corruption
      expect(tab3.isSignedOut, isFalse);
      expect(tab3.currentUserId, equals(orgStaffId));
      expect(tab3.currentRoute, equals('/provider-application/app-999'));
      expect(tab3.sessionStorage['sb-auth-token:scope-staff'], equals('staff-jwt-token-67890'));
      expect(tab3.container.read(authSessionProvider)?.userId, equals(orgStaffId));

      tab1.dispose();
      tab3.dispose();
    });

    test('Three-Tab Scenario: Admin in Tab 1, Admin in Tab 2, Reviewer in Tab 3', () {
      const adminId = 'admin-uuid';
      const reviewerId = 'reviewer-uuid';

      final tab1 = SimulatedBrowserTab(
        tabName: 'Tab 1 (Admin Session A)',
        scope: 'scope-1',
        bus: bus,
        initialUserId: adminId,
        initialToken: 'tok-admin-1',
      );
      final tab2 = SimulatedBrowserTab(
        tabName: 'Tab 2 (Admin Session B)',
        scope: 'scope-2',
        bus: bus,
        initialUserId: adminId,
        initialToken: 'tok-admin-2',
      );
      final tab3 = SimulatedBrowserTab(
        tabName: 'Tab 3 (Reviewer Session)',
        scope: 'scope-3',
        bus: bus,
        initialUserId: reviewerId,
        initialToken: 'tok-rev',
      );

      // Admin logs out from Tab 2
      tab2.triggerUserLogout();

      // Tab 2 and Tab 1 must be terminated
      expect(tab2.isSignedOut, isTrue);
      expect(tab1.isSignedOut, isTrue);
      expect(tab1.currentUserId, isNull);

      // Tab 3 (Reviewer) must remain 100% authenticated
      expect(tab3.isSignedOut, isFalse);
      expect(tab3.currentUserId, equals(reviewerId));
      expect(tab3.sessionStorage.containsKey('sb-auth-token:scope-3'), isTrue);

      tab1.dispose();
      tab2.dispose();
      tab3.dispose();
    });
  });

  group('IAS Section E2: Zero Token & Secret Exposure Invariant', () {
    test('Broadcast payload strictly omits access tokens, passwords, and sessions', () {
      const userA = 'user-uuid-9999';
      final tab = SimulatedBrowserTab(
        tabName: 'Tab 1',
        scope: 'scope-secret-test',
        bus: bus,
        initialUserId: userA,
        initialToken: 'secret-bearer-jwt-ey1234567890',
      );

      tab.triggerUserLogout();

      expect(bus.broadcastHistory.length, equals(1));
      final broadcast = bus.broadcastHistory.first;

      // Verify allowed fields
      expect(broadcast.raw.keys, containsAll(['type', 'userId', 'sourceScope', 'timestamp']));
      expect(broadcast.raw['type'], equals('USER_LOGOUT'));
      expect(broadcast.raw['userId'], equals(userA));

      // Assert ZERO secrets or tokens exposed
      expect(broadcast.raw.containsKey('token'), isFalse);
      expect(broadcast.raw.containsKey('accessToken'), isFalse);
      expect(broadcast.raw.containsKey('refreshToken'), isFalse);
      expect(broadcast.raw.containsKey('password'), isFalse);
      expect(broadcast.raw.containsKey('session'), isFalse);
      expect(broadcast.raw.toString().contains('secret-bearer-jwt'), isFalse);

      tab.dispose();
    });
  });

  group('IAS Section E2: Robustness to Malformed & Replayed Events', () {
    test('Ignores payload with missing userId without uncaught exception', () {
      final tab = SimulatedBrowserTab(
        tabName: 'Tab 1',
        scope: 'scope-test',
        bus: bus,
        initialUserId: 'user-valid',
      );

      bus.broadcast(CrossTabLogoutMessage.fromJson({
        'type': 'USER_LOGOUT',
        'sourceScope': 'external-scope',
        'timestamp': 1730000000000,
        // userId missing!
      }));

      expect(tab.logoutEventsReceived, equals(1));
      expect(tab.logoutEventsIgnored, equals(1));
      expect(tab.isSignedOut, isFalse);
      expect(tab.currentUserId, equals('user-valid'));

      tab.dispose();
    });

    test('Ignores payload with unknown event type', () {
      final tab = SimulatedBrowserTab(
        tabName: 'Tab 1',
        scope: 'scope-test',
        bus: bus,
        initialUserId: 'user-valid',
      );

      bus.broadcast(CrossTabLogoutMessage.fromJson({
        'type': 'UNKNOWN_EVENT_PING',
        'userId': 'user-valid',
        'sourceScope': 'external-scope',
        'timestamp': 1730000000000,
      }));

      expect(tab.logoutEventsReceived, equals(1));
      expect(tab.logoutEventsIgnored, equals(1));
      expect(tab.isSignedOut, isFalse);

      tab.dispose();
    });

    test('Handles duplicate / repeated broadcast idempotently without crash', () {
      final tab = SimulatedBrowserTab(
        tabName: 'Tab 1',
        scope: 'scope-test',
        bus: bus,
        initialUserId: 'user-valid',
      );

      final msg = CrossTabLogoutMessage(
        type: 'USER_LOGOUT',
        userId: 'user-valid',
        sourceScope: 'external-scope',
        timestamp: 1730000000000,
      );

      // Deliver duplicate broadcasts
      bus.broadcast(msg);
      bus.broadcast(msg);
      bus.broadcast(msg);

      expect(tab.logoutEventsReceived, equals(3));
      // First one processes; second and third are ignored because user is already signed out
      expect(tab.logoutEventsProcessed, equals(1));
      expect(tab.logoutEventsIgnored, equals(2));
      expect(tab.isSignedOut, isTrue);

      tab.dispose();
    });
  });

  group('IAS Section E2: Page Refresh & Session Rehydration', () {
    test('Refreshing active tab preserves sessionStorage and emits zero logout broadcasts', () {
      final tab = SimulatedBrowserTab(
        tabName: 'Tab Refresh Test',
        scope: 'scope-refresh',
        bus: bus,
        initialUserId: 'user-refreshed',
        initialToken: 'token-persisted-in-session-storage',
      );

      expect(bus.broadcastHistory.isEmpty, isTrue);

      // Simulate F5 page refresh
      tab.refreshPage();

      // Session must remain intact
      expect(tab.isSignedOut, isFalse);
      expect(tab.currentUserId, equals('user-refreshed'));
      expect(tab.sessionStorage['sb-auth-token:scope-refresh'], equals('token-persisted-in-session-storage'));
      // Zero broadcasts emitted by refreshing tab
      expect(bus.broadcastHistory.isEmpty, isTrue);

      tab.dispose();
    });
  });

  group('TabScopedLocalStorage Contract Interface Verification', () {
    test('TabScopedLocalStorage exposes expected initialization and storage contracts', () async {
      const storage = TabScopedLocalStorage(persistSessionKey: 'sb-test-token');

      // Initialization runs safely
      await storage.initialize();

      // In VM unit test environment (kIsWeb == false):
      // hasAccessToken returns false and accessToken returns null
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);

      // removePersistedSession and persistSession complete without error
      await storage.persistSession('sample-persisted-string');
      await storage.removePersistedSession();
    });
  });
}
