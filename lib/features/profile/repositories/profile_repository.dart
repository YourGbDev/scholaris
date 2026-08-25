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
  Future<void> upsertProfile(String userId, Map<String, dynamic> row);
}

/// Production implementation backed by Supabase.
class SupabaseProfileDataSource implements ProfileDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    return _client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  @override
  Future<void> upsertProfile(String userId, Map<String, dynamic> row) async {
    await _client.from('profiles').upsert({'id': userId, ...row});
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
}