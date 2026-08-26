// Regression tests for Increment 2 — the authentication boundary.
//
// These prove the core invariant: when User A logs out and User B logs in,
// User B never inherits User A's profile, matches, bookmarks, or profile-setup
// draft. The tests drive a controllable auth session notifier and keep the
// repository fakes' `currentUserId` in lock-step with it, exactly like the real
// Supabase session would.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

/// A controllable [AuthSessionNotifier]: starts signed out and lets the test
/// drive sign-in/sign-out like the real session boundary would.
class _TestAuthNotifier extends AuthSessionNotifier {
  @override
  AuthSession? build() => null;

  void signInAs(String userId) => state = AuthSession(userId: userId);
  void signOut() => state = null;
}

StudentProfile _student({
  required String id,
  required String fullName,
  double gpa = 3.2,
  int yearLevel = 2,
  String course = 'BS Computer Science',
  double? monthlyFamilyIncome = 15000,
  String region = 'NCR',
  bool setupComplete = true,
}) =>
    StudentProfile(
      id: id,
      fullName: fullName,
      nationality: 'Filipino',
      region: region,
      gpa: gpa,
      yearLevel: yearLevel,
      course: course,
      monthlyFamilyIncome: monthlyFamilyIncome,
      setupComplete: setupComplete,
    );

Map<String, dynamic> _rowFor(String id, String fullName) =>
    _student(id: id, fullName: fullName).toDbRow();

/// Wires the user-scoped repositories and the auth session boundary together
/// so a session change propagates through the same dependency graph the real
/// app uses. [currentUser] is the "session" the repositories see; the auth
/// notifier drives the reactive providers.
class _Harness {
  _Harness()
      : profiles = FakeProfileDataSource(),
        bookmarks = FakeBookmarkDataSource() {
    auth = _TestAuthNotifier();
    container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(() => auth),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(
            dataSource: profiles,
            currentUserId: () => currentUser,
          ),
        ),
        bookmarkRepositoryProvider.overrideWith(
          (ref) => BookmarkRepository(
            dataSource: bookmarks,
            currentUserId: () => currentUser,
          ),
        ),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(
            dataSource: FakeScholarshipDataSource(),
          ),
        ),
      ],
    );
    // Force the auth provider element to exist so the controllable notifier is
    // bound to it before any test drives sign-in/sign-out.
    container.read(authSessionProvider);
  }

  final FakeProfileDataSource profiles;
  final FakeBookmarkDataSource bookmarks;
  late final ProviderContainer container;
  late final _TestAuthNotifier auth;

  /// The user id the repositories believe is signed in.
  String? currentUser;

  void signInAs(String userId) {
    currentUser = userId;
    auth.signInAs(userId);
  }

  void signOut() {
    currentUser = null;
    auth.signOut();
  }
}

/// Keeps an autoDispose family provider alive so its notifier (and draft) is
/// not disposed between operations in the test.
void _keepAlive(ProviderContainer container, ProviderListenable<Object?> p) {
  final sub = container.listen(p, (_, _) {});
  addTearDown(sub.close);
}

