import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/admin/presentation/admin_audit_logs_provider.dart';
import 'package:scholaris/features/admin/presentation/admin_audit_logs_tab.dart';
import 'package:scholaris/features/admin/repositories/admin_audit_log_repository.dart';

class FakeAuditLogDataSource implements AuditLogDataSource {
  FakeAuditLogDataSource(this.logs);
  final List<Map<String, dynamic>> logs;

  @override
  Future<List<Map<String, dynamic>>> fetchAuditLogs() async => logs;
}

void main() {
  final sampleLogs = [
    {
      'id': 'log-001',
      'action': 'user_created',
      'target_type': 'user',
      'target_id': 'usr-123',
      'actor_email': 'admin@scholaris.ph',
      'actor_role': 'admin',
      'details': {'name': 'Juan Dela Cruz', 'role': 'student'},
      'ip_address': '192.168.1.1',
      'created_at': '2026-09-19T10:00:00Z',
    },
    {
      'id': 'log-002',
      'action': 'role_and_status_updated',
      'target_type': 'user',
      'target_id': 'usr-456',
      'actor_email': 'admin@scholaris.ph',
      'actor_role': 'admin',
      'details': {'old_role': 'student', 'new_role': 'provider'},
      'ip_address': '192.168.1.2',
      'created_at': '2026-09-19T11:00:00Z',
    },
    {
      'id': 'log-003',
      'action': 'account_lockout_triggered',
      'target_type': 'auth',
      'target_id': 'usr-789',
      'actor_email': 'attacker@example.com',
      'actor_role': 'anonymous',
      'details': {'failed_attempts': 3},
      'ip_address': '10.0.0.99',
      'created_at': '2026-09-19T12:00:00Z',
    },
  ];

  Widget buildApp({List<Map<String, dynamic>>? logs}) {
    final fakeDs = FakeAuditLogDataSource(logs ?? sampleLogs);
    final repo = AdminAuditLogRepository(dataSource: fakeDs);

    return ProviderScope(
      overrides: [
        adminAuditLogRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        home: Scaffold(body: AdminAuditLogsTab()),
      ),
    );
  }

  group('AdminAuditLogsTab', () {
    testWidgets('renders ledger title, readiness status, and live event entries on desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('System Audit Ledger'), findsOneWidget);
      expect(find.text('Audit logging infrastructure readiness'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Verify table headers
      expect(find.text('Timestamp'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Target'), findsOneWidget);
      expect(find.text('Actor'), findsOneWidget);

      // Verify log actions rendered in table
      expect(find.text('user_created'), findsOneWidget);
      expect(find.text('role_and_status_updated'), findsOneWidget);
      expect(find.text('account_lockout_triggered'), findsOneWidget);
    });

    testWidgets('renders fluid card feed on mobile viewport (< 768px)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('System Audit Ledger'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(3));
      expect(find.text('user_created'), findsOneWidget);
    });

    testWidgets('search query filters audit logs by action or actor', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'lockout');
      await tester.pumpAndSettle();

      expect(find.text('account_lockout_triggered'), findsOneWidget);
      expect(find.text('user_created'), findsNothing);
      expect(find.text('role_and_status_updated'), findsNothing);
    });

    testWidgets('action filter chips filter audit logs', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Filter by Security
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();

      expect(find.text('account_lockout_triggered'), findsOneWidget);
      expect(find.text('user_created'), findsNothing);

      // Filter by Users
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(find.text('user_created'), findsOneWidget);
      expect(find.text('role_and_status_updated'), findsOneWidget);
      expect(find.text('account_lockout_triggered'), findsNothing);
    });

    testWidgets('tapping Inspect opens structured details modal with JSON payload', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap first Inspect button
      await tester.tap(find.text('Inspect').first);
      await tester.pumpAndSettle();

      expect(find.text('Audit Event Details'), findsOneWidget);
      expect(find.text('Event ID'), findsOneWidget);
      expect(find.text('log-001'), findsOneWidget);
      expect(find.text('Event Payload & Metadata'), findsOneWidget);
      expect(find.textContaining('Juan Dela Cruz'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Audit Event Details'), findsNothing);
    });

    testWidgets('empty state renders when no logs match', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(logs: []));
      await tester.pumpAndSettle();

      expect(find.text('No audit logs found'), findsOneWidget);
    });
  });
}
