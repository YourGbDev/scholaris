import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/applications/providers/application_draft_provider.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';

import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_application_data_source.dart';

class Session extends AuthSessionNotifier {
  @override
  AuthSession? build() => const AuthSession(userId: 'a');
  void change(String? id) =>
      state = id == null ? null : AuthSession(userId: id);
}

class DelayedBookmarks extends FakeBookmarkDataSource {
  final gate = Completer<void>();
  @override
  Future<void> addBookmark(String id, String grant) async {
    await gate.future;
    await super.addBookmark(id, grant);
  }
}

class DelayedApplications extends FakeApplicationDataSource {
  final gate = Completer<void>();
  @override
  Future<Map<String, dynamic>> insertApplication(
    String userId,
    Map<String, dynamic> row,
  ) async {
    await gate.future;
    return super.insertApplication(userId, row);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'tab resets on logout and account switch but not same-user update',
    () async {
      final auth = Session();
      final c = ProviderContainer(
        overrides: [authSessionProvider.overrideWith(() => auth)],
      );
      addTearDown(c.dispose);
      final keep = c.listen(homeTabIndexProvider, (_, _) {});
      addTearDown(keep.close);
      c.read(homeTabIndexProvider.notifier).selectTab(3);
      auth.change('a');
      await c.pump();
      expect(c.read(homeTabIndexProvider), 3);
      auth.change(null);
      await c.pump();
      expect(c.read(homeTabIndexProvider), 0);
      auth.change('a');
      await c.pump();
      expect(c.read(homeTabIndexProvider), 0);
      c.read(homeTabIndexProvider.notifier).selectTab(2);
      auth.change('b');
      await c.pump();
      expect(c.read(homeTabIndexProvider), 0);
    },
  );
  test(
    'essay and recommender state cannot follow a different account',
    () async {
      final auth = Session();
      final c = ProviderContainer(
        overrides: [authSessionProvider.overrideWith(() => auth)],
      );
      addTearDown(c.dispose);
      c.read(authSessionProvider);
      final key = (userId: 'a', scholarshipId: 'grant');
      c.read(applicationDraftProvider(key).notifier).setEssay('Private essay');
      c
          .read(applicationDraftProvider(key).notifier)
          .addRecommender('private@example.test');
      auth.change(null);
      await c.pump();
      auth.change('b');
      await c.pump();
      expect(
        c
            .read(
              applicationDraftProvider((userId: 'b', scholarshipId: 'grant')),
            )
            .essay,
        isEmpty,
      );
      expect(c.read(applicationDraftProvider(key)).essay, isEmpty);
      expect(c.read(applicationDraftProvider(key)).recommenders, isEmpty);
    },
  );
  test('late bookmark completion cannot populate the next session', () async {
    final auth = Session();
    final source = DelayedBookmarks();
    String? user = 'a';
    final c = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(() => auth),
        bookmarkRepositoryProvider.overrideWith(
          (ref) =>
              BookmarkRepository(dataSource: source, currentUserId: () => user),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.read(authSessionProvider);
    final keep = c.listen(bookmarksProvider, (_, _) {});
    addTearDown(keep.close);
    await c.read(bookmarksProvider.future);
    final operation = c.read(bookmarksProvider.notifier).toggle('grant');
    user = 'b';
    auth.change('b');
    await c.read(bookmarksProvider.future);
    source.gate.complete();
    await operation;
    expect(c.read(bookmarksProvider).requireValue, isEmpty);
  });
  for (final draft in [false, true]) test(
    'late ${draft ? 'draft' : 'application'} completion cannot populate the next session',
    () async {
      final auth = Session();
      final source = DelayedApplications();
      String? user = 'a';
      final c = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(() => auth),
          applicationRepositoryProvider.overrideWith(
            (ref) => ApplicationRepository(
              dataSource: source,
              currentUserId: () => user,
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.read(authSessionProvider);
      final keep = c.listen(applicationsProvider, (_, _) {});
      addTearDown(keep.close);
      await c.read(applicationsProvider.future);
      final notifier = c.read(applicationsProvider.notifier);
      final operation = draft ? notifier.saveDraft('grant') : notifier.apply('grant');
      await Future<void>.delayed(Duration.zero);
      user = 'b';
      auth.change('b');
      await c.read(applicationsProvider.future);
      source.gate.complete();
      await operation;
      expect(c.read(applicationsProvider).requireValue, isEmpty);
    },
  );
}
