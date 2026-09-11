import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/admin/presentation/admin_audit_logs_tab.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';

void main() {
  testWidgets('AdminAuditLogsTab renders audit ledger readiness and hooks table', (tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('admin-operator-99'),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminAuditLogsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('System Audit Ledger'), findsOneWidget);
    expect(find.text('Audit logging infrastructure readiness'), findsOneWidget);
    expect(find.text('Migration pending'), findsOneWidget);
    expect(find.text('Registered Action Hooks'), findsOneWidget);
    expect(find.text('provider.approved'), findsOneWidget);
    expect(find.text('Session Telemetry'), findsOneWidget);
    expect(find.text('admin-operator-99'), findsOneWidget);
  });
}
