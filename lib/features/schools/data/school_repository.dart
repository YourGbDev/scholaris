// lib/features/schools/data/school_repository.dart
//
// Repository for the School catalog domain backed by public.schools and
// public.add_custom_school RPC.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/school.dart';

abstract class SchoolDataSource {
  Future<List<Map<String, dynamic>>> fetchSchools();
  Future<String> addCustomSchool(String name);
}

class SupabaseSchoolDataSource implements SchoolDataSource {
  SupabaseSchoolDataSource({SupabaseClient? client}) : _providedClient = client;
  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> fetchSchools() async {
    final rows = await _client
        .from('schools')
        .select()
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<String> addCustomSchool(String name) async {
    final res = await _client.rpc('add_custom_school', params: {'p_name': name});
    return res.toString();
  }
}

class SchoolRepository {
  SchoolRepository({SchoolDataSource? dataSource})
      : _dataSource = dataSource ?? SupabaseSchoolDataSource();

  final SchoolDataSource _dataSource;

  Future<List<School>> fetchSchools() async {
    final rows = await _dataSource.fetchSchools();
    return rows.map(School.fromJson).toList();
  }

  Future<List<School>> searchSchools(String query) async {
    final all = await fetchSchools();
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all.where((school) {
      if (school.name.toLowerCase().contains(q)) return true;
      if (school.normalizedName.contains(q)) return true;
      return school.aliases.any((alias) => alias.toLowerCase().contains(q));
    }).toList();
  }

  Future<String> addSchool(String name) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('School name cannot be empty');
    }
    return _dataSource.addCustomSchool(name.trim());
  }
}
