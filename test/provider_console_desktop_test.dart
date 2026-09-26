import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_shell.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

void main() {
  Widget buildApp() {
    final fakeProfileDs = FakeProfileDataSource();
    fakeProfileDs.rows['prov-1'] = {
      'id': 'prov-1',
      'email': 'ayala.provider@scholaris.ph',
      'full_name': 'Ayala Foundation Inc.',
      'role': 'provider',
      'status': 'active',
      'setup_complete': true,
      'region': 'NCR',
      'provider_type': 'organization',
    };
    fakeProfileDs.rows['stud-1'] = {
      'id': 'stud-1',
      'email': 'sofia@example.com',
      'full_name': 'Sofia Cruz',
      'role': 'student',
      'status': 'active',
      'setup_complete': true,
      'school': 'University of Santo Tomas',
      'course': 'BS Nursing',
      'gpa': 1.30,
      'year_level': 3,
      'region': 'NCR',
    };

    final fakeAppDs = FakeApplicationDataSource();
    fakeAppDs.scholarshipIndex['sch-1'] = {
      'id': 'sch-1',
      'title': 'Ayala Future Leaders STEM Grant 2026',
      'created_by': 'prov-1',
      'award_amount': 50000,
    };
    fakeAppDs.insertApplication('stud-1', {
      'user_id': 'stud-1',
      'scholarship_id': 'sch-1',
      'status': 'submitted',
    });

    final fakeScholDs = FakeScholarshipDataSource([
      {
        'id': 'sch-1',
        'title': 'Ayala Future Leaders STEM Grant 2026',
        'description': 'Test description',
        'award_amount': 50000,
        'deadline': '2026-12-31T00:00:00Z',
        'tags': ['STEM'],
        'is_active': true,
        'created_by': 'prov-1',
      }
    ]);

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('prov-1'),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(
            dataSource: fakeProfileDs,
            currentUserId: () => 'prov-1',
          ),
        ),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(
            dataSource: fakeScholDs,
          ),
        ),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(
            dataSource: fakeAppDs,
            currentUserId: () => 'prov-1',
          ),
        ),
      ],
      child: const MaterialApp(
        home: OrgProviderShell(),
      ),
    );
  }

  testWidgets('OrgProviderShell renders at 1920x1080 desktop width', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Top bar and workspace
    expect(find.text('Incoming Applications'), findsOneWidget);
    expect(find.text('AY 2024–2025 • Sem 1'), findsOneWidget);
    expect(find.text('New Grant'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsNWidgets(2));

    // KPI cards
    expect(find.text('Total Intake'), findsOneWidget);
    expect(find.text('Under Review'), findsOneWidget);
    expect(find.text('Confirmed Awardees'), findsOneWidget);

    // Applicant data
    expect(find.text('Sofia Cruz'), findsOneWidget);
    expect(find.text('Review Dossier'), findsOneWidget);
  });

  testWidgets('OrgProviderShell renders at 1366x768 common laptop desktop width', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Incoming Applications'), findsOneWidget);
    expect(find.text('AY 2024–2025 • Sem 1'), findsOneWidget);
    expect(find.text('New Grant'), findsOneWidget);
    expect(find.text('Sofia Cruz'), findsOneWidget);
    expect(find.text('Review Dossier'), findsOneWidget);
  });
}
