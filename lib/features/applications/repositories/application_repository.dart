// lib/features/applications/repositories/application_repository.dart
//
// Repository/service split for the Application domain, mirroring the bookmark
// and profile features.
//
// SECURITY: the repository derives the target user id EXCLUSIVELY from the
// authenticated session. Callers can never read or write another student's
// application through this API. Row-level security in the database enforces
// the same rule as defense in depth.
//
// Duplicate prevention: a user may apply to a scholarship at most once. The
// repository checks for an existing row before inserting, because the current
// `applications` schema has no unique (user_id, scholarship_id) constraint —
// the same check the UI relies on. The data source is injectable so tests can
// exercise persistence, scoping, duplicate protection and the security guard
// without a real Supabase client.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/application.dart';

/// Thrown when an application operation requires a signed-in user.
class ApplicationNotAuthenticatedException implements Exception {
  const ApplicationNotAuthenticatedException();

  @override
  String toString() => 'You must be signed in to apply for scholarships.';
}

/// Thrown when a user tries to apply to a scholarship they already applied to.
class ApplicationDuplicateException implements Exception {
  const ApplicationDuplicateException();

  @override
  String toString() => 'You have already applied to this scholarship.';
}

/// Low-level row access for the `applications` table.
abstract class ApplicationDataSource {
  Future<List<Map<String, dynamic>>> fetchApplications(String userId);
  Future<Map<String, dynamic>?> fetchApplicationByScholarship(
    String userId,
    String scholarshipId,
  );
  Future<Map<String, dynamic>> insertApplication(
    String userId,
    Map<String, dynamic> row,
  );
  Future<void> updateApplication(
    String userId,
    String applicationId,
    Map<String, dynamic> row,
  );
}

/// Production implementation backed by Supabase.
class SupabaseApplicationDataSource implements ApplicationDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> fetchApplications(String userId) async {
    return _client
        .from('applications')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchApplicationByScholarship(
    String userId,
    String scholarshipId,
  ) async {
    return _client
        .from('applications')
        .select()
        .eq('user_id', userId)
        .eq('scholarship_id', scholarshipId)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> insertApplication(
    String userId,
    Map<String, dynamic> row,
  ) async {
    return _client.from('applications').insert(row).select().single();
  }

  @override
  Future<void> updateApplication(
    String userId,
    String applicationId,
    Map<String, dynamic> row,
  ) async {
    await _client
        .from('applications')
        .update(row)
        .eq('user_id', userId)
        .eq('id', applicationId);
  }
}

class ApplicationRepository {
  ApplicationRepository({
    ApplicationDataSource? dataSource,
    String? Function()? currentUserId,
  })  : _dataSource = dataSource ?? SupabaseApplicationDataSource(),
        _currentUserId = currentUserId ??
            (() => Supabase.instance.client.auth.currentUser?.id);

  final ApplicationDataSource _dataSource;
  final String? Function() _currentUserId;

  String? get currentUserId => _currentUserId();

  /// The signed-in user's own applications, newest first, or an empty list when
  /// signed out. Never reads another user's applications.
  Future<List<Application>> fetchMyApplications() async {
    final userId = _currentUserId();
    if (userId == null) return const [];
    final rows = await _dataSource.fetchApplications(userId);
    return rows.map(Application.fromJson).toList();
  }

  /// Whether the signed-in user already has an application for
  /// [scholarshipId]. False when signed out.
  Future<bool> hasApplied(String scholarshipId) async {
    final userId = _currentUserId();
    if (userId == null) return false;
    return await _dataSource.fetchApplicationByScholarship(userId, scholarshipId) !=
        null;
  }

  /// Submits an application for [scholarshipId] on behalf of the signed-in
  /// user. Rejects a second application for the same scholarship with an
  /// [ApplicationDuplicateException], and rejects unauthenticated callers with
  /// an [ApplicationNotAuthenticatedException].
  Future<Application> apply({
    required String scholarshipId,
    String? notes,
  }) async {
    final userId = _requireUserId();
    final existing =
        await _dataSource.fetchApplicationByScholarship(userId, scholarshipId);
    if (existing != null) {
      throw const ApplicationDuplicateException();
    }
    final created = await _dataSource.insertApplication(userId, {
      'user_id': userId,
      'scholarship_id': scholarshipId,
      'status': ApplicationStatus.submitted.dbValue,
      'notes': notes,
      'applied_at': DateTime.now().toUtc().toIso8601String(),
    });
    return Application.fromJson(created);
  }

  /// Advances the status of one of the signed-in user's own applications.
  Future<void> updateStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    final userId = _requireUserId();
    await _dataSource
        .updateApplication(userId, applicationId, {'status': status.dbValue});
  }

  String _requireUserId() {
    final userId = _currentUserId();
    if (userId == null) {
      throw const ApplicationNotAuthenticatedException();
    }
    return userId;
  }
}
