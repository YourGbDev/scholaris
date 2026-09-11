import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/admin/presentation/admin_applicants_tab.dart';
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

  testWidgets('Admin can confirm award for approved application with confirmation guard', (tester) async {
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

    final fakeAppDs = FakeApplicationDataSource();
    await fakeAppDs.insertApplication('student-1', {
      'id': 'app-approved-1',
      'user_id': 'student-1',
      'scholarship_id': 'sch-1',
      'status': 'approved',
    });

    final fakeSchDs = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'DOST Merit Scholarship',
      }
    ]);

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
          applicationRepositoryProvider.overrideWith(
            (ref) => ApplicationRepository(
              dataSource: fakeAppDs,
              currentUserId: () => 'admin-1',
            ),
          ),
          scholarshipRepositoryProvider.overrideWith(
            (ref) => ScholarshipRepository(
              dataSource: fakeSchDs,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminApplicantsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Award button is rendered for student-1 with approved application
    final awardBtn = find.widgetWithText(FilledButton, 'Award');
    expect(awardBtn, findsOneWidget);

    // Tap Award button
    await tester.tap(awardBtn);
    await tester.pumpAndSettle();

    // Verify confirmation dialog appears with guard text
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Confirm Award'), findsOneWidget);
    expect(find.textContaining('officially award the "DOST Merit Scholarship" scholarship to Juan Dela Cruz'), findsOneWidget);

    // Test Cancel button aborts
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    // Application status should still be approved
    final appsAfterCancel = await fakeAppDs.fetchAllApplications();
    expect(appsAfterCancel.first['status'], 'approved');

    // Tap Award again and confirm
    await tester.tap(awardBtn);
    await tester.pumpAndSettle();

    final confirmBtn = find.widgetWithText(FilledButton, 'Confirm award');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Dialog closes, SnackBar appears
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Scholarship awarded to Juan Dela Cruz.'), findsOneWidget);

    // Data source updated to awarded
    final appsAfterConfirm = await fakeAppDs.fetchAllApplications();
    expect(appsAfterConfirm.first['status'], 'awarded');

    // Table re-renders and Award button is no longer shown (since status is now awarded, not approved)
    expect(find.widgetWithText(FilledButton, 'Award'), findsNothing);
  });

  testWidgets('Inspect dialog displays applications and allows confirming award', (tester) async {
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

    final fakeAppDs = FakeApplicationDataSource();
    await fakeAppDs.insertApplication('student-1', {
      'id': 'app-approved-1',
      'user_id': 'student-1',
      'scholarship_id': 'sch-1',
      'status': 'approved',
      'applied_at': '2026-08-01T04:30:00.000Z',
    });

    final fakeSchDs = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'DOST Merit Scholarship',
      }
    ]);

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
          applicationRepositoryProvider.overrideWith(
            (ref) => ApplicationRepository(
              dataSource: fakeAppDs,
              currentUserId: () => 'admin-1',
            ),
          ),
          scholarshipRepositoryProvider.overrideWith(
            (ref) => ScholarshipRepository(
              dataSource: fakeSchDs,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminApplicantsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Inspect dialog
    await tester.tap(find.widgetWithText(TextButton, 'Inspect'));
    await tester.pumpAndSettle();

    // Verify dialog has applications section
    expect(find.text('Scholarship applications'), findsOneWidget);
    expect(find.text('DOST Merit Scholarship'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);

    final dialogConfirmBtn = find.widgetWithText(FilledButton, 'Confirm award');
    expect(dialogConfirmBtn, findsOneWidget);

    // Tap Confirm award from inside Inspect dialog
    await tester.tap(dialogConfirmBtn);
    await tester.pumpAndSettle();

    // Guard dialog appears
    expect(find.text('Confirm Award'), findsOneWidget);

    // Confirm
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm award'));
    await tester.pumpAndSettle();

    // SnackBar appears
    expect(find.text('Scholarship awarded to Juan Dela Cruz.'), findsOneWidget);

    // DB updated
    final apps = await fakeAppDs.fetchAllApplications();
    expect(apps.first['status'], 'awarded');
  });
}
