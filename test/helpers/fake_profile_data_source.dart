import 'package:scholaris/features/profile/repositories/profile_repository.dart';

/// In-memory [ProfileDataSource] for tests. Rows are keyed by user id so the
/// repository's own-user scoping can be exercised without a Supabase client.
class FakeProfileDataSource implements ProfileDataSource {
  final Map<String, Map<String, dynamic>> rows = {};

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final row = rows[userId];
    return row == null ? null : Map<String, dynamic>.of(row);
  }

  @override
  Future<void> upsertProfile(String userId, Map<String, dynamic> row) async {
    rows[userId] = {...rows[userId] ?? const {}, ...row};
  }
}
