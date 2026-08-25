import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';

/// In-memory [BookmarkDataSource] for tests. Stores sets of scholarship ids
/// keyed by user id.
class FakeBookmarkDataSource implements BookmarkDataSource {
  final Map<String, Set<String>> _bookmarks = {};

  Set<String> _userSet(String userId) =>
      _bookmarks.putIfAbsent(userId, () => <String>{});

  @override
  Future<List<String>> fetchScholarshipIds(String userId) async =>
      _userSet(userId).toList();

  @override
  Future<void> addBookmark(String userId, String scholarshipId) async {
    _userSet(userId).add(scholarshipId);
  }

  @override
  Future<void> removeBookmark(String userId, String scholarshipId) async {
    _userSet(userId).remove(scholarshipId);
  }
}