import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/admin/screens/audit_trail_screen.dart';
import 'package:scholaris/features/admin/presentation/admin_audit_logs_tab.dart';

void main() {
  final sampleLogs = <AuditLogEntry>[
    AuditLogEntry(
      id: 'log-001',
      action: 'user_created',
      targetType: 'user',
      targetId: 'usr-123',
      actorId: 'adm-001',
      actorEmail: 'admin@scholaris.ph',
      actorRole: 'admin',
      details: const {'name': 'Juan Dela Cruz', 'role': 'student'},
      ipAddress: '192.168.1.1',
      createdAt: DateTime.parse('2026-09-19T10:00:00Z'),
    ),
    AuditLogEntry(
      id: 'log-002',
      action: 'role_and_status_updated',
      targetType: 'user',
      targetId: 'usr-456',
      actorId: 'adm-001',
      actorEmail: 'admin@scholaris.ph',
      actorRole: 'admin',
      details: const {'old_role': 'student', 'new_role': 'provider'},
      ipAddress: '192.168.1.2',
      createdAt: DateTime.parse('2026-09-19T11:00:00Z'),
    ),
    AuditLogEntry(
      id: 'log-003',
      action: 'account_lockout_triggered',
      targetType: 'auth',
      targetId: 'usr-789',
      actorId: 'anon-001',
      actorEmail: 'attacker@example.com',
      actorRole: 'anonymous',
      details: const {'failed_attempts': 3},
      ipAddress: '10.0.0.99',
      createdAt: DateTime.parse('2026-09-19T12:00:00Z'),
    ),
  ];

  Widget buildApp({List<AuditLogEntry>? logs}) {
    return ProviderScope(
      overrides: [
        auditTrailLogsProvider.overrideWith((ref) => Future.value(logs ?? sampleLogs)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: AdminAuditLogsTab()),
      ),
    );
  }

  group('AdminAuditLogsTab', () {
    testWidgets('renders ledger title, live count, and event entries on desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('System Audit Trail'), findsOneWidget);
      expect(find.text('3 audit events recorded'), findsOneWidget);
      expect(find.text('Live data'), findsOneWidget);

      // Verify log actions rendered in table/cards
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

      expect(find.text('System Audit Trail'), findsOneWidget);
      expect(find.text('user_created'), findsOneWidget);
      expect(find.text('role_and_status_updated'), findsOneWidget);
      expect(find.text('account_lockout_triggered'), findsOneWidget);
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

    testWidgets('action dropdown filter filters audit logs', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open Action dropdown
      await tester.tap(find.text('Action: All'));
      await tester.pumpAndSettle();

      // Select 'Action: user created'
      await tester.tap(find.text('Action: user created').last);
      await tester.pumpAndSettle();

      expect(find.text('user_created'), findsOneWidget);
      expect(find.text('account_lockout_triggered'), findsNothing);
    });

    testWidgets('tapping log entry opens structured details modal with JSON payload', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap first log row
      await tester.tap(find.text('user_created'));
      await tester.pumpAndSettle();

      expect(find.text('Audit Event Detail'), findsOneWidget);
      expect(find.text('Event ID'), findsOneWidget);
      expect(find.text('log-001'), findsOneWidget);
      expect(find.text('EVENT DETAILS (JSONB)'), findsOneWidget);
      expect(find.textContaining('Juan Dela Cruz'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Audit Event Detail'), findsNothing);
    });

    testWidgets('empty state renders when no logs match', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(logs: []));
      await tester.pumpAndSettle();

      expect(find.text('No audit events found'), findsOneWidget);
    });
  });
}
