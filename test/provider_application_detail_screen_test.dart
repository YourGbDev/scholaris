import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/provider/presentation/provider_application_detail_screen.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

void main() {
  Widget buildApp({
    required Application application,
    required Scholarship scholarship,
    required StudentProfile profile,
  }) {
    final appDs = FakeApplicationDataSource();
    final schDs = FakeScholarshipDataSource([
      {
        ...FakeScholarshipDataSource.defaultRows.first,
        'id': scholarship.id,
        'title': scholarship.title,
        'min_gpa': scholarship.minGpa,
      }
    ]);
    final profDs = FakeProfileDataSource();
    profDs.rows[profile.id] = {
      'id': profile.id,
      'full_name': profile.fullName,
      'course': profile.course,
      'school': profile.school,
      'year_level': profile.yearLevel,
      'gpa': profile.gpa,
      'region': profile.region,
      'nationality': profile.nationality,
    };

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('prov-1'),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(
            dataSource: appDs,
            currentUserId: () => 'prov-1',
          ),
        ),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(dataSource: schDs),
        ),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(
            dataSource: profDs,
            currentUserId: () => 'prov-1',
          ),
        ),
      ],
      child: MaterialApp(
        home: ProviderApplicationDetailScreen(
          applicationId: application.id,
          initialApplication: application,
          initialScholarship: scholarship,
          initialProfile: profile,
        ),
      ),
    );
  }

  group('ProviderApplicationDetailScreen', () {
    testWidgets('renders all Stitch review sections correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const app = Application(
        id: 'app-1',
        userId: 'student-1',
        scholarshipId: 'sch-1',
        status: ApplicationStatus.submitted,
        notes: 'Passionate about artificial intelligence and open source.',
      );

      final sch = Scholarship(
        id: 'sch-1',
        title: 'DOST-SEI Merit Scholarship',
        minGpa: 1.75,
        deadline: DateTime(2026, 11, 15),
      );

      final profile = StudentProfile(
        id: 'student-1',
        fullName: 'Maya Santos Dela Cruz',
        course: 'BS Computer Science',
        school: 'University of the Philippines Diliman',
        yearLevel: 2,
        gpa: 1.45,
        region: 'National Capital Region (NCR)',
        nationality: 'Filipino',
      );

      await tester.pumpWidget(buildApp(
        application: app,
        scholarship: sch,
        profile: profile,
      ));
      await tester.pumpAndSettle();

      // Header & Sub-Header
      expect(find.text('Application Review'), findsOneWidget);
      expect(find.text('Back to Console'), findsOneWidget);
      expect(find.text('Maya Santos Dela Cruz'), findsOneWidget);
      expect(find.text('98% Match Score'), findsOneWidget);
      expect(find.text('STAGE: SUBMITTED'), findsOneWidget);

      // Section 1: Academic Credentials
      expect(find.text('Academic Credentials'), findsOneWidget);
      expect(find.text('Verified SUC'), findsOneWidget);
      expect(find.text('1.45'), findsOneWidget);
      expect(find.text('Exceeds 1.75 Merit Cutoff'), findsOneWidget);
      expect(find.text('University of the Philippines Diliman'), findsOneWidget);

      // Section 2: Socioeconomic Assessment
      expect(find.text('Socioeconomic Assessment'), findsOneWidget);
      expect(find.textContaining('RA 10173 Compliance'), findsOneWidget);
      expect(find.text('Verified Tier 2: Low-to-Middle Income Bracket'), findsOneWidget);

      // Section 3: Document Checklist
      await tester.ensureVisible(find.text('Document Audit Checklist'));
      await tester.pumpAndSettle();
      expect(find.text('Document Audit Checklist'), findsOneWidget);
      expect(find.text('Certified True Copy of Grades (TCG)'), findsOneWidget);
      expect(find.text('Applicant Statement / Note'), findsOneWidget);
      expect(find.text('Passionate about artificial intelligence and open source.'), findsOneWidget);

      // Sticky Action Bar
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Request Docs'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
    });

    testWidgets('tapping Approve shows confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const app = Application(
        id: 'app-2',
        userId: 'student-2',
        scholarshipId: 'sch-1',
        status: ApplicationStatus.underReview,
      );

      final sch = Scholarship(
        id: 'sch-1',
        title: 'DOST-SEI Merit Scholarship',
        minGpa: 1.75,
        deadline: DateTime(2026, 11, 15),
      );

      final profile = StudentProfile(
        id: 'student-2',
        fullName: 'Joshua Paolo Reyes',
        course: 'BS Electronics Eng',
        school: 'PUP Sta. Mesa',
        yearLevel: 3,
        gpa: 1.58,
        region: 'National Capital Region (NCR)',
        nationality: 'Filipino',
      );

      await tester.pumpWidget(buildApp(
        application: app,
        scholarship: sch,
        profile: profile,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Approve Application'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('adds a new deliberation remark', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const app = Application(
        id: 'app-3',
        userId: 'student-3',
        scholarshipId: 'sch-1',
        status: ApplicationStatus.underReview,
      );

      final sch = Scholarship(
        id: 'sch-1',
        title: 'DOST-SEI Merit Scholarship',
        minGpa: 1.75,
        deadline: DateTime(2026, 11, 15),
      );

      final profile = StudentProfile(
        id: 'student-3',
        fullName: 'Camille Anne Bautista',
        course: 'BS Chemistry',
        school: 'Ateneo de Manila',
        yearLevel: 1,
        gpa: 1.70,
        region: 'National Capital Region (NCR)',
        nationality: 'Filipino',
      );

      await tester.pumpWidget(buildApp(
        application: app,
        scholarship: sch,
        profile: profile,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Add internal reviewer evaluation or conditional remarks...'),
        'Interview scheduled with regional committee.',
      );
      await tester.pumpAndSettle();

      final saveBtn = find.text('Save Remark');
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();

      await tester.tap(saveBtn);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Interview scheduled with regional committee.'), findsOneWidget);
    });
  });
}
