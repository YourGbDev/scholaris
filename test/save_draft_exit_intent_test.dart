// test/save_draft_exit_intent_test.dart
//
// Tests save-as-draft on exit intent, draft application state, resume/continue
// flow, and draft-to-submitted upgrade without duplicate exception.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/presentation/application_detail_screen.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/avatar_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/shared/widgets/save_draft_dialog.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

StudentProfile _student() => const StudentProfile(
      id: 'user-a',
      fullName: 'Maria Santos',
      nationality: 'Filipino',
      region: 'NCR',
      gpa: 3.2,
      yearLevel: 2,
      course: 'BS Computer Science',
      monthlyFamilyIncome: 15000,
      setupComplete: true,
    );

Scholarship _scholarship() =>
    Scholarship.fromJson(FakeScholarshipDataSource.defaultRows.first);

Widget _wrapScholarship({
  required Scholarship scholarship,
  FakeApplicationDataSource? applications,
}) {
  final profileSource = FakeProfileDataSource();
  profileSource.upsertProfile('user-a', _student().toDbRow());

  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-a'),
      avatarProvider('user-a').overrideWith(
        (ref) => AvatarNotifier(
          userId: 'user-a',
          initialState: const AvatarState(
            avatarId: 'verified_photo',
            isRealPhoto: true,
          ),
        ),
      ),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: profileSource,
          currentUserId: () => 'user-a',
        ),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: applications ?? FakeApplicationDataSource(),
          currentUserId: () => 'user-a',
        ),
      ),
      bookmarkRepositoryProvider.overrideWith(
        (ref) => BookmarkRepository(
          dataSource: FakeBookmarkDataSource(),
          currentUserId: () => 'user-a',
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) => ScholarshipRepository(dataSource: FakeScholarshipDataSource()),
      ),
    ],
    child: MaterialApp(
      home: ScholarshipDetailScreen(
        scholarshipId: scholarship.id,
        initial: scholarship,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('showSaveDraftExitDialog unit/widget tests', () {
    testWidgets('renders dialog and handles Cancel, Discard, and Save as Draft',
        (tester) async {
      SaveDraftExitAction? actionResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  actionResult = await showSaveDraftExitDialog(context);
                },
                child: const Text('Exit Intent'),
              ),
            ),
          ),
        ),
      );

      // 1. Test Cancel
      await tester.tap(find.text('Exit Intent'));
      await tester.pumpAndSettle();

      expect(find.text('Save your progress?'), findsOneWidget);
      expect(find.byKey(const ValueKey('exit-dialog-cancel')), findsOneWidget);
      expect(find.byKey(const ValueKey('exit-dialog-discard')), findsOneWidget);
      expect(find.byKey(const ValueKey('exit-dialog-save-draft')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('exit-dialog-cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Save your progress?'), findsNothing);
      expect(actionResult, SaveDraftExitAction.cancel);

      // 2. Test Discard
      await tester.tap(find.text('Exit Intent'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('exit-dialog-discard')));
      await tester.pumpAndSettle();

      expect(find.text('Save your progress?'), findsNothing);
      expect(actionResult, SaveDraftExitAction.discard);

      // 3. Test Save as Draft
      await tester.tap(find.text('Exit Intent'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('exit-dialog-save-draft')));
      await tester.pumpAndSettle();

      expect(find.text('Save your progress?'), findsNothing);
      expect(actionResult, SaveDraftExitAction.saveAsDraft);
    });
  });

  group('ScholarshipDetailScreen Save-as-Draft & Resume Flow', () {
    testWidgets('tapping Save as Draft in pre-apply dialog creates draft application',
        (tester) async {
      final applications = FakeApplicationDataSource();

      await tester.pumpWidget(
        _wrapScholarship(scholarship: _scholarship(), applications: applications),
      );
      await tester.pumpAndSettle();

      // Tap Apply now
      await tester.tap(find.text('Apply now'));
      await tester.pumpAndSettle();

      expect(find.text('Apply to this scholarship?'), findsOneWidget);
      expect(find.byKey(const ValueKey('apply-save-draft')), findsOneWidget);

      // Tap Save as Draft
      await tester.tap(find.byKey(const ValueKey('apply-save-draft')));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Apply to this scholarship?'), findsNothing);

      // Application is persisted with status 'draft'
      final rows = await applications.fetchApplications('user-a');
      expect(rows, hasLength(1));
      expect(rows.single['scholarship_id'], _scholarship().id);
      expect(rows.single['status'], 'draft');

      // Scholarship detail now renders Draft in progress banner with Continue Application
      expect(find.text('DRAFT IN PROGRESS'), findsOneWidget);
      expect(find.text('You have a saved draft'), findsOneWidget);
      expect(find.byKey(const ValueKey('continue-application')), findsOneWidget);
    });

    testWidgets('closing pre-apply dialog opens exit-intent dialog',
        (tester) async {
      final applications = FakeApplicationDataSource();

      await tester.pumpWidget(
        _wrapScholarship(scholarship: _scholarship(), applications: applications),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply now'));
      await tester.pumpAndSettle();

      // Tap close button in modal header
      final closeBtn = find.byKey(const ValueKey('apply-close-button'));
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Exit-intent dialog is presented
      expect(find.text('Save your progress?'), findsOneWidget);

      // Tap Cancel -> stays on the review dialog
      await tester.tap(find.byKey(const ValueKey('exit-dialog-cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Save your progress?'), findsNothing);
      expect(find.text('Apply to this scholarship?'), findsOneWidget);

      // Tap close again and Discard -> closes review dialog without saving
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('exit-dialog-discard')));
      await tester.pumpAndSettle();

      expect(find.text('Apply to this scholarship?'), findsNothing);
      expect(await applications.fetchApplications('user-a'), isEmpty);
    });

    testWidgets('tapping Continue Application resumes review and submitting upgrades draft',
        (tester) async {
      final applications = FakeApplicationDataSource();
      // Pre-seed a draft application
      await applications.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': _scholarship().id,
        'status': 'draft',
      });

      await tester.pumpWidget(
        _wrapScholarship(scholarship: _scholarship(), applications: applications),
      );
      await tester.pumpAndSettle();

      expect(find.text('DRAFT IN PROGRESS'), findsOneWidget);
      final continueBtn = find.byKey(const ValueKey('continue-application'));
      expect(continueBtn, findsOneWidget);

      // Tap Continue Application -> opens review dialog
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Apply to this scholarship?'), findsOneWidget);

      // Confirm application
      await tester.tap(find.byKey(const ValueKey('apply-confirm')));
      await tester.pumpAndSettle();

      // Now officially applied
      expect(find.text('Application submitted'), findsOneWidget);

      // Upgraded in data source to submitted (not duplicate error)
      final rows = await applications.fetchApplications('user-a');
      expect(rows, hasLength(1));
      expect(rows.single['status'], 'submitted');
    });
  });

  group('ApplicationDetailScreen Draft View', () {
    testWidgets('renders Draft In Progress card and Continue Application action',
        (tester) async {
      final applications = FakeApplicationDataSource();
      final row = await applications.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': _scholarship().id,
        'status': 'draft',
      });

      final application = Application.fromJson(row);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-a'),
            applicationRepositoryProvider.overrideWith(
              (ref) => ApplicationRepository(
                dataSource: applications,
                currentUserId: () => 'user-a',
              ),
            ),
            scholarshipRepositoryProvider.overrideWith(
              (ref) => ScholarshipRepository(
                dataSource: FakeScholarshipDataSource(),
              ),
            ),
          ],
          child: MaterialApp(
            home: ApplicationDetailScreen(
              applicationId: application.id,
              initial: application,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Draft In Progress'), findsOneWidget);
      expect(find.byKey(const ValueKey('detail-continue-application')), findsOneWidget);
    });
  });
}
