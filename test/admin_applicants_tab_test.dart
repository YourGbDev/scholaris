import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/admin/presentation/admin_applicants_tab.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

import 'helpers/fake_profile_data_source.dart';

void main() {
  testWidgets('AdminApplicantsTab renders student list, searches, and opens inspect dialog', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeProfileDs = FakeProfileDataSource();
    fakeProfileDs.rows['student-1'] = {
      'id': 'student-1',
      'full_name': 'Juan Dela Cruz',
      'course': 'BS Computer Science',
      'school': 'University of the Philippines',
      'year_level': 3,
      'gpa': 3.85,
      'region': 'NCR',
      'nationality': 'Filipino',
      'role': 'student',
      'setup_complete': true,
    };
    fakeProfileDs.rows['student-2'] = {
      'id': 'student-2',
      'full_name': 'Maria Santos',
      'course': 'BS Civil Engineering',
      'school': 'De La Salle University',
      'year_level': 2,
      'gpa': 3.70,
      'region': 'Region IV-A',
      'nationality': 'Filipino',
      'role': 'student',
      'setup_complete': true,
    };
    fakeProfileDs.rows['provider-1'] = {
      'id': 'provider-1',
      'full_name': 'DOST Officer',
      'role': 'provider',
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
          home: Scaffold(body: AdminApplicantsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and student entries
    expect(find.text('Student Directory'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
    // Provider excluded from student directory
    expect(find.text('DOST Officer'), findsNothing);

    // Search for Juan
    await tester.enterText(find.byType(TextField), 'Juan');
    await tester.pumpAndSettle();

    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Maria Santos'), findsNothing);

    // Tap Inspect button
    final inspectBtn = find.widgetWithText(TextButton, 'Inspect').first;
    await tester.tap(inspectBtn);
    await tester.pumpAndSettle();

    // Dialog appears with student details
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('University of the Philippines'),
      ),
      findsOneWidget,
    );
    expect(find.text('BS Computer Science'), findsWidgets);

    // Close dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
