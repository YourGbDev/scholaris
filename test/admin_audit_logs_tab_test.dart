import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/admin/presentation/admin_audit_logs_tab.dart';

void main() {
  testWidgets('AdminAuditLogsTab renders audit ledger readiness, blueprint, and inactive stream notice', (tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AdminAuditLogsTab()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('System Audit Ledger'), findsOneWidget);
    expect(find.text('Audit logging infrastructure readiness'), findsOneWidget);
    expect(find.text('Migration pending'), findsOneWidget);
    expect(find.text('Target migration blueprint (0008_create_audit_logs.sql)'), findsOneWidget);
    expect(find.text('Audit event stream'), findsOneWidget);
    expect(find.text('Event streaming inactive'), findsOneWidget);
  });
}
