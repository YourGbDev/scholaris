// lib/features/bookmarks/repositories/bookmark_repository.dart
//
// Repository for the `bookmarks` join table (user ↔ scholarship). Follows the
// profile pattern: the target user id is always derived from the authenticated
// session, never from caller input, and the data source is injectable.

import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when a bookmark operation requires a signed-in user.
class BookmarkNotAuthenticatedException implements Exception {
  const BookmarkNotAuthenticatedException();

  @override
  String toString() => 'You must be signed in to save scholarships.';
}

/// Low-level row access for the `bookmarks` table.
abstract class BookmarkDataSource {
  Future<List<String>> fetchScholarshipIds(String userId);
  Future<void> addBookmark(String userId, String scholarshipId);
  Future<void> removeBookmark(String userId, String scholarshipId);
}

/// Production implementation backed by Supabase.
class SupabaseBookmarkDataSource implements BookmarkDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<String>> fetchScholarshipIds(String userId) async {
    final rows = await _client
        .from('bookmarks')
        .select('scholarship_id')
        .eq('user_id', userId);
    return rows.map((row) => row['scholarship_id'] as String).toList();
  }

  @override
  Future<void> addBookmark(String userId, String scholarshipId) async {
    await _client.from('bookmarks').upsert({
      'user_id': userId,
      'scholarship_id': scholarshipId,
    }, onConflict: 'user_id,scholarship_id');
  }

  @override
  Future<void> removeBookmark(String userId, String scholarshipId) async {
    await _client
        .from('bookmarks')
        .delete()
        .eq('user_id', userId)
        .eq('scholarship_id', scholarshipId);
  }
}

class BookmarkRepository {
  BookmarkRepository({
    BookmarkDataSource? dataSource,
    String? Function()? currentUserId,
  })  : _dataSource = dataSource ?? SupabaseBookmarkDataSource(),
        _currentUserId = currentUserId ??
            (() => Supabase.instance.client.auth.currentUser?.id);

  final BookmarkDataSource _dataSource;
  final String? Function() _currentUserId;

  String? get currentUserId => _currentUserId();

  /// The scholarship ids the signed-in user has saved, or empty when signed
  /// out. Never reads another user's bookmarks.
  Future<List<String>> fetchBookmarkedIds() async {
    final userId = _currentUserId();
    if (userId == null) return const [];
    return _dataSource.fetchScholarshipIds(userId);
  }

  /// Saves a scholarship for the signed-in user.
  Future<void> add(String scholarshipId) async {
    final userId = _requireUserId();
    await _dataSource.addBookmark(userId, scholarshipId);
  }

  /// Removes a saved scholarship for the signed-in user. Idempotent.
  Future<void> remove(String scholarshipId) async {
    final userId = _requireUserId();
    await _dataSource.removeBookmark(userId, scholarshipId);
  }

  String _requireUserId() {
    final userId = _currentUserId();
    if (userId == null) {
      throw const BookmarkNotAuthenticatedException();
    }
    return userId;
  }
}
