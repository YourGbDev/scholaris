// lib/features/scholarships/data/scholarship_capacity_repository.dart
//
// Repository for aggregate scholarship capacity queries backed by
// public.scholarship_capacities security barrier view.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/scholarship_capacity.dart';

abstract class ScholarshipCapacityDataSource {
  Future<Map<String, dynamic>?> fetchCapacity(String scholarshipId);
  Future<List<Map<String, dynamic>>> fetchAllCapacities();
}

class SupabaseScholarshipCapacityDataSource
    implements ScholarshipCapacityDataSource {
  SupabaseScholarshipCapacityDataSource({SupabaseClient? client})
      : _providedClient = client;
  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  @override
  Future<Map<String, dynamic>?> fetchCapacity(String scholarshipId) async {
    final row = await _client
        .from('scholarship_capacities')
        .select()
        .eq('scholarship_id', scholarshipId)
        .maybeSingle();
    return row;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllCapacities() async {
    final rows = await _client.from('scholarship_capacities').select();
    return List<Map<String, dynamic>>.from(rows);
  }
}

class ScholarshipCapacityRepository {
  ScholarshipCapacityRepository({ScholarshipCapacityDataSource? dataSource})
      : _dataSource = dataSource ?? SupabaseScholarshipCapacityDataSource();

  final ScholarshipCapacityDataSource _dataSource;

  Future<ScholarshipCapacity?> fetchCapacity(String scholarshipId) async {
    final row = await _dataSource.fetchCapacity(scholarshipId);
    if (row == null) return null;
    return ScholarshipCapacity.fromJson(row);
  }

  Future<Map<String, ScholarshipCapacity>> fetchAllCapacities() async {
    final rows = await _dataSource.fetchAllCapacities();
    final map = <String, ScholarshipCapacity>{};
    for (final row in rows) {
      final cap = ScholarshipCapacity.fromJson(row);
      map[cap.scholarshipId] = cap;
    }
    return map;
  }
}
