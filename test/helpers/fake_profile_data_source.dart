import 'package:scholaris/features/profile/repositories/profile_repository.dart';

/// In-memory [ProfileDataSource] for tests. Rows are keyed by user id so the
/// repository's own-user scoping can be exercised without a Supabase client.
class FakeProfileDataSource implements ProfileDataSource {
  final Map<String, Map<String, dynamic>> rows = {};

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    for (final entry in rows.entries) {
      if (entry.key == userId || entry.value['id'] == userId) {
        return Map<String, dynamic>.of(entry.value);
      }
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllProfiles() async {
    return rows.entries
        .map((e) =>
            Map<String, dynamic>.of({'id': e.value['id'] ?? e.key, ...e.value}))
        .toList();
  }

  @override
  Future<void> upsertProfile(String userId, Map<String, dynamic> row) async {
    rows.removeWhere((key, val) => key == userId || val['id'] == userId);
    rows[userId] = {'id': userId, ...row};
  }

  @override
  Future<void> deleteProfile(String userId) async {
    rows.remove(userId);
    rows.removeWhere((key, val) => key == userId || val['id'] == userId);
  }
}
