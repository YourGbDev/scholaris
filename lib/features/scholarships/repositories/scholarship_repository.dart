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
}

class ScholarshipRepository {
  ScholarshipRepository({ScholarshipDataSource? dataSource})
      : _dataSource = dataSource ?? SupabaseScholarshipDataSource();

  final ScholarshipDataSource _dataSource;

  /// Fetches all active scholarships ordered by soonest deadline.
  Future<List<Scholarship>> fetchActive() async {
    final rows = await _dataSource.fetchScholarships();
    final scholarships =
        rows.map(Scholarship.fromJson).where((s) => s.isActive).toList();
    scholarships.sort((a, b) => a.deadline.compareTo(b.deadline));
    return scholarships;
  }
}
