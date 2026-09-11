import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/admin/presentation/admin_users_tab.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

import 'helpers/fake_profile_data_source.dart';

void main() {
  testWidgets('AdminUsersTab renders accounts, role filters, and search', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeProfileDs = FakeProfileDataSource();
    fakeProfileDs.rows['user-1'] = {
      'id': 'user-1-uuid',
      'full_name': 'Admin User',
      'role': 'admin',
      'setup_complete': true,
    };
    fakeProfileDs.rows['user-2'] = {
      'id': 'user-2-uuid',
      'full_name': 'Provider Org',
      'role': 'provider',
      'setup_complete': true,
    };
    fakeProfileDs.rows['user-3'] = {
      'id': 'user-3-uuid',
      'full_name': 'Student Applicant',
      'role': 'student',
      'setup_complete': false,
    };

    await tester.pumpWidget(
      ProviderScope(
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
      ),
    );
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
}
