// lib/features/bookmarks/providers/bookmarks_provider.dart
//
// Reactive bookmarks state: [bookmarksProvider] holds the set of scholarship ids
// the signed-in user has saved, and exposes [toggle] for the detail / card
// UI to call.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../repositories/bookmark_repository.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>(
  (ref) => BookmarkRepository(),
);

final bookmarksProvider =
    AsyncNotifierProvider<BookmarksNotifier, Set<String>>(
  BookmarksNotifier.new,
);

class BookmarksNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    // Bound to the authenticated user: rebuilt (and refetched) on every auth
    // transition, so a previous user's saved set can never leak to the next.
    ref.watch(currentUserIdProvider);
    final ids = await ref.watch(bookmarkRepositoryProvider).fetchBookmarkedIds();
    return ids.toSet();
  }

  /// Toggles the bookmark for [scholarshipId]. Returns the new state (true =
  /// bookmarked after the call).
  Future<bool> toggle(String scholarshipId) async {
    final repo = ref.read(bookmarkRepositoryProvider);
    final current = state.valueOrNull ?? <String>{};

    if (current.contains(scholarshipId)) {
      await repo.remove(scholarshipId);
      state = AsyncData(Set<String>.of(current)..remove(scholarshipId));
      return false;
    } else {
      await repo.add(scholarshipId);
      state = AsyncData(Set<String>.of(current)..add(scholarshipId));
      return true;
    }
  }
}