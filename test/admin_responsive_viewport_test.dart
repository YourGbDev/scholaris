import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/admin/screens/audit_trail_screen.dart';
import 'package:scholaris/features/admin/presentation/admin_audit_logs_provider.dart';
import 'package:scholaris/features/admin/presentation/admin_home_screen.dart';
import 'package:scholaris/features/admin/repositories/admin_audit_log_repository.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

class _FakeAuditLogDataSource implements AuditLogDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchAuditLogs() async => [
        {
          'id': 'log-viewport-1',
          'action': 'user_created',
          'target_type': 'user',
          'target_id': 'usr-viewport-1',
          'actor_email': 'admin@scholaris.ph',
          'actor_role': 'admin',
          'details': {'test': true},
          'created_at': '2026-09-19T12:00:00Z',
        },
        {
          'id': 'log-viewport-2',
          'action': 'role_and_status_updated',
          'target_type': 'user',
          'target_id': 'usr-viewport-2',
          'actor_email': 'admin@scholaris.ph',
          'actor_role': 'admin',
          'details': {'test': true},
          'created_at': '2026-09-19T13:00:00Z',
        },
      ];
}

void main() {
  Widget buildAdminApp() {
    final fakeProfileDs = FakeProfileDataSource();
    fakeProfileDs.rows['user-vp-1'] = {
      'id': 'user-vp-1',
      'email': 'admin@scholaris.ph',
      'full_name': 'Admin Viewport Test',
      'role': 'admin',
      'status': 'active',
      'setup_complete': true,
      'region': 'NCR',
    };
    fakeProfileDs.rows['user-vp-2'] = {
      'id': 'user-vp-2',
      'email': 'student@scholaris.ph',
      'full_name': 'Student Viewport Test',
      'role': 'student',
      'status': 'active',
      'setup_complete': false,
      'region': 'Region VII',
    };

    final sampleAuditEntries = [
      AuditLogEntry(
        id: 'log-viewport-1',
        action: 'user_created',
        targetType: 'user',
        targetId: 'usr-viewport-1',
        actorId: 'adm-001',
        actorEmail: 'admin@scholaris.ph',
        actorRole: 'admin',
        details: const {'test': true},
        ipAddress: '192.168.1.1',
        createdAt: DateTime.parse('2026-09-19T12:00:00Z'),
      ),
      AuditLogEntry(
        id: 'log-viewport-2',
        action: 'role_and_status_updated',
        targetType: 'user',
        targetId: 'usr-viewport-2',
        actorId: 'adm-001',
        actorEmail: 'admin@scholaris.ph',
        actorRole: 'admin',
        details: const {'test': true},
        ipAddress: '192.168.1.2',
        createdAt: DateTime.parse('2026-09-19T13:00:00Z'),
      ),
    ];

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('admin-1'),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(
            dataSource: fakeProfileDs,
            currentUserId: () => 'admin-1',
          ),
        ),
        adminAuditLogRepositoryProvider.overrideWithValue(
          AdminAuditLogRepository(dataSource: _FakeAuditLogDataSource()),
        ),
        auditTrailLogsProvider.overrideWith(
          (ref) => Future.value(sampleAuditEntries),
        ),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(
            dataSource: FakeScholarshipDataSource([]),
          ),
        ),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(
            dataSource: FakeApplicationDataSource(),
            currentUserId: () => 'admin-1',
          ),
        ),
      ],
      child: const MaterialApp(
        home: AdminHomeScreen(),
      ),
    );
  }

  group('Admin Responsive Viewport Tests', () {
    testWidgets('360x800 narrow mobile renders AppBar drawer trigger, fluid card feeds, and all modals without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildAdminApp());
      await tester.pumpAndSettle();

      // Verify mobile AppBar exists with hamburger drawer icon
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byTooltip('Open navigation drawer'), findsOneWidget);
      expect(find.text('Scholaris Admin'), findsOneWidget);

      // Open drawer
      await tester.tap(find.byTooltip('Open navigation drawer'));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Audit Logs'), findsOneWidget);

      // Navigate to Users tab
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      // Drawer should be closed
      expect(find.byType(Drawer), findsNothing);

      // Users tab renders fluid card feed on 360px
      expect(find.text('User Directory & Access Control'), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
      expect(find.text('Admin Viewport Test'), findsOneWidget);

      // Open Provision Identity modal on 360x800 (exercises all dropdowns including Region)
      final provisionBtn = find.text('Provision Identity');
      expect(provisionBtn, findsOneWidget);
      await tester.tap(provisionBtn);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Provision Platform Identity'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Open User Inspect modal on 360x800
      final inspectDossierBtn = find.text('Inspect Dossier').first;
      await tester.dragUntilVisible(
        inspectDossierBtn,
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(inspectDossierBtn);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Account ID'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Open Edit Role & Status modal on 360x800 via popup menu
      final userActionsBtn = find.byTooltip('User actions').first;
      await tester.dragUntilVisible(
        userActionsBtn,
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(userActionsBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Role / Status'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Edit Role & Status'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Open drawer again and navigate to Audit Logs
      await tester.tap(find.byTooltip('Open navigation drawer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Logs'));
      await tester.pumpAndSettle();

      // Audit Logs tab renders fluid card feed on 360px
      expect(find.text('System Audit Trail'), findsOneWidget);
      expect(find.text('user_created'), findsOneWidget);

      // Tap inspect on audit card on 360x800
      await tester.tap(find.text('user_created'));
      await tester.pumpAndSettle();

      expect(find.text('Audit Event Detail'), findsOneWidget);
      expect(find.text('Event ID'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('440x956 standard mobile renders Drawer, fluid card feeds, and modals without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildAdminApp());
      await tester.pumpAndSettle();

      // Verify mobile AppBar and drawer trigger
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byTooltip('Open navigation drawer'), findsOneWidget);

      // Open drawer and navigate to Users
      await tester.tap(find.byTooltip('Open navigation drawer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(find.text('User Directory & Access Control'), findsOneWidget);
      expect(find.byType(Card), findsWidgets);

      // Open Provision Identity modal on 440x956
      final provisionBtn = find.text('Provision Identity');
      expect(provisionBtn, findsOneWidget);
      await tester.tap(provisionBtn);
      await tester.pumpAndSettle();
      expect(find.text('Provision Platform Identity'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Open User Inspect modal on 440x956
      final inspectDossierBtn = find.text('Inspect Dossier').first;
      await tester.dragUntilVisible(
        inspectDossierBtn,
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(inspectDossierBtn);
      await tester.pumpAndSettle();
      expect(find.text('Account ID'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Open drawer and navigate to Audit Logs
      await tester.tap(find.byTooltip('Open navigation drawer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Logs'));
      await tester.pumpAndSettle();

      expect(find.text('System Audit Trail'), findsOneWidget);
      expect(find.text('user_created'), findsOneWidget);

      // Inspect audit log on 440x956
      await tester.tap(find.text('user_created'));
      await tester.pumpAndSettle();
      expect(find.text('Audit Event Detail'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('1280x800 desktop renders persistent 220px sidebar, wide tables, and inspection modals without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildAdminApp());
      await tester.pumpAndSettle();

      // Desktop has no AppBar and no Drawer
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(Drawer), findsNothing);

      // Sidebar is persistent
      expect(find.text('Review & oversight'), findsOneWidget);
      expect(find.text('Platform records'), findsOneWidget);
      expect(find.text('Activity & settings'), findsOneWidget);
      expect(find.text('Platform administration'), findsWidgets);

      // Switch to Users tab
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      // Wide table headers are present
      expect(find.text('IDENTITY & INSTITUTIONAL REGISTRY'), findsOneWidget);
      expect(find.text('ACCESS ROLE'), findsOneWidget);
      expect(find.text('STATUS & VERIFICATION'), findsOneWidget);
      expect(find.text('ACTIONS'), findsOneWidget);

      // Inspect first user in desktop table
      final inspectBtn = find.text('Inspect').first;
      await tester.dragUntilVisible(
        inspectBtn,
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(inspectBtn);
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Account ID')), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Switch to Audit Logs tab
      await tester.tap(find.text('Audit Logs'));
      await tester.pumpAndSettle();

      // Wide audit log entries are present
      expect(find.text('System Audit Trail'), findsOneWidget);
      expect(find.text('user_created'), findsOneWidget);
      expect(find.text('role_and_status_updated'), findsOneWidget);

      // Inspect first audit log in desktop table
      await tester.tap(find.text('user_created'));
      await tester.pumpAndSettle();
      expect(find.text('Audit Event Detail'), findsOneWidget);
      expect(find.text('EVENT DETAILS (JSONB)'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });
  });
}
