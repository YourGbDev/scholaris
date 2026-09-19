import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/core/security/login_lockout_service.dart';
import 'package:scholaris/features/admin/presentation/admin_users_tab.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

import 'helpers/fake_profile_data_source.dart';

void main() {
  setUp(() {
    LoginLockoutService.instance.resetState();
  });

  Widget buildApp(FakeProfileDataSource fakeProfileDs) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('admin-1'),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(
            dataSource: fakeProfileDs,
            currentUserId: () => 'admin-1',
          ),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: AdminUsersTab()),
      ),
    );
  }

  FakeProfileDataSource makeSampleDataSource() {
    final ds = FakeProfileDataSource();
    ds.rows['user-1'] = {
      'id': 'user-1-uuid',
      'email': 'admin@scholaris.ph',
      'full_name': 'Admin User',
      'role': 'admin',
      'status': 'active',
      'setup_complete': true,
      'region': 'NCR',
    };
    ds.rows['user-2'] = {
      'id': 'user-2-uuid',
      'email': 'provider@org.ph',
      'full_name': 'Provider Org',
      'role': 'provider',
      'status': 'active',
      'setup_complete': true,
      'region': 'Region VII',
    };
    ds.rows['user-3'] = {
      'id': 'user-3-uuid',
      'email': 'student@up.edu.ph',
      'full_name': 'Student Applicant',
      'role': 'student',
      'status': 'active',
      'setup_complete': false,
      'region': 'Region IV-A (CALABARZON)',
    };
    return ds;
  }

  testWidgets('AdminUsersTab renders accounts, role filters, and search', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeProfileDs = makeSampleDataSource();

    await tester.pumpWidget(buildApp(fakeProfileDs));
    await tester.pumpAndSettle();

    // Verify header and all users rendered
    expect(find.text('User Management'), findsOneWidget);
    expect(find.text('Admin User'), findsOneWidget);
    expect(find.text('Provider Org'), findsOneWidget);
    expect(find.text('Student Applicant'), findsOneWidget);
    expect(find.text('Setup pending'), findsOneWidget);

    // Filter by Providers
    await tester.tap(find.text('Providers'));
    await tester.pumpAndSettle();

    expect(find.text('Provider Org'), findsOneWidget);
    expect(find.text('Admin User'), findsNothing);
    expect(find.text('Student Applicant'), findsNothing);

    // Filter by Admins
    await tester.tap(find.text('Admins'));
    await tester.pumpAndSettle();

    expect(find.text('Admin User'), findsOneWidget);
    expect(find.text('Provider Org'), findsNothing);
  });

  testWidgets('AdminUsersTab inspect dialog displays full user attributes', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeProfileDs = makeSampleDataSource();

    await tester.pumpWidget(buildApp(fakeProfileDs));
    await tester.pumpAndSettle();

    // Tap inspect on the first user
    await tester.tap(find.text('Inspect').first);
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Account ID')), findsOneWidget);
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('user-1-uuid')), findsOneWidget);
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('admin@scholaris.ph')), findsOneWidget);
    expect(find.text('NCR'), findsOneWidget);
    expect(find.text('Edit Role / Status'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('AdminUsersTab creates a new user account with audit event logging', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeProfileDs = makeSampleDataSource();

    await tester.pumpWidget(buildApp(fakeProfileDs));
    await tester.pumpAndSettle();

    // Tap Create User button
    await tester.tap(find.text('Create User'));
    await tester.pumpAndSettle();

    expect(find.text('Create User Account'), findsOneWidget);

    // Fill form
    await tester.enterText(find.widgetWithText(TextFormField, 'Full Name *'), 'Elena Santos');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email Address *'), 'elena@scholaris.ph');

    // Tap Create Account button
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();

    // Verify user was created in data source
    expect(find.text('Elena Santos'), findsOneWidget);

    // Verify audit log was recorded
    final logs = LoginLockoutService.instance.inMemoryAuditLogs;
    expect(logs.any((l) => l['action'] == 'user_created' && l['target_type'] == 'user'), isTrue);
  });

  testWidgets('AdminUsersTab edits role and status with audit event logging', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeProfileDs = makeSampleDataSource();

    await tester.pumpWidget(buildApp(fakeProfileDs));
    await tester.pumpAndSettle();

    // Open popup menu on first user
    await tester.tap(find.byTooltip('User actions').first);
    await tester.pumpAndSettle();

    // Tap Edit Role / Status
    await tester.tap(find.text('Edit Role / Status'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Role & Status: Admin User'), findsOneWidget);

    // Save changes
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();

    // Verify audit log recorded
    final logs = LoginLockoutService.instance.inMemoryAuditLogs;
    expect(logs.any((l) => l['action'] == 'role_and_status_updated'), isTrue);
  });

  testWidgets('AdminUsersTab deactivates user with audit event logging', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeProfileDs = makeSampleDataSource();

    await tester.pumpWidget(buildApp(fakeProfileDs));
    await tester.pumpAndSettle();

    // Open popup menu on student
    await tester.tap(find.byTooltip('User actions').at(2));
    await tester.pumpAndSettle();

    // Tap Deactivate Account
    await tester.tap(find.text('Deactivate Account'));
    await tester.pumpAndSettle();

    expect(find.text('Deactivate Account'), findsWidgets);

    // Confirm
    await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
    await tester.pumpAndSettle();

    // Verify status badge changed to Deactivated
    expect(find.text('Deactivated'), findsOneWidget);

    // Verify audit log
    final logs = LoginLockoutService.instance.inMemoryAuditLogs;
    expect(logs.any((l) => l['action'] == 'user_deactivated'), isTrue);
  });

  testWidgets('AdminUsersTab deletes user with audit event logging', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeProfileDs = makeSampleDataSource();

    await tester.pumpWidget(buildApp(fakeProfileDs));
    await tester.pumpAndSettle();

    // Open popup menu on student
    await tester.tap(find.byTooltip('User actions').at(2));
    await tester.pumpAndSettle();

    // Tap Delete Account
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Are you sure you want to permanently delete'), findsOneWidget);

    // Confirm Delete
    await tester.tap(find.widgetWithText(FilledButton, 'Delete Permanently'));
    await tester.pumpAndSettle();

    // Verify Student Applicant is deleted
    expect(find.text('Student Applicant'), findsNothing);

    // Verify audit log
    final logs = LoginLockoutService.instance.inMemoryAuditLogs;
    expect(logs.any((l) => l['action'] == 'user_deleted'), isTrue);
  });

  testWidgets('AdminUsersTab renders fluid card feed on mobile viewport (< 768px)', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeProfileDs = makeSampleDataSource();

    await tester.pumpWidget(buildApp(fakeProfileDs));
    await tester.pumpAndSettle();

    expect(find.text('User Management'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(3));
    expect(find.text('Admin User'), findsOneWidget);
    expect(find.text('Provider Org'), findsOneWidget);
    expect(find.text('Student Applicant'), findsOneWidget);
  });
}
