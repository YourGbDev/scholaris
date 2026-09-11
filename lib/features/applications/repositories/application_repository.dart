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

/// Thrown when a user tries to withdraw an application that is not in a
/// withdrawable (pending) state. Withdrawal is only allowed for draft,
/// submitted and under-review applications; approved, rejected and already
/// withdrawn applications are terminal.
class ApplicationWithdrawalException implements Exception {
  const ApplicationWithdrawalException();

  @override
  String toString() => 'This application can no longer be withdrawn.';
}

/// Low-level row access for the `applications` table.
abstract class ApplicationDataSource {
  Future<List<Map<String, dynamic>>> fetchApplications(String userId);
  Future<List<Map<String, dynamic>>> fetchAllApplications();
  Future<List<Map<String, dynamic>>> fetchApplicationsForScholarships(
    List<String> scholarshipIds,
  );
  Future<List<String>> fetchProviderScholarshipIds(String providerId);
  Future<Map<String, dynamic>?> fetchApplicationByScholarship(
    String userId,
    String scholarshipId,
  );
  Future<Map<String, dynamic>?> fetchApplication(
    String userId,
    String applicationId,
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
  Future<void> updateApplicationStatus(
    String applicationId,
    String status,
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
  Future<List<Map<String, dynamic>>> fetchAllApplications() async {
    return _client
        .from('applications')
        .select()
        .order('applied_at', ascending: false);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchApplicationsForScholarships(
    List<String> scholarshipIds,
  ) async {
    if (scholarshipIds.isEmpty) return const [];
    return _client
        .from('applications')
        .select()
        .inFilter('scholarship_id', scholarshipIds)
        .order('applied_at', ascending: false);
  }

  @override
  Future<List<String>> fetchProviderScholarshipIds(String providerId) async {
    final rows = await _client
        .from('scholarships')
        .select('id')
        .eq('created_by', providerId);
    return [
      for (final row in rows)
        if (row['id'] is String) row['id'] as String,
    ];
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
  Future<Map<String, dynamic>?> fetchApplication(
    String userId,
    String applicationId,
  ) async {
    return _client
        .from('applications')
        .select()
        .eq('user_id', userId)
        .eq('id', applicationId)
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

  @override
  Future<void> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    await _client
        .from('applications')
        .update({'status': status})
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

  /// Applications submitted to scholarships owned by the signed-in provider
  /// (those whose `scholarships.created_by` equals the current user id).
  ///
  /// Scoping is delegated to the database: the
  /// `providers_select_own_applications` RLS policy only returns rows belonging
  /// to the provider's own scholarships, so this method is safe to call for any
  /// signed-in user — a non-provider simply gets an empty list. Returns an empty
  /// list when signed out.
  ///
  /// The returned rows are NOT filtered by `applied_at` on the client; the data
  /// source orders newest-first and any application without an `applied_at`
  /// (e.g. a still-draft submission) sorts to the end.
  Future<List<Application>> fetchIncomingApplications() async {
    final providerId = _currentUserId();
    if (providerId == null) return const [];
    final ids = await _dataSource.fetchProviderScholarshipIds(providerId);
    if (ids.isEmpty) return const [];
    final rows = await _dataSource.fetchApplicationsForScholarships(ids);
    return rows.map(Application.fromJson).toList();
  }

  /// All applications across the platform. Intended for administrative telemetry
  /// and pipeline analytics.
  Future<List<Application>> fetchAllApplications() async {
    final rows = await _dataSource.fetchAllApplications();
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

  /// Confirms an award for an approved application. Accessible by administrators.
  Future<void> confirmAward(String applicationId) async {
    _requireUserId();
    await _dataSource.updateApplicationStatus(
      applicationId,
      ApplicationStatus.awarded.dbValue,
    );
  }

  /// Withdraws one of the signed-in user's own applications.
  ///
  /// Only pending applications (draft, submitted, under review) can be
  /// withdrawn. Terminal applications (approved, rejected, withdrawn) throw
  /// [ApplicationWithdrawalException]. The application record is preserved —
  /// only its status changes to withdrawn.
  Future<void> withdraw(String applicationId) async {
    final userId = _requireUserId();
    final current = await _dataSource.fetchApplication(userId, applicationId);
    if (current == null) {
      throw const ApplicationWithdrawalException();
    }
    final status = ApplicationStatus.fromDbValue(current['status'] as String);
    if (!status.isPending) {
      throw const ApplicationWithdrawalException();
    }
    await _dataSource
        .updateApplication(userId, applicationId, {'status': ApplicationStatus.withdrawn.dbValue});
  }

  /// Updates the notes of one of the signed-in user's own applications.
  /// Only the notes column is modified — status and other fields are never
  /// touched.
  Future<void> updateNotes(String applicationId, String notes) async {
    final userId = _requireUserId();
    await _dataSource
        .updateApplication(userId, applicationId, {'notes': notes});
  }

  String _requireUserId() {
    final userId = _currentUserId();
    if (userId == null) {
      throw const ApplicationNotAuthenticatedException();
    }
    return userId;
  }
}
