// test/avatar_setup_and_verification_test.dart
//
// Tests the Avatar Setup Flow during profile setup and the Real Photo Identity
// Verification Check during scholarship application submission.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/profile/models/avatar_item.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/presentation/profile_setup_screen.dart';
import 'package:scholaris/features/profile/presentation/profile_tab_screen.dart';
import 'package:scholaris/features/profile/providers/avatar_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

StudentProfile _student({String id = 'test-student'}) => StudentProfile(
      id: id,
      fullName: 'Maya Santos Dela Cruz',
      nationality: 'Filipino',
      region: 'NCR',
      gpa: 3.5,
      yearLevel: 2,
      course: 'BS Computer Science',
      monthlyFamilyIncome: 20000,
      setupComplete: true,
    );

Scholarship _scholarship() =>
    Scholarship.fromJson(FakeScholarshipDataSource.defaultRows.first);

Widget _wrapProfileSetup({
  required String step,
  required String userId,
  AvatarNotifier? avatarNotifier,
}) {
  final profileSource = FakeProfileDataSource();
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      profileSetupProvider.overrideWith(
        (ref, id) => ProfileSetupNotifier(
          ProfileRepository(
            dataSource: profileSource,
            currentUserId: () => userId,
          ),
        ),
      ),
      if (avatarNotifier != null)
        avatarProvider(userId).overrideWith((ref) => avatarNotifier),
    ],
    child: MaterialApp(
      home: ProfileSetupScreen(step: step),
    ),
  );
}

Widget _wrapScholarshipDetail({
  required String userId,
  required AvatarNotifier avatarNotifier,
  FakeApplicationDataSource? applications,
}) {
  final profileSource = FakeProfileDataSource();
  profileSource.upsertProfile(userId, _student(id: userId).toDbRow());

  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      avatarProvider(userId).overrideWith((ref) => avatarNotifier),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: profileSource,
          currentUserId: () => userId,
        ),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: applications ?? FakeApplicationDataSource(),
          currentUserId: () => userId,
        ),
      ),
      bookmarkRepositoryProvider.overrideWith(
        (ref) => BookmarkRepository(
          dataSource: FakeBookmarkDataSource(),
          currentUserId: () => userId,
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) => ScholarshipRepository(dataSource: FakeScholarshipDataSource()),
      ),
    ],
    child: MaterialApp(
      home: ScholarshipDetailScreen(
        scholarshipId: _scholarship().id,
        initial: _scholarship(),
      ),
    ),
  );
}

