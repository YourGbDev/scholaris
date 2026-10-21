// test/critical_user_journeys_interaction_test.dart
//
// End-to-End interaction tests for Scholaris critical user journeys:
// 1. Student Application Submission Flow: Discover -> Details -> Pre-apply Dialog -> Affirmations -> Submit -> Applied State
// 2. Application Withdrawal Flow: Submitted -> Withdraw Action -> State Transition to Withdrawn & Guard Terminal States
// 3. Provider Benefactor Decision Flow: Drawer -> Direct Approve -> Confirmation Dialog -> State Update
// 4. Platform Admin Award Guard Flow: Award Action -> State Transition to Awarded
// 5. Profile Setup Account Switch Flow: Switch Button -> Confirmation Dialog -> Cancel / Confirm Sign-Out

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/profile/models/applicant_profile.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/presentation/widgets/profile_setup_account_switch.dart';
import 'package:scholaris/features/profile/providers/avatar_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/provider/presentation/widgets/applicant_review_drawer.dart';
import 'package:scholaris/features/provider/providers/provider_sub_role_provider.dart';
import 'package:scholaris/features/provider/providers/provider_type_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

class _FakeReviewBenefactorSource extends FakeApplicationDataSource {
  @override
  Future<Map<String, dynamic>> reviewApplication(Map<String, dynamic> params) async {
    final id = params['p_application_id'] as String;
    final action = (params['p_action'] ?? params['p_decision']) as String;
    final newStatus = action == 'approve' ? 'approved' : 'rejected';
    await updateApplicationStatus(id, newStatus);
    final row = await fetchApplication('student-1', id);
    return row ?? {
      'id': id,
      'user_id': 'student-1',
      'scholarship_id': 'sch-journey-1',
      'status': newStatus,
    };
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final futureDeadline = DateTime.now().add(const Duration(days: 30));

  final testScholarship = Scholarship(
    id: 'sch-journey-1',
    title: 'Philippine STEM Leadership Grant',
    provider: 'DOST-SEI',
    description: 'Empowering future scientists and engineers.',
    deadline: futureDeadline,
    minGpa: 85.0,
    requiredYearLevels: const [1, 2, 3, 4],
    requiredCourses: const ['BS Computer Science'],
    locationRestriction: 'NCR',
    maxMonthlyIncome: 50000,
    slots: 10,
    isActive: true,
  );

  final testStudentProfile = StudentProfile(
    id: 'student-1',
    fullName: 'Maria Santos',
    gender: 'female',
    gpa: 90.0,
    gpaScale: 'percentage',
    yearLevel: 2,
    course: 'BS Computer Science',
    region: 'NCR',
    monthlyFamilyIncome: 25000,
    setupComplete: true,
  );

  group('Journey 1: Student Application Submission Interaction', () {
    testWidgets(
      'Eligible student taps Start Application, affirms certifications, confirms submit, and sees applied state',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final profileSource = FakeProfileDataSource();
        profileSource.upsertProfile('student-1', testStudentProfile.toDbRow());

        final appSource = FakeApplicationDataSource();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWithValue('student-1'),
              currentProfileProvider.overrideWith((ref) async => testStudentProfile),
              avatarProvider('student-1').overrideWith(
                (ref) => AvatarNotifier(
                  userId: 'student-1',
                  initialState: const AvatarState(
                    avatarId: 'verified_photo',
                    isRealPhoto: true,
                  ),
                ),
              ),
              profileRepositoryProvider.overrideWith(
                (ref) => ProfileRepository(
                  dataSource: profileSource,
                  currentUserId: () => 'student-1',
                ),
              ),
              applicationRepositoryProvider.overrideWith(
                (ref) => ApplicationRepository(
                  dataSource: appSource,
                  currentUserId: () => 'student-1',
                ),
              ),
              bookmarkRepositoryProvider.overrideWith(
                (ref) => BookmarkRepository(
                  dataSource: FakeBookmarkDataSource(),
                  currentUserId: () => 'student-1',
                ),
              ),
              scholarshipRepositoryProvider.overrideWith(
                (ref) => ScholarshipRepository(
                  dataSource: FakeScholarshipDataSource(),
                ),
              ),
            ],
            child: MaterialApp(
              home: ScholarshipDetailScreen(
                scholarshipId: testScholarship.id,
                initial: testScholarship,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify "Start Application" button is visible and tap it
        final startButton = find.widgetWithText(ElevatedButton, 'Start Application');
        expect(startButton, findsOneWidget);
        await tester.tap(startButton);
        await tester.pumpAndSettle();

        // 2. Verify pre-apply review dialog opens
        expect(find.text('Affirmations & Honor Code'), findsOneWidget);

        // 3. Affirm all 3 certifications by tapping the checkboxes
        final checkboxes = find.byType(Checkbox);
        expect(checkboxes, findsNWidgets(3));
        for (int i = 0; i < 3; i++) {
          await tester.ensureVisible(checkboxes.at(i));
          await tester.pumpAndSettle();
          await tester.tap(checkboxes.at(i));
          await tester.pumpAndSettle();
        }

        // 4. Tap "Submit Application (Final)" button
        final submitButton = find.byKey(const ValueKey('apply-confirm'));
        expect(submitButton, findsOneWidget);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // 5. Verify application was created in repository
        final userApps = await appSource.fetchApplications('student-1');
        expect(userApps, isNotEmpty);
        expect(userApps.first['scholarship_id'], 'sch-journey-1');
        expect(userApps.first['status'], 'submitted');

        // 6. Verify SnackBar feedback
        expect(find.text('Application submitted!'), findsOneWidget);
      },
    );
  });

  group('Journey 2: Application Withdrawal Interaction & Terminal Guards', () {
    test('Student can withdraw pending application, and terminal applications cannot be withdrawn', () async {
      final appSource = FakeApplicationDataSource();
      final inserted = await appSource.insertApplication('student-1', {
        'user_id': 'student-1',
        'scholarship_id': 'sch-journey-1',
        'status': 'submitted',
        'applied_at': DateTime.now().toIso8601String(),
      });
      final appId = inserted['id'] as String;

      final repo = ApplicationRepository(
        dataSource: appSource,
        currentUserId: () => 'student-1',
      );

      // Verify withdrawal transitions status to withdrawn
      await repo.withdraw(appId);

      final updated = await appSource.fetchApplication('student-1', appId);
      expect(updated?['status'], 'withdrawn');

      // Verify terminal guard: already withdrawn application throws ApplicationWithdrawalException
      expect(
        () async => await repo.withdraw(appId),
        throwsA(isA<ApplicationWithdrawalException>()),
      );
    });
  });

  group('Journey 3: Provider Benefactor Decision Interaction', () {
    testWidgets(
      'Individual benefactor taps Approve Application, confirms in modal, and callback updates status',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final applications = _FakeReviewBenefactorSource();
        final inserted = await applications.insertApplication('student-1', {
          'user_id': 'student-1',
          'scholarship_id': 'sch-journey-1',
          'status': 'submitted',
          'applied_at': DateTime.now().toIso8601String(),
        });
        final appId = inserted['id'] as String;

        final application = Application(
          id: appId,
          userId: 'student-1',
          scholarshipId: 'sch-journey-1',
          status: ApplicationStatus.submitted,
          appliedAt: DateTime.now(),
        );

        final applicantProfile = const ApplicantProfile(
          id: 'student-1',
          fullName: 'Maria Santos',
          school: 'UP Diliman',
          course: 'BS Computer Science',
          yearLevel: 2,
          gpa: 90.0,
        );

        bool callbackFired = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWithValue('benefactor-1'),
              currentProfileProvider.overrideWith((ref) async => const StudentProfile(
                id: 'benefactor-1',
                fullName: 'Atty. Santos Benefactor',
                role: 'provider',
                setupComplete: true,
              )),
              organizationMembershipProvider.overrideWith((ref) async => null),
              providerTypeOverrideProvider.overrideWith((ref) => 'individual'),
              applicationRepositoryProvider.overrideWith((ref) => ApplicationRepository(
                dataSource: applications,
                currentUserId: () => 'benefactor-1',
              )),
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
                        applicantProfile: applicantProfile,
                        onStatusChanged: () => callbackFired = true,
                      );
                    },
                    child: const Text('Open Review Drawer'),
                  ),
                ),
              ),
            ),
          ),
        );

        // 1. Open Review Drawer
        await tester.tap(find.text('Open Review Drawer'));
        await tester.pumpAndSettle();

        // 2. Verify direct action button is present and tap 'Approve Application'
        final approveButton = find.text('Approve Application');
        expect(approveButton, findsOneWidget);
        await tester.tap(approveButton);
        await tester.pumpAndSettle();

        // 3. Verify confirmation modal is shown
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Confirm Decision'), findsOneWidget);

        // 4. Tap confirmation button
        final confirmButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        );
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        // 5. Verify status callback executed and record updated
        expect(callbackFired, isTrue);
        final updatedApp = await applications.fetchApplication('student-1', appId);
        expect(updatedApp?['status'], 'approved');
      },
    );
  });

  group('Journey 4: Platform Admin Award Flow', () {
    test('Admin confirms award on approved application, transitioning status to awarded', () async {
      final appSource = FakeApplicationDataSource();
      final inserted = await appSource.insertApplication('student-1', {
        'user_id': 'student-1',
        'scholarship_id': 'sch-journey-1',
        'status': 'approved',
        'applied_at': DateTime.now().toIso8601String(),
      });
      final appId = inserted['id'] as String;

      final repo = ApplicationRepository(
        dataSource: appSource,
        currentUserId: () => 'admin-1',
      );

      // Confirm award
      await repo.confirmAward(appId);

      final updated = await appSource.fetchApplication('student-1', appId);
      expect(updated?['status'], 'awarded');
    });
  });

  group('Journey 5: Account Switching & Failure Recovery Interaction', () {
    testWidgets(
      'User can open account switch dialog, cancel to keep session, or confirm to sign out',
      (tester) async {
        int signoutCount = 0;
        int navigationCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              profileSetupSignOutProvider.overrideWithValue(() async {
                signoutCount++;
              }),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ProfileSetupAccountSwitch(
                  onSignedOut: () => navigationCount++,
                ),
              ),
            ),
          ),
        );

        // 1. Tap action button
        await tester.tap(find.text('Use a different account'));
        await tester.pumpAndSettle();

        // 2. Cancel preserves session
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(signoutCount, 0);
        expect(navigationCount, 0);

        // 3. Tap again and confirm sign out
        await tester.tap(find.text('Use a different account'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log Out'));
        await tester.pumpAndSettle();

        expect(signoutCount, 1);
        expect(navigationCount, 1);
      },
    );
  });
}
