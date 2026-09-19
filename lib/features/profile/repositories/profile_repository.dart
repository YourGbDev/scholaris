// lib/features/profile/repositories/profile_repository.dart
//
// Repository/service split for the StudentProfile domain.
//
// SECURITY: the repository derives the target user id EXCLUSIVELY from the
// authenticated session. Callers can never read or write another student's
// row through this API. Row-level security in the database enforces the same
// rule as defense in depth.
//
// The data source is injectable so tests can exercise persistence, scoping and
// the security guard without a real Supabase client.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_profile.dart';

/// Thrown when an operation requires a signed-in user.
class ProfileNotAuthenticatedException implements Exception {
  const ProfileNotAuthenticatedException();

  @override
  String toString() => 'You must be signed in to use your profile.';
}

/// Thrown when a caller tries to save a profile whose id is not the
/// authenticated user's own id.
class ProfileOwnershipException implements Exception {
  const ProfileOwnershipException();

  @override
  String toString() => 'You may only modify your own profile.';
}

/// Low-level row access for the `profiles` table.
abstract class ProfileDataSource {
  Future<Map<String, dynamic>?> fetchProfile(String userId);
  Future<List<Map<String, dynamic>>> fetchAllProfiles();
  Future<void> upsertProfile(String userId, Map<String, dynamic> row);
  Future<void> updateProfile(String userId, Map<String, dynamic> row) async {}
  Future<void> deleteProfile(String userId) async {}
}

/// Production implementation backed by Supabase.
class SupabaseProfileDataSource implements ProfileDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    return _client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllProfiles() async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> upsertProfile(String userId, Map<String, dynamic> row) async {
    await _client.from('profiles').upsert({'id': userId, ...row});
  }

  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> row) async {
    await _client.from('profiles').update(row).eq('id', userId);
  }

  @override
  Future<void> deleteProfile(String userId) async {
    await _client.from('profiles').delete().eq('id', userId);
  }
}

class ProfileRepository {
  ProfileRepository({
    ProfileDataSource? dataSource,
    String? Function()? currentUserId,
  })  : _dataSource = dataSource ?? SupabaseProfileDataSource(),
        _currentUserId = currentUserId ??
            (() => Supabase.instance.client.auth.currentUser?.id);

  final ProfileDataSource _dataSource;
  final String? Function() _currentUserId;

  String? get currentUserId => _currentUserId();

  /// Fetches the signed-in user's own profile, or null when signed out or the
  /// profile does not exist yet. Never reads another user's row.
  Future<StudentProfile?> fetchCurrent() async {
    final userId = _currentUserId();
    if (userId == null) return null;
    final row = await _dataSource.fetchProfile(userId);
    if (row == null) return null;
    return StudentProfile.fromJson({...row, 'id': userId});
  }

  /// Fetches the profile of an arbitrary user by id, or null when it does not
  /// exist. Used by the provider console to resolve an applicant's display name
  /// for an incoming application. Row-level security (`providers_select_
  /// applicant_profiles`) restricts the calling provider to applicants who
  /// applied to their own scholarships — this method performs no ownership check
  /// of its own because the database enforces the boundary.
  Future<StudentProfile?> fetchProfileById(String userId) async {
    final row = await _dataSource.fetchProfile(userId);
    if (row == null) return null;
    return StudentProfile.fromJson({...row, 'id': userId});
  }

  /// Fetches all profiles across the platform. Intended for administrative directories
  /// (such as student applicant directory and user account management).
  Future<List<StudentProfile>> fetchAllProfiles() async {
    final rows = await _dataSource.fetchAllProfiles();
    return rows.map((r) {
      final safeRow = {
        ...r,
        'id': r['id'] ?? '',
        'full_name': r['full_name'] ?? '',
        'region': r['region'] ?? '',
        'gpa': (r['gpa'] as num?)?.toDouble() ?? 0.0,
        'year_level': (r['year_level'] as num?)?.toInt() ?? 1,
        'course': r['course'] ?? '',
      };
      return StudentProfile.fromJson(safeRow);
    }).toList();
  }

  /// Upserts the signed-in user's own profile. Rejects any profile that does
  /// not belong to the authenticated user.
  Future<void> saveCurrent({required StudentProfile profile}) async {
    final userId = _currentUserId();
    if (userId == null) {
      throw const ProfileNotAuthenticatedException();
    }
    if (profile.id != userId) {
      throw const ProfileOwnershipException();
    }
    await _dataSource.upsertProfile(userId, profile.toDbRow());
  }

  /// Administrative creation or replacement of a profile.
  Future<void> adminUpsertProfile(String userId, Map<String, dynamic> row) async {
    await _dataSource.upsertProfile(userId, row);
  }

  /// Administrative update of an existing profile (direct UPDATE/PATCH)
  /// conforming to Supabase Row-Level Security policies.
  Future<void> adminUpdateProfile(String userId, Map<String, dynamic> row) async {
    await _dataSource.updateProfile(userId, row);
  }

  /// Administrative deletion of a user profile.
  Future<void> adminDeleteProfile(String userId) async {
    await _dataSource.deleteProfile(userId);
  }
}