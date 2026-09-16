// lib/features/scholarships/repositories/scholarship_repository.dart
//
// Repository/service split for the Scholarship domain, mirroring the profile
// feature: an injectable data source keeps persistence testable, and the
// repository is the only gateway to the `scholarships` table.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/scholarship.dart';

/// Low-level row access for the `scholarships` table.
abstract class ScholarshipDataSource {
  Future<List<Map<String, dynamic>>> fetchScholarships();
  Future<List<Map<String, dynamic>>> fetchScholarshipsByProvider(String providerId);
  Future<Map<String, dynamic>> createScholarship(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateScholarship(String id, Map<String, dynamic> data);
  Future<void> deleteScholarship(String id);
}

/// Production implementation backed by Supabase.
class SupabaseScholarshipDataSource implements ScholarshipDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> fetchScholarships() async {
    final rows = await _client
        .from('scholarships')
        .select()
        .eq('is_active', true)
        .order('deadline', ascending: true);
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchScholarshipsByProvider(
    String providerId,
  ) async {
    final rows = await _client
        .from('scholarships')
        .select()
        .eq('created_by', providerId)
        .order('created_at', ascending: false);
    return rows;
  }

  @override
  Future<Map<String, dynamic>> createScholarship(
    Map<String, dynamic> data,
  ) async {
    final row = await _client
        .from('scholarships')
        .insert(data)
        .select()
        .single();
    return row;
  }

  @override
  Future<Map<String, dynamic>> updateScholarship(
    String id,
    Map<String, dynamic> data,
  ) async {
    final row = await _client
        .from('scholarships')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return row;
  }

  @override
  Future<void> deleteScholarship(String id) async {
    await _client.from('scholarships').delete().eq('id', id);
  }
}

class ScholarshipRepository {
  ScholarshipRepository({ScholarshipDataSource? dataSource})
      : _dataSource = dataSource ?? SupabaseScholarshipDataSource();

  final ScholarshipDataSource _dataSource;

  /// Fetches all active scholarships ordered by soonest deadline.
  Future<List<Scholarship>> fetchActive() async {
    final rows = await _dataSource.fetchScholarships();
    final scholarships =
        rows.map(Scholarship.fromJson).toList();
    scholarships.sort((a, b) => a.deadline.compareTo(b.deadline));
    return scholarships;
  }

  /// Fetches all scholarships created by a specific provider (active and inactive).
  Future<List<Scholarship>> fetchByProvider(String providerId) async {
    final rows = await _dataSource.fetchScholarshipsByProvider(providerId);
    return rows.map(Scholarship.fromJson).toList();
  }

  /// Creates a new scholarship and returns the parsed domain model.
  Future<Scholarship> createScholarship(Map<String, dynamic> data) async {
    final row = await _dataSource.createScholarship(data);
    return Scholarship.fromJson(row);
  }

  /// Updates an existing scholarship and returns the updated domain model.
  Future<Scholarship> updateScholarship(
    String id,
    Map<String, dynamic> data,
  ) async {
    final row = await _dataSource.updateScholarship(id, data);
    return Scholarship.fromJson(row);
  }

  /// Toggles the active status of a scholarship.
  Future<void> toggleActive(String id, bool isActive) async {
    await _dataSource.updateScholarship(id, {'is_active': isActive});
  }

  /// Deletes a scholarship by id.
  Future<void> deleteScholarship(String id) async {
    await _dataSource.deleteScholarship(id);
  }
}
