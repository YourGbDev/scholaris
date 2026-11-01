import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/admin/screens/admin_backup_screen.dart';
import 'package:scholaris/core/security/login_lockout_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    LoginLockoutService.instance.resetState();
  });

  Widget createHarness() {
    return const ProviderScope(
      child: MaterialApp(
        home: AdminBackupScreen(),
      ),
    );
  }

  testWidgets('AdminBackupScreen renders honest header, automated schedule card, and genuine archives list', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createHarness());
    await tester.pumpAndSettle();

    // Verify Honest Header
    expect(find.text('Database Backup & Recovery'), findsOneWidget);
    expect(find.textContaining('Host AES-256 Snapshot Pipeline & Verified Isolated Recovery'), findsOneWidget);

    // Verify Schedule Card
    expect(find.text('Automated Scheduled Backups'), findsOneWidget);
    expect(find.text('ACTIVE • HOST AUTOMATION'), findsOneWidget);
    expect(find.text('AES-256-GCM'), findsOneWidget);
    expect(find.text('Task Scheduler Daily'), findsOneWidget);
    expect(find.text('Supabase Free (No Cloud PITR)'), findsOneWidget);

    // Verify Isolated Recovery Milestone Card
    expect(find.text('Verified Disaster Recovery Milestone'), findsOneWidget);
    expect(find.textContaining('All 15 Public Tables Restored & Integrity Verified (0 errors)'), findsOneWidget);
    expect(find.textContaining('127.0.0.1:55479'), findsOneWidget);

    // Verify Genuine Vault & Archives
    expect(find.text('Encrypted Snapshot Vault'), findsOneWidget);
    expect(find.textContaining('scholaris-20261031T180002310505Z.scb'), findsOneWidget);
    expect(find.textContaining('scholaris-20261029T140248455668Z.scb'), findsOneWidget);
    expect(find.text('VERIFIED RECOVERY'), findsOneWidget);
  });

  testWidgets('Triggering host backup inspection displays CLI instructions and records audit event', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createHarness());
    await tester.pumpAndSettle();

    final triggerButton = find.text('Inspect Host Backup Pipeline');
    await tester.ensureVisible(triggerButton);
    await tester.tap(triggerButton);
    await tester.pumpAndSettle();

    // Verify advisory dialog
    expect(find.text('Host Backup Pipeline'), findsOneWidget);
    expect(find.textContaining('Direct client-side dump generation is disabled by design'), findsOneWidget);
    expect(find.textContaining('powershell -ExecutionPolicy Bypass -File tools/run_scholaris_backup.ps1'), findsOneWidget);

    // Dismiss
    await tester.tap(find.text('Understood'));
    await tester.pumpAndSettle();

    final auditLogs = LoginLockoutService.instance.inMemoryAuditLogs;
    expect(auditLogs.any((l) => l['action'] == 'ADMIN_DATABASE_BACKUP_STATUS_INSPECTED'), isTrue);
  });

  testWidgets('Recovery Guard dialog enforces production protection and provides staging commands', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createHarness());
    await tester.pumpAndSettle();

    final recoveryGuardButton = find.text('Recovery Guard').first;
    await tester.ensureVisible(recoveryGuardButton);
    await tester.tap(recoveryGuardButton);
    await tester.pumpAndSettle();

    expect(find.text('Production Recovery Guard'), findsOneWidget);
    expect(find.textContaining('Live restoration over the production cluster (yqwbarzxpduzmtrxnrbm) is strictly disabled'), findsOneWidget);
    expect(find.textContaining('powershell -File tools/decrypt_scholaris_backup.ps1'), findsOneWidget);

    // Dismiss
    await tester.tap(find.text('Close Advisory'));
    await tester.pumpAndSettle();

    final auditLogs = LoginLockoutService.instance.inMemoryAuditLogs;
    expect(auditLogs.any((l) => l['action'] == 'ADMIN_DATABASE_RECOVERY_INSPECTED'), isTrue);
  });
}
