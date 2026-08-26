import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';

import 'helpers/fake_bookmark_data_source.dart';

void main() {
  group('BookmarkRepository', () {
    test('fetch returns the signed-in user bookmarks only', () async {
      final source = FakeBookmarkDataSource();
      await source.addBookmark('user-b', 'sch-other');

      final repo = BookmarkRepository(
        dataSource: source,
        currentUserId: () => 'user-a',
      );

      expect(await repo.fetchBookmarkedIds(), isEmpty);

      await repo.add('sch-dost');
      await repo.add('sch-ched');

      expect(await repo.fetchBookmarkedIds(), ['sch-dost', 'sch-ched']);
      // user-b untouched.
      expect(await source.fetchScholarshipIds('user-b'), ['sch-other']);
    });

    test('remove is idempotent', () async {
      final source = FakeBookmarkDataSource();
      final repo = BookmarkRepository(
        dataSource: source,
        currentUserId: () => 'user-a',
      );

      await repo.add('sch-dost');
      await repo.remove('sch-dost');
      await repo.remove('sch-dost');

      expect(await repo.fetchBookmarkedIds(), isEmpty);
    });

    test('unauthenticated fetch returns empty and add throws', () async {
      final repo = BookmarkRepository(
        dataSource: FakeBookmarkDataSource(),
        currentUserId: () => null,
      );

      expect(await repo.fetchBookmarkedIds(), isEmpty);
      expect(
        () => repo.add('sch-dost'),
        throwsA(isA<BookmarkNotAuthenticatedException>()),
      );
    });
  });

  group('BookmarksNotifier', () {
    test('toggle adds and removes, keeping state in sync', () async {
      final source = FakeBookmarkDataSource();
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-a'),
          bookmarkRepositoryProvider.overrideWith(
            (ref) => BookmarkRepository(
              dataSource: source,
              currentUserId: () => 'user-a',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(bookmarksProvider.notifier);
      await container.read(bookmarksProvider.future);

      expect(await notifier.toggle('sch-dost'), isTrue);
      expect(container.read(bookmarksProvider).valueOrNull, {'sch-dost'});

      expect(await notifier.toggle('sch-dost'), isFalse);
      expect(container.read(bookmarksProvider).valueOrNull, isEmpty);
      expect(await source.fetchScholarshipIds('user-a'), isEmpty);
    });
  });
}