Widget _wrapProfileTab({
  required String userId,
  required AvatarNotifier avatarNotifier,
}) {
  final profileSource = FakeProfileDataSource();
  profileSource.upsertProfile(userId, _student(id: userId).toDbRow());

  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      avatarProvider(userId).overrideWith((ref) => avatarNotifier),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: profileSource,
          currentUserId: () => userId,
        ),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: ProfileTabScreen()),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AvatarItem model tests', () {
    test('contains 6 presets and has doodle_scholar as default', () {
      expect(AvatarItem.presets.length, equals(6));
      expect(AvatarItem.defaultAvatarId, equals('doodle_scholar'));
      expect(AvatarItem.findById('doodle_graduate').name, equals('Graduate Iskolar'));
      expect(AvatarItem.findById('unknown_id').id, equals('doodle_scholar'));
    });
  });

  group('Profile Setup Avatar Selection Flow (Step 1)', () {
    testWidgets('renders avatar picker section with doodle options and "Set up later"',
        (tester) async {
      final notifier = AvatarNotifier(
        userId: 'student-1',
        initialState: const AvatarState(),
      );

      await tester.pumpWidget(_wrapProfileSetup(
        step: 'personal',
        userId: 'student-1',
        avatarNotifier: notifier,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Avatar'), findsOneWidget);
      expect(find.text('Pick a doodle or set up later'), findsOneWidget);
      expect(find.byKey(const ValueKey('avatar-setup-later')), findsOneWidget);

      // Verify all doodle options are rendered
      for (final preset in AvatarItem.presets) {
        expect(find.byKey(ValueKey('avatar-setup-option-${preset.id}')), findsOneWidget);
      }
    });

    testWidgets('tapping a doodle avatar option updates the selected avatar',
        (tester) async {
      final notifier = AvatarNotifier(
        userId: 'student-2',
        initialState: const AvatarState(),
      );

      await tester.pumpWidget(_wrapProfileSetup(
        step: 'personal',
        userId: 'student-2',
        avatarNotifier: notifier,
      ));
      await tester.pumpAndSettle();

      // Tap the graduate doodle option
      await tester.tap(find.byKey(const ValueKey('avatar-setup-option-doodle_graduate')));
      await tester.pumpAndSettle();

      expect(notifier.state.avatarId, equals('doodle_graduate'));
      expect(notifier.state.isRealPhoto, isFalse);
    });

    testWidgets('tapping "Set up later" assigns default doodle avatar and shows toast',
        (tester) async {
      final notifier = AvatarNotifier(
        userId: 'student-3',
        initialState: const AvatarState(avatarId: 'doodle_explorer'),
      );

      await tester.pumpWidget(_wrapProfileSetup(
        step: 'personal',
        userId: 'student-3',
        avatarNotifier: notifier,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('avatar-setup-later')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(notifier.state.avatarId, equals('doodle_scholar'));
      expect(notifier.state.isRealPhoto, isFalse);
      expect(notifier.state.isSkipped, isTrue);
      expect(find.textContaining('Default doodle avatar assigned'), findsOneWidget);
    });
  });

  group('Scholarship Application Real Photo Identity Verification Check', () {
    testWidgets(
        'applying with placeholder avatar shows Identity Photo Required dialog and blocks submission when cancelled',
        (tester) async {
      final notifier = AvatarNotifier(
        userId: 'student-placeholder',
        initialState: const AvatarState(
          avatarId: 'doodle_scholar',
          isRealPhoto: false,
        ),
      );

      await tester.pumpWidget(_wrapScholarshipDetail(
        userId: 'student-placeholder',
        avatarNotifier: notifier,
      ));
      await tester.pumpAndSettle();

      // Tap Apply Now button
      final applyBtn = find.byKey(const ValueKey('apply-now'));
      expect(applyBtn, findsOneWidget);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      // Identity verification photo dialog appears
      expect(find.text('Identity Photo Required'), findsOneWidget);
      expect(
        find.textContaining('Scholarship providers require an authentic, real photograph of you'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Applications submitted with cartoon or placeholder avatars cannot be deliberated'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('photo-upload-camera')), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-upload-gallery')), findsOneWidget);

      // Cancel the dialog
      await tester.tap(find.byKey(const ValueKey('photo-upload-cancel')));
      await tester.pumpAndSettle();

      // Verify user was NOT advanced to pre-apply review dialog
      expect(find.text('Apply to this scholarship?'), findsNothing);
      expect(
        find.textContaining('A verified real photo is required to submit your scholarship application'),
        findsOneWidget,
      );
    });

    testWidgets(
        'uploading from camera in Identity Photo Required dialog verifies photo and advances to pre-apply dialog',
        (tester) async {
      final notifier = AvatarNotifier(
        userId: 'student-camera',
        initialState: const AvatarState(
          avatarId: 'doodle_scholar',
          isRealPhoto: false,
        ),
      );

      await tester.pumpWidget(_wrapScholarshipDetail(
        userId: 'student-camera',
        avatarNotifier: notifier,
      ));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.byKey(const ValueKey('apply-now')));
      await tester.pumpAndSettle();

      expect(find.text('Identity Photo Required'), findsOneWidget);

      // Choose Camera
      await tester.tap(find.byKey(const ValueKey('photo-upload-camera')));
      await tester.pump();
      await tester.pumpAndSettle();

      // State is updated to real photo
      expect(notifier.state.isRealPhoto, isTrue);

      // Smoothly advances to application review dialog!
      expect(find.text('Apply to this scholarship?'), findsOneWidget);
      expect(find.byKey(const ValueKey('apply-confirm')), findsOneWidget);
    });

    testWidgets(
        'uploading from gallery in Identity Photo Required dialog verifies photo and advances to pre-apply dialog',
        (tester) async {
      final notifier = AvatarNotifier(
        userId: 'student-gallery',
        initialState: const AvatarState(
          avatarId: 'doodle_scholar',
          isRealPhoto: false,
        ),
      );

      await tester.pumpWidget(_wrapScholarshipDetail(
        userId: 'student-gallery',
        avatarNotifier: notifier,
      ));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.byKey(const ValueKey('apply-now')));
      await tester.pumpAndSettle();

      // Choose Gallery
      await tester.tap(find.byKey(const ValueKey('photo-upload-gallery')));
      await tester.pumpAndSettle();

      expect(notifier.state.isRealPhoto, isTrue);
      expect(find.text('Apply to this scholarship?'), findsOneWidget);
    });

    testWidgets(
        'applying when real photo is already verified directly opens pre-apply dialog without prompt',
        (tester) async {
      final notifier = AvatarNotifier(
        userId: 'student-verified',
        initialState: const AvatarState(
          avatarId: 'real_photo',
          isRealPhoto: true,
        ),
      );

      await tester.pumpWidget(_wrapScholarshipDetail(
        userId: 'student-verified',
        avatarNotifier: notifier,
      ));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.byKey(const ValueKey('apply-now')));
      await tester.pumpAndSettle();

      // Does NOT show Identity Photo Required dialog
      expect(find.text('Identity Photo Required'), findsNothing);

      // Directly opens application review dialog
      expect(find.text('Apply to this scholarship?'), findsOneWidget);
      expect(find.byKey(const ValueKey('apply-confirm')), findsOneWidget);
    });
  });

  group('ProfileTabScreen Avatar Customization', () {
    testWidgets('renders avatar in hero card and tapping opens AvatarSelectorSheet',
        (tester) async {
      final notifier = AvatarNotifier(
        userId: 'student-tab',
        initialState: const AvatarState(
          avatarId: 'doodle_scholar',
          isRealPhoto: false,
        ),
      );

      await tester.pumpWidget(_wrapProfileTab(
        userId: 'student-tab',
        avatarNotifier: notifier,
      ));
      await tester.pumpAndSettle();

      // Tap avatar display in hero card
      await tester.tap(find.byKey(const ValueKey('profile-hero-avatar')));
      await tester.pumpAndSettle();

      // AvatarSelectorSheet opens
      expect(find.text('Profile Avatar'), findsOneWidget);
      expect(find.text('Choose a cartoon doodle or upload a real photo.'), findsOneWidget);
      expect(find.byKey(const ValueKey('avatar-camera-btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('avatar-gallery-btn')), findsOneWidget);
    });
  });
}
