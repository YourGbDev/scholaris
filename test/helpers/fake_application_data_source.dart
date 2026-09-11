import 'package:scholaris/features/applications/repositories/application_repository.dart';

/// In-memory [ApplicationDataSource] for tests. Applications are keyed by
/// user id so the repository's own-user scoping can be exercised without a
/// Supabase client. Each insert generates a sequential id like `app-1`.
class FakeApplicationDataSource implements ApplicationDataSource {
  final Map<String, List<Map<String, dynamic>>> _rows = {};
  int _seq = 0;

  /// Scholarship rows keyed by id, so the provider-scoped incoming-applications
  /// path can be exercised without a Supabase client. Seed with a
  /// `created_by` column to emulate the `scholarships.created_by` ownership
  /// the production query filters on.
  final Map<String, Map<String, dynamic>> scholarshipIndex = {};

  List<Map<String, dynamic>> _userRows(String userId) =>
      _rows.putIfAbsent(userId, () => []);

  @override
  Future<List<Map<String, dynamic>>> fetchApplications(String userId) async =>
      [for (final r in _userRows(userId)) Map<String, dynamic>.of(r)];

  @override
  Future<List<Map<String, dynamic>>> fetchAllApplications() async =>
      [for (final rows in _rows.values) for (final r in rows) Map<String, dynamic>.of(r)];

  @override
  Future<List<String>> fetchProviderScholarshipIds(String providerId) async =>
      scholarshipIndex.entries
          .where((e) => e.value['created_by'] == providerId)
          .map((e) => e.key)
          .toList();

  @override
  Future<List<Map<String, dynamic>>> fetchApplicationsForScholarships(
    List<String> scholarshipIds,
  ) async {
    if (scholarshipIds.isEmpty) return const [];
    return [
      for (final rows in _rows.values)
        for (final r in rows)
          if (scholarshipIds.contains(r['scholarship_id']))
            Map<String, dynamic>.of(r),
    ];
  }

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
  Future<Map<String, dynamic>?> fetchApplication(
    String userId,
    String applicationId,
  ) async {
    for (final r in _userRows(userId)) {
      if (r['id'] == applicationId) {
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
      'user_id': userId,
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