import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/presentation/application_decision_letter.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/models/applicant_profile.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/provider/presentation/widgets/applicant_review_drawer.dart';
import 'package:scholaris/features/provider/providers/provider_sub_role_provider.dart';
import 'package:scholaris/features/provider/providers/provider_type_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';

import '../../helpers/fake_application_data_source.dart';

class _FakeBenefactorDataSource extends FakeApplicationDataSource {
  @override
  Future<Map<String, dynamic>> reviewApplication(
    Map<String, dynamic> params,
  ) async {
    final id = params['p_application_id'] as String;
    final action = (params['p_action'] ?? params['p_decision']) as String;
    final newStatus = action == 'approve' ? 'approved' : 'rejected';
    await updateApplicationStatus(id, newStatus);
    final row = await fetchApplication('student-1', id);
    return row ??
        {
          'id': id,
          'user_id': 'student-1',
          'scholarship_id': 'grant-indiv-1',
          'status': newStatus,
        };
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testScholarship = Scholarship(
    id: 'grant-indiv-1',
    title: 'Don Ramon Engineering Grant',
    provider: 'Don Ramon Benefactor',
    description: 'Direct benefactor funding for engineering undergraduates.',
    deadline: DateTime.now().add(const Duration(days: 30)),
    minGpa: 2.0,
    slots: 1,
  );

  final testApplicantProfile = const ApplicantProfile(
    id: 'student-1',
    fullName: 'Juan Dela Cruz',
    school: 'University of the Philippines Diliman',
    course: 'BS Computer Science',
    yearLevel: 2,
    gpa: 1.5,
  );

  group('Individual Provider Benefactor Decisioning & Drawer UI', () {
    testWidgets(
      'ApplicantReviewDrawer presents direct Approve Application action without endorsement gate',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final applications = _FakeBenefactorDataSource();
        await applications.insertApplication('student-1', {
          'id': 'app-1',
          'user_id': 'student-1',
          'scholarship_id': 'grant-indiv-1',
          'status': 'submitted',
          'applied_at': DateTime(2026, 10, 20).toUtc().toIso8601String(),
        });

        final application = Application(
          id: 'app-1',
          userId: 'student-1',
          scholarshipId: 'grant-indiv-1',
          status: ApplicationStatus.submitted,
          appliedAt: DateTime(2026, 10, 20),
        );

        bool statusChanged = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWithValue('indiv-provider-1'),
              currentProfileProvider.overrideWith(
                (ref) async => const StudentProfile(
                  id: 'indiv-provider-1',
                  fullName: 'Don Ramon Benefactor',
                  role: 'provider',
                  setupComplete: true,
                ),
              ),
              organizationMembershipProvider.overrideWith((ref) async => null),
              providerTypeOverrideProvider.overrideWith((ref) => 'individual'),
              applicationRepositoryProvider.overrideWith(
                (ref) => ApplicationRepository(
                  dataSource: applications,
                  currentUserId: () => 'indiv-provider-1',
                ),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      ApplicantReviewDrawer.show(
                        context,
                        application: application,
                        scholarship: testScholarship,
                        applicantProfile: testApplicantProfile,
                        onStatusChanged: () => statusChanged = true,
                      );
                    },
                    child: const Text('Open Review Drawer'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Open drawer
        await tester.tap(find.text('Open Review Drawer'));
        await tester.pumpAndSettle();

        // Verify that individual benefactor identity does NOT see reviewer endorsement notice
        expect(
          find.text('Awaiting a separate reviewer endorsement.'),
          findsNothing,
        );
        expect(find.text('Endorse to Org Admin for Decision'), findsNothing);

        // Verify that direct action buttons are available
        expect(find.text('Decline application'), findsOneWidget);
        expect(find.text('Approve Application'), findsOneWidget);

        // Tap 'Approve Application'
        await tester.tap(find.text('Approve Application'));
        await tester.pumpAndSettle();

        // Verify confirmation dialog opens
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Confirm Decision'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining(
              'Are you sure you want to Approve Application',
            ),
          ),
          findsOneWidget,
        );

        // Confirm decision in dialog
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();

        // Verify callback fired
        expect(statusChanged, isTrue);

        // Verify repository updated status to approved (NOT awarded)
        final updatedApp = await applications.fetchApplication(
          'student-1',
          'app-1',
        );
        expect(updatedApp!['status'], equals('approved'));
        expect(updatedApp['status'], isNot(equals('awarded')));
      },
    );

    testWidgets(
      'Decision letter displays correct date wording for approved vs awarded',
      (tester) async {
        // 1. Approved status test
        await tester.pumpWidget(
          MaterialApp(
            home: ApplicationDecisionLetter(
              application: Application(
                id: 'app-approved-1',
                userId: 'student-1',
                scholarshipId: 'grant-indiv-1',
                status: ApplicationStatus.approved,
                decidedAt: DateTime(2026, 10, 21),
              ),
              scholarshipTitle: 'Don Ramon Engineering Grant',
              providerName: 'Don Ramon Benefactor',
              studentName: 'Juan Dela Cruz',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Scholarship Approval Letter'), findsOneWidget);
        expect(
          find.text('Application approved on 21 Oct 2026'),
          findsOneWidget,
        );
        expect(find.text('Scholarship awarded on 21 Oct 2026'), findsNothing);

        // 2. Awarded status test
        await tester.pumpWidget(
          MaterialApp(
            home: ApplicationDecisionLetter(
              application: Application(
                id: 'app-awarded-1',
                userId: 'student-1',
                scholarshipId: 'grant-indiv-1',
                status: ApplicationStatus.awarded,
                decidedAt: DateTime(2026, 10, 21),
              ),
              scholarshipTitle: 'Don Ramon Engineering Grant',
              providerName: 'Don Ramon Benefactor',
              studentName: 'Juan Dela Cruz',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Scholarship Award Certificate'), findsOneWidget);
        expect(find.text('Scholarship awarded on 21 Oct 2026'), findsOneWidget);
        expect(find.text('Application approved on 21 Oct 2026'), findsNothing);
      },
    );
  });
}
