import 'package:scholaris/features/applications/repositories/application_repository.dart';

/// In-memory [ApplicationDataSource] for tests. Applications are keyed by
/// user id so the repository's own-user scoping can be exercised without a
/// Supabase client. Each insert generates a sequential id like `app-1`.
class FakeApplicationDataSource implements ApplicationDataSource {
  final Map<String, List<Map<String, dynamic>>> _rows = {};
  int _seq = 0;

  List<Map<String, dynamic>> _userRows(String userId) =>
      _rows.putIfAbsent(userId, () => []);

  @override
  Future<List<Map<String, dynamic>>> fetchApplications(String userId) async =>
      [for (final r in _userRows(userId)) Map<String, dynamic>.of(r)];

  @override
  Future<Map<String, dynamic>?> fetchApplicationByScholarship(
    String userId,
    String scholarshipId,
  ) async {
    for (final r in _userRows(userId)) {
      if (r['scholarship_id'] == scholarshipId) {
        return Map<String, dynamic>.of(r);
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> insertApplication(
    String userId,
    Map<String, dynamic> row,
  ) async {
    final created = <String, dynamic>{
      ...row,
      'id': 'app-${++_seq}',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    _userRows(userId).add(created);
    return Map<String, dynamic>.of(created);
  }

  @override
  Future<void> updateApplication(
    String userId,
    String applicationId,
    Map<String, dynamic> row,
  ) async {
    final rows = _userRows(userId);
    final i = rows.indexWhere((r) => r['id'] == applicationId);
    if (i == -1) return;
    rows[i] = {...rows[i], ...row};
  }
}