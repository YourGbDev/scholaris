import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/admin/presentation/admin_analytics_tab.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'package:scholaris/features/admin/presentation/admin_analytics_provider.dart';
import 'package:scholaris/features/applications/models/application.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

void main() {
  test('adminAnalyticsDataProvider aggregates counts and computes rates correctly', () async {
    final fakeProfileDs = FakeProfileDataSource();
    fakeProfileDs.rows['student-1'] = {
      'id': 'student-1',
      'full_name': 'Juan Dela Cruz',
      'school': 'UP Diliman',
      'region': 'NCR',
      'role': 'student',
    };
    fakeProfileDs.rows['student-2'] = {
      'id': 'student-2',
      'full_name': 'Maria Santos',
      'school': 'UP Diliman',
      'region': 'Region III',
      'role': 'student',
    };

    final fakeScholarshipDs = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-1',
        'title': 'Science Grant',
        'provider': 'DOST',
        'is_active': true,
      },
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': 'sch-2',
        'title': 'Arts Grant',
        'provider': 'NCCA',
        'is_active': false,
      },
    ]);

    final fakeAppDs = FakeApplicationDataSource();
    fakeAppDs.insertApplication('student-1', {
      'scholarship_id': 'sch-1',
      'status': 'approved',
    });
    fakeAppDs.insertApplication('student-2', {
      'scholarship_id': 'sch-1',
      'status': 'submitted',
    });

    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('admin-1'),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(dataSource: fakeProfileDs, currentUserId: () => 'admin-1'),
        ),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(dataSource: fakeScholarshipDs),
        ),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(dataSource: fakeAppDs, currentUserId: () => 'admin-1'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final analytics = await container.read(adminAnalyticsDataProvider.future);
    expect(analytics.totalApplications, 2);
    expect(analytics.totalScholarships, 1);
    expect(analytics.activeScholarships, 1);
    expect(analytics.totalApplicants, 2);
    expect(analytics.schoolCounts['UP Diliman'], 2);
    expect(analytics.regionCounts['NCR'], 1);
    expect(analytics.regionCounts['Region III'], 1);
    expect(analytics.acceptanceRate, 50.0);
  });

  testWidgets('AdminAnalyticsTab renders aggregated platform telemetry', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const testAnalytics = AdminAnalyticsData(
      totalApplications: 42,
      totalScholarships: 5,
      activeScholarships: 3,
      totalApplicants: 18,
      schoolCounts: {'UP Diliman': 12, 'Ateneo de Manila': 6},
      statusCounts: {
        ApplicationStatus.draft: 2,
        ApplicationStatus.submitted: 20,
        ApplicationStatus.underReview: 10,
        ApplicationStatus.approved: 8,
        ApplicationStatus.rejected: 2,
      },
      regionCounts: {'NCR': 15, 'Region III': 3},
      acceptanceRate: 19.0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminAnalyticsDataProvider.overrideWith((ref) => Future.value(testAnalytics)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminAnalyticsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Platform Analytics'), findsOneWidget);
    expect(find.text('Total applications'), findsOneWidget);
    expect(find.text('Participating schools'), findsOneWidget);
    expect(find.text('Institution breakdown'), findsOneWidget);
    expect(find.text('UP Diliman'), findsOneWidget);
    expect(find.text('Pipeline stage distribution'), findsOneWidget);
    expect(find.text('Regional coverage'), findsOneWidget);
  });
}
