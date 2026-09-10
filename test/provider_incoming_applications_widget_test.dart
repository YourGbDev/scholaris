import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/features/provider/presentation/provider_incoming_applications.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

class _MockApplicationRepository implements ApplicationRepository {
  ApplicationStatus? lastUpdatedStatus;
  String? lastUpdatedId;

  @override
  Future<List<Application>> fetchIncomingApplications() async {
    return [
      const Application(
        id: 'app-3',
        userId: 'applicant-3',
        scholarshipId: 'sch-1',
        status: ApplicationStatus.submitted,
      )
    ];
  }

  @override
  Future<void> updateStatus(String applicationId, ApplicationStatus status) async {
    lastUpdatedId = applicationId;
    lastUpdatedStatus = status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildApp({
    required FakeApplicationDataSource applications,
    required FakeScholarshipDataSource scholarships,
    required FakeProfileDataSource profiles,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('prov-1'),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(
            dataSource: applications,
            currentUserId: () => 'prov-1',
          ),
        ),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(
            dataSource: scholarships,
          ),
        ),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(
            dataSource: profiles,
            currentUserId: () => 'prov-1',
          ),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ProviderIncomingApplications()),
      ),
    );
  }

  Widget buildAppWithRepo(ApplicationRepository repo, {required FakeScholarshipDataSource scholarships, required FakeProfileDataSource profiles}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('prov-1'),
        applicationRepositoryProvider.overrideWithValue(repo),
        scholarshipRepositoryProvider.overrideWith((ref) => ScholarshipRepository(dataSource: scholarships)),
        profileRepositoryProvider.overrideWith((ref) => ProfileRepository(dataSource: profiles, currentUserId: () => 'prov-1')),
      ],
      child: const MaterialApp(home: Scaffold(body: ProviderIncomingApplications())),
    );
  }

  testWidgets('tapping a submitted row shows Under review/Approved/Rejected options', (tester) async {
    final applications = FakeApplicationDataSource();
    applications.scholarshipIndex['sch-1'] = {'id': 'sch-1', 'created_by': 'prov-1'};
    await applications.insertApplication('applicant-1', {
      'user_id': 'applicant-1',
      'scholarship_id': 'sch-1',
      'status': 'submitted',
    });

    final scholarships = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'Test Scholarship',
      }
    ]);

    final profiles = FakeProfileDataSource();
    profiles.rows['applicant-1'] = {'id': 'applicant-1', 'full_name': 'Juan Dela Cruz'};

    await tester.pumpWidget(buildApp(
      applications: applications,
      scholarships: scholarships,
      profiles: profiles,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Scholarship'));
    await tester.pumpAndSettle();

    expect(find.text('Update Application Status'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
  });

  testWidgets('tapping an approved row does nothing', (tester) async {
    final applications = FakeApplicationDataSource();
    applications.scholarshipIndex['sch-1'] = {'id': 'sch-1', 'created_by': 'prov-1'};
    await applications.insertApplication('applicant-2', {
      'user_id': 'applicant-2',
      'scholarship_id': 'sch-1',
      'status': 'approved',
    });

    final scholarships = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'Test Scholarship',
      }
    ]);

    final profiles = FakeProfileDataSource();
    profiles.rows['applicant-2'] = {'id': 'applicant-2', 'full_name': 'Maria Santos'};

    await tester.pumpWidget(buildApp(
      applications: applications,
      scholarships: scholarships,
      profiles: profiles,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Scholarship'));
    await tester.pumpAndSettle();

    expect(find.text('Update Application Status'), findsNothing);
  });

  testWidgets('selecting Under review updates status directly without confirmation dialog', (tester) async {
    final mockRepo = _MockApplicationRepository();

    final scholarships = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'Test Scholarship',
      }
    ]);

    final profiles = FakeProfileDataSource();
    profiles.rows['applicant-3'] = {'id': 'applicant-3', 'full_name': 'Jose Rizal'};

    await tester.pumpWidget(buildAppWithRepo(
      mockRepo,
      scholarships: scholarships,
      profiles: profiles,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Scholarship'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Under review'));
    await tester.pumpAndSettle();

    // No dialog shown, directly updated
    expect(find.byType(AlertDialog), findsNothing);
    expect(mockRepo.lastUpdatedId, 'app-3');
    expect(mockRepo.lastUpdatedStatus, ApplicationStatus.underReview);
  });

  testWidgets('selecting Approved shows confirmation dialog and Cancel aborts update', (tester) async {
    final mockRepo = _MockApplicationRepository();

    final scholarships = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'Test Scholarship',
      }
    ]);

    final profiles = FakeProfileDataSource();
    profiles.rows['applicant-3'] = {'id': 'applicant-3', 'full_name': 'Jose Rizal'};

    await tester.pumpWidget(buildAppWithRepo(
      mockRepo,
      scholarships: scholarships,
      profiles: profiles,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Scholarship'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approved'));
    await tester.pumpAndSettle();

    // Confirmation dialog is shown
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Approve Application'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog dismissed and no update was made
    expect(find.byType(AlertDialog), findsNothing);
    expect(mockRepo.lastUpdatedStatus, isNull);
  });

  testWidgets('selecting Approved shows confirmation dialog and Confirm updates status', (tester) async {
    final mockRepo = _MockApplicationRepository();

    final scholarships = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'Test Scholarship',
      }
    ]);

    final profiles = FakeProfileDataSource();
    profiles.rows['applicant-3'] = {'id': 'applicant-3', 'full_name': 'Jose Rizal'};

    await tester.pumpWidget(buildAppWithRepo(
      mockRepo,
      scholarships: scholarships,
      profiles: profiles,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Scholarship'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approved'));
    await tester.pumpAndSettle();

    // Tap confirm action button inside AlertDialog
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(mockRepo.lastUpdatedId, 'app-3');
    expect(mockRepo.lastUpdatedStatus, ApplicationStatus.approved);
  });

  testWidgets('selecting Rejected shows confirmation dialog and Confirm updates status', (tester) async {
    final mockRepo = _MockApplicationRepository();

    final scholarships = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'Test Scholarship',
      }
    ]);

    final profiles = FakeProfileDataSource();
    profiles.rows['applicant-3'] = {'id': 'applicant-3', 'full_name': 'Jose Rizal'};

    await tester.pumpWidget(buildAppWithRepo(
      mockRepo,
      scholarships: scholarships,
      profiles: profiles,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Scholarship'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rejected'));
    await tester.pumpAndSettle();

    // Tap confirm action button inside AlertDialog
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Reject Application'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
    await tester.pumpAndSettle();

    expect(mockRepo.lastUpdatedId, 'app-3');
    expect(mockRepo.lastUpdatedStatus, ApplicationStatus.rejected);
  });

  testWidgets('tapping a submitted row shows applicant credentials card in sheet', (tester) async {
    final applications = FakeApplicationDataSource();
    applications.scholarshipIndex['sch-1'] = {'id': 'sch-1', 'created_by': 'prov-1'};
    await applications.insertApplication('applicant-1', {
      'user_id': 'applicant-1',
      'scholarship_id': 'sch-1',
      'status': 'submitted',
    });

    final scholarships = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'Test Scholarship',
      }
    ]);

    final profiles = FakeProfileDataSource();
    profiles.rows['applicant-1'] = {
      'id': 'applicant-1',
      'full_name': 'Juan Dela Cruz',
      'course': 'BS Computer Science',
      'school': 'University of the Philippines',
      'year_level': 3,
      'gpa': 3.5,
      'region': 'NCR',
      'nationality': 'Filipino',
    };

    await tester.pumpWidget(buildApp(
      applications: applications,
      scholarships: scholarships,
      profiles: profiles,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Scholarship'));
    await tester.pumpAndSettle();

    expect(find.text('Juan Dela Cruz'), findsWidgets);
    expect(find.text('BS Computer Science'), findsOneWidget);
    expect(find.text('University of the Philippines'), findsOneWidget);
    expect(find.text('Year 3 · GPA 3.5'), findsOneWidget);
    expect(find.text('NCR'), findsOneWidget);
  });

  testWidgets('applicant note renders in credentials card when present', (tester) async {
    final applications = FakeApplicationDataSource();
    applications.scholarshipIndex['sch-1'] = {'id': 'sch-1', 'created_by': 'prov-1'};
    await applications.insertApplication('applicant-1', {
      'user_id': 'applicant-1',
      'scholarship_id': 'sch-1',
      'status': 'submitted',
      'notes': 'I am passionate about software engineering.',
    });

    final scholarships = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'Test Scholarship',
      }
    ]);

    final profiles = FakeProfileDataSource();
    profiles.rows['applicant-1'] = {
      'id': 'applicant-1',
      'full_name': 'Juan Dela Cruz',
      'course': 'BS Computer Science',
      'year_level': 3,
      'gpa': 3.5,
      'region': 'NCR',
      'nationality': 'Filipino',
    };

    await tester.pumpWidget(buildApp(
      applications: applications,
      scholarships: scholarships,
      profiles: profiles,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Scholarship'));
    await tester.pumpAndSettle();

    expect(find.text('Applicant Note'), findsOneWidget);
    expect(find.text('I am passionate about software engineering.'), findsOneWidget);
  });

  testWidgets('status filter chips filter the applications list and show empty state when no matches', (tester) async {
    final applications = FakeApplicationDataSource();
    applications.scholarshipIndex['sch-1'] = {'id': 'sch-1', 'created_by': 'prov-1'};
    await applications.insertApplication('applicant-1', {
      'user_id': 'applicant-1',
      'scholarship_id': 'sch-1',
      'status': 'submitted',
    });
    await applications.insertApplication('applicant-2', {
      'user_id': 'applicant-2',
      'scholarship_id': 'sch-1',
      'status': 'under_review',
    });

    final scholarships = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'Test Scholarship',
      }
    ]);

    final profiles = FakeProfileDataSource();
    profiles.rows['applicant-1'] = {
      'id': 'applicant-1',
      'full_name': 'Juan Dela Cruz',
      'course': 'BS CS',
      'year_level': 2,
      'gpa': 3.0,
      'region': 'NCR',
      'nationality': 'Filipino',
    };
    profiles.rows['applicant-2'] = {
      'id': 'applicant-2',
      'full_name': 'Maria Santos',
      'course': 'BS IT',
      'year_level': 3,
      'gpa': 3.2,
      'region': 'NCR',
      'nationality': 'Filipino',
    };

    await tester.pumpWidget(buildApp(
      applications: applications,
      scholarships: scholarships,
      profiles: profiles,
    ));
    await tester.pumpAndSettle();

    // Verify filter chips exist
    expect(find.byKey(const ValueKey('provider-filter-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('provider-filter-submitted')), findsOneWidget);
    expect(find.byKey(const ValueKey('provider-filter-under_review')), findsOneWidget);
    expect(find.byKey(const ValueKey('provider-filter-approved')), findsOneWidget);

    // Filter by Submitted
    await tester.ensureVisible(find.byKey(const ValueKey('provider-filter-submitted')));
    await tester.tap(find.byKey(const ValueKey('provider-filter-submitted')));
    await tester.pumpAndSettle();

    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Maria Santos'), findsNothing);

    // Filter by Approved (0 items)
    await tester.ensureVisible(find.byKey(const ValueKey('provider-filter-approved')));
    await tester.tap(find.byKey(const ValueKey('provider-filter-approved')));
    await tester.pumpAndSettle();

    expect(find.text('No approved applications'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsNothing);
    expect(find.text('Maria Santos'), findsNothing);

    // Back to All
    await tester.ensureVisible(find.byKey(const ValueKey('provider-filter-all')));
    await tester.tap(find.byKey(const ValueKey('provider-filter-all')));
    await tester.pumpAndSettle();

    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
  });

  testWidgets('renders queue summary bar with Total, Pending, and Decided counts and shows Review affordance', (tester) async {
    final applications = FakeApplicationDataSource();
    applications.scholarshipIndex['sch-1'] = {'id': 'sch-1', 'created_by': 'prov-1'};
    await applications.insertApplication('applicant-1', {
      'user_id': 'applicant-1',
      'scholarship_id': 'sch-1',
      'status': 'submitted',
    });
    await applications.insertApplication('applicant-2', {
      'user_id': 'applicant-2',
      'scholarship_id': 'sch-1',
      'status': 'approved',
    });

    final scholarships = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'Test Scholarship',
      }
    ]);

    final profiles = FakeProfileDataSource();
    profiles.rows['applicant-1'] = {'id': 'applicant-1', 'full_name': 'Juan Dela Cruz'};
    profiles.rows['applicant-2'] = {'id': 'applicant-2', 'full_name': 'Maria Santos'};

    await tester.pumpWidget(buildApp(
      applications: applications,
      scholarships: scholarships,
      profiles: profiles,
    ));
    await tester.pumpAndSettle();

    // Summary bar pills
    expect(find.text('2 Total'), findsOneWidget);
    expect(find.text('1 Pending'), findsOneWidget);
    expect(find.text('1 Decided'), findsOneWidget);

    // Non-terminal application (Juan) shows Review affordance
    expect(find.text('Review'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });
}
