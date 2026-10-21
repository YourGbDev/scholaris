import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/admin/screens/applications_oversight_screen.dart';
import 'package:scholaris/features/admin/presentation/admin_applicants_tab.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'helpers/fake_application_data_source.dart';

void main() {
  final sampleApp1 = ApplicationRecord(
    id: 'app-approved-1',
    userId: 'student-1',
    scholarshipId: 'sch-1',
    status: 'approved',
    notes: 'Strong candidate',
    appliedAt: DateTime.parse('2026-08-01T04:30:00.000Z'),
    updatedAt: DateTime.parse('2026-08-05T04:30:00.000Z'),
    applicantName: 'Juan Dela Cruz',
    school: 'University of the Philippines',
    course: 'BS Computer Science',
    yearLevel: 3,
    gpa: 3.85,
    region: 'NCR',
    scholarshipTitle: 'DOST Merit Scholarship',
    scholarshipAmount: 50000,
  );

  final sampleApp2 = ApplicationRecord(
    id: 'app-submitted-2',
    userId: 'student-2',
    scholarshipId: 'sch-2',
    status: 'submitted',
    notes: null,
    appliedAt: DateTime.parse('2026-08-10T04:30:00.000Z'),
    updatedAt: DateTime.parse('2026-08-10T04:30:00.000Z'),
    applicantName: 'Maria Santos',
    school: 'De La Salle University',
    course: 'BS Civil Engineering',
    yearLevel: 2,
    gpa: 3.70,
    region: 'Region IV-A',
    scholarshipTitle: 'CHED Merit Grant',
    scholarshipAmount: 40000,
  );

  testWidgets('AdminApplicantsTab renders application list, searches, and filters', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAppDs = FakeApplicationDataSource();
    final repo = ApplicationRepository(dataSource: fakeAppDs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('admin-1'),
          applicationRepositoryProvider.overrideWithValue(repo),
          adminApplicationsProvider.overrideWith((ref) => Future.value([sampleApp1, sampleApp2])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminApplicantsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and applications
    expect(find.text('Applications Oversight'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);

    // Search for Juan
    await tester.enterText(find.byType(TextField), 'Juan');
    await tester.pumpAndSettle();

    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Maria Santos'), findsNothing);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
  });

  testWidgets('Confirmed successful lookup with no record allows award action for approved application', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAppDs = FakeApplicationDataSource();
    final repo = ApplicationRepository(dataSource: fakeAppDs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('admin-1'),
          applicationRepositoryProvider.overrideWithValue(repo),
          adminApplicationsProvider.overrideWith((ref) => Future.value([sampleApp1])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminApplicantsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify card is rendered
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Inspect Dossier'), findsOneWidget);

    // Open dossier
    await tester.tap(find.text('Inspect Dossier'));
    await tester.pumpAndSettle();

    // Dossier dialog shows student details and 'Confirm Award & Disburse'
    expect(find.text('Confirm Award & Disburse'), findsOneWidget);

    // Tap 'Confirm Award & Disburse'
    await tester.tap(find.text('Confirm Award & Disburse'));
    await tester.pumpAndSettle();

    // Modal appears with guard header and details
    expect(find.text('Confirm Award & Schedule Disbursement'), findsOneWidget);
    expect(find.text('Recipient'), findsOneWidget);
    expect(find.text('Scholarship'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);

    // Close disbursement sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Award & Schedule Disbursement'), findsNothing);
  });

  testWidgets('Loading disbursement state keeps award/disbursement action unavailable', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final completer = Completer<Map<String, dynamic>?>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('admin-1'),
          applicationDisbursementProvider('app-approved-1').overrideWith((ref) => completer.future),
          adminApplicationsProvider.overrideWith((ref) => Future.value([sampleApp1])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminApplicantsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open dossier
    await tester.tap(find.text('Inspect Dossier'));
    await tester.pump(); // Pump frame without settling completer

    // Verify CircularProgressIndicator is displayed and award action is UNAVAILABLE
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Confirm Award & Disburse'), findsNothing);
    expect(find.text('Confirm Award & Schedule Disbursement'), findsNothing);

    // Now resolve completer
    completer.complete(null);
    await tester.pumpAndSettle();

    // Award action is now available
    expect(find.text('Confirm Award & Disburse'), findsOneWidget);
  });

  testWidgets('Lookup error shows understandable error and retry action; keeps award action unavailable', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAppDs = FakeApplicationDataSource();
    fakeAppDs.disbursementFetchError = Exception('Simulated network timeout querying disbursements');
    final repo = ApplicationRepository(dataSource: fakeAppDs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('admin-1'),
          applicationRepositoryProvider.overrideWithValue(repo),
          adminApplicationsProvider.overrideWith((ref) => Future.value([sampleApp1])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminApplicantsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open dossier
    await tester.tap(find.text('Inspect Dossier'));
    await tester.pumpAndSettle();

    // Verify error UI is displayed
    expect(find.text('Unable to verify disbursement record. Please try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Award action MUST be completely unavailable
    expect(find.text('Confirm Award & Disburse'), findsNothing);
    expect(find.text('Confirm Award & Schedule Disbursement'), findsNothing);

    // Verify tapping close closes dialog without invoking mutation
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Award & Schedule Disbursement'), findsNothing);
  });

  testWidgets('Retry action refetches and transitions from error to success when resolved', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAppDs = FakeApplicationDataSource();
    fakeAppDs.disbursementFetchError = Exception('Transient connection drop');
    final repo = ApplicationRepository(dataSource: fakeAppDs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('admin-1'),
          applicationRepositoryProvider.overrideWithValue(repo),
          adminApplicationsProvider.overrideWith((ref) => Future.value([sampleApp1])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminApplicantsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open dossier
    await tester.tap(find.text('Inspect Dossier'));
    await tester.pumpAndSettle();

    // Initially in error state
    expect(find.text('Unable to verify disbursement record. Please try again.'), findsOneWidget);
    expect(find.text('Confirm Award & Disburse'), findsNothing);

    // Clear error
    fakeAppDs.disbursementFetchError = null;

    // Tap Retry
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Error is dismissed and award button appears
    expect(find.text('Unable to verify disbursement record. Please try again.'), findsNothing);
    expect(find.text('Confirm Award & Disburse'), findsOneWidget);

    // Action can now be executed
    await tester.tap(find.text('Confirm Award & Disburse'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Award & Schedule Disbursement'), findsOneWidget);
  });

  testWidgets('Existing disbursement record prevents duplicate action', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAppDs = FakeApplicationDataSource();
    fakeAppDs.disbursements.add({
      'id': 'disb-existing-101',
      'application_id': sampleApp1.id,
      'amount': 50000,
      'status': 'released',
    });
    final repo = ApplicationRepository(dataSource: fakeAppDs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('admin-1'),
          applicationRepositoryProvider.overrideWithValue(repo),
          adminApplicationsProvider.overrideWith((ref) => Future.value([sampleApp1])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminApplicantsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open dossier
    await tester.tap(find.text('Inspect Dossier'));
    await tester.pumpAndSettle();

    // Shows record indicator and prevents duplicate award trigger
    expect(find.text('● Disbursement on record'), findsOneWidget);
    expect(find.text('Confirm Award & Disburse'), findsNothing);
  });

  testWidgets('Non-approved application does not show award action in dossier', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAppDs = FakeApplicationDataSource();
    final repo = ApplicationRepository(dataSource: fakeAppDs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('admin-1'),
          applicationRepositoryProvider.overrideWithValue(repo),
          adminApplicationsProvider.overrideWith((ref) => Future.value([sampleApp2])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminApplicantsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maria Santos'), findsOneWidget);

    // Open dossier for submitted application
    await tester.tap(find.text('Inspect Dossier'));
    await tester.pumpAndSettle();

    // 'Confirm Award & Disburse' should NOT be present for submitted status
    expect(find.text('Confirm Award & Disburse'), findsNothing);
    expect(find.text('Close'), findsOneWidget);

    // Close dossier
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });
}