void main() {
  group('auth boundary — profile isolation', () {
    test('each user gets their own profile and logout clears it', () async {
      final h = _Harness()
        ..profiles.upsertProfile('user-a', _rowFor('user-a', 'Maria Santos'))
        ..profiles.upsertProfile('user-b', _rowFor('user-b', 'Juan Cruz'));
      addTearDown(h.container.dispose);

      // Signed out: no profile.
      expect(await h.container.read(currentProfileProvider.future), isNull);

      // User A loads A's profile.
      h.signInAs('user-a');
      expect(
        (await h.container.read(currentProfileProvider.future))!.fullName,
        'Maria Santos',
      );

      // Logout invalidates the cached profile.
      h.signOut();
      expect(await h.container.read(currentProfileProvider.future), isNull);

      // User B gets B's own profile — never A's cached one.
      h.signInAs('user-b');
      expect(
        (await h.container.read(currentProfileProvider.future))!.fullName,
        'Juan Cruz',
      );
    });

    test('profile completeness follows the signed-in user', () async {
      final h = _Harness()
        ..profiles.upsertProfile(
          'user-a',
          _student(id: 'user-a', fullName: 'Maria Santos', setupComplete: true)
              .toDbRow(),
        )
        ..profiles.upsertProfile(
          'user-b',
          _student(id: 'user-b', fullName: 'Juan Cruz', setupComplete: false)
              .toDbRow(),
        );
      addTearDown(h.container.dispose);

      h.signInAs('user-a');
      expect(await h.container.read(profileCompleteProvider.future), isTrue);

      h.signOut();
      expect(await h.container.read(profileCompleteProvider.future), isFalse);

      h.signInAs('user-b');
      expect(await h.container.read(profileCompleteProvider.future), isFalse);
    });
  });

  group('auth boundary — bookmarks isolation', () {
    test('bookmarks are per-user and cleared on logout', () async {
      final h = _Harness();
      await h.bookmarks.addBookmark('user-a', 'sch-a');
      await h.bookmarks.addBookmark('user-b', 'sch-b');
      addTearDown(h.container.dispose);

      h.signInAs('user-a');
      expect(await h.container.read(bookmarksProvider.future), {'sch-a'});

      h.signOut();
      expect(await h.container.read(bookmarksProvider.future), isEmpty);

      h.signInAs('user-b');
      expect(await h.container.read(bookmarksProvider.future), {'sch-b'});
    });
  });

  group('auth boundary — matches isolation', () {
    test('matches recompute for the new user and never reuse prior results',
        () async {
      final h = _Harness()
        ..profiles.upsertProfile(
          'user-a',
          _student(
            id: 'user-a',
            fullName: 'Maria Santos',
            gpa: 3.2,
            monthlyFamilyIncome: 15000,
            region: 'NCR',
          ).toDbRow(),
        )
        // High-income student: CHED (income 'low') must not match, and this is
        // exactly the kind of result User B would wrongly inherit if matches
        // were cached from User A.
        ..profiles.upsertProfile(
          'user-b',
          _student(
            id: 'user-b',
            fullName: 'Juan Cruz',
            gpa: 4.0,
            monthlyFamilyIncome: 90000,
            region: 'Davao',
          ).toDbRow(),
        );
      addTearDown(h.container.dispose);

      h.signInAs('user-a');
      final aMatches = await h.container.read(matchesProvider.future);
      expect(aMatches.map((s) => s.id), ['sch-dost', 'sch-ched']);

      h.signOut();
      expect(await h.container.read(matchesProvider.future), isEmpty);

      h.signInAs('user-b');
      final bMatches = await h.container.read(matchesProvider.future);
      expect(bMatches.map((s) => s.id), ['sch-dost']);
      // User B's result must be driven by B's profile, not User A's cache.
      expect(bMatches.map((s) => s.id), isNot(aMatches.map((s) => s.id)));
    });
  });

  group('auth boundary — profile setup draft', () {
    test('a previous user draft cannot leak into the next user session',
        () async {
      final h = _Harness()
        ..profiles.upsertProfile('user-a', _rowFor('user-a', 'Maria Santos'))
        ..profiles.upsertProfile('user-b', _rowFor('user-b', 'Juan Cruz'));
      addTearDown(h.container.dispose);

      // User A opens the setup wizard and hydrates their own profile.
      h.signInAs('user-a');
      _keepAlive(h.container, profileSetupProvider('user-a'));
      final aNotifier =
          h.container.read(profileSetupProvider('user-a').notifier);
      await aNotifier.hydrationComplete;
      expect(aNotifier.state.fullName, 'Maria Santos');

      // A actively edits the draft.
      aNotifier.setFullName('Maria editing in progress');

      // A signs out, then B signs in and opens the wizard.
      h.signOut();
      h.signInAs('user-b');
      _keepAlive(h.container, profileSetupProvider('user-b'));
      final bNotifier =
          h.container.read(profileSetupProvider('user-b').notifier);
      await bNotifier.hydrationComplete;

      // B sees B's own profile, never A's hydrated data or A's partial draft.
      expect(bNotifier.state.fullName, 'Juan Cruz');
      expect(bNotifier.state.fullName, isNot('Maria editing in progress'));
      expect(bNotifier.state.hydrated, isTrue);

      // A's draft stays isolated in A's own notifier.
      expect(aNotifier.state.fullName, 'Maria editing in progress');
    });

    test('hydration resolves against the currently authenticated user only',
        () async {
      final h = _Harness();
      // Only user-a has a persisted profile; user-b is a first-time user.
      h.profiles.upsertProfile('user-a', _rowFor('user-a', 'Maria Santos'));
      addTearDown(h.container.dispose);

      h.signInAs('user-b');
      _keepAlive(h.container, profileSetupProvider('user-b'));
      final bNotifier =
          h.container.read(profileSetupProvider('user-b').notifier);
      await bNotifier.hydrationComplete;

      expect(bNotifier.state.hydrated, isFalse);
      expect(bNotifier.state.fullName, isEmpty);
      // User A's name must never appear in User B's session.
      expect(bNotifier.state.fullName, isNot('Maria Santos'));
    });
  });

  group('auth boundary — session restoration', () {
    test('restoring the next session does not resurrect previous user state',
        () async {
      final h = _Harness()
        ..profiles.upsertProfile('user-a', _rowFor('user-a', 'Maria Santos'))
        ..profiles.upsertProfile('user-b', _rowFor('user-b', 'Juan Cruz'));
      await h.bookmarks.addBookmark('user-a', 'sch-a');
      await h.bookmarks.addBookmark('user-b', 'sch-b');
      addTearDown(h.container.dispose);

      // User A is active, then signs out.
      h.signInAs('user-a');
      expect(
        (await h.container.read(currentProfileProvider.future))!.fullName,
        'Maria Santos',
      );
      expect(await h.container.read(bookmarksProvider.future), {'sch-a'});

      h.signOut();
      expect(await h.container.read(currentProfileProvider.future), isNull);
      expect(await h.container.read(bookmarksProvider.future), isEmpty);

      // A new session is established for user B.
      h.signInAs('user-b');
      expect(
        (await h.container.read(currentProfileProvider.future))!.fullName,
        'Juan Cruz',
      );
      expect(await h.container.read(bookmarksProvider.future), {'sch-b'});
      expect(await h.container.read(bookmarksProvider.future), isNot({'sch-a'}));
    });
  });
}
