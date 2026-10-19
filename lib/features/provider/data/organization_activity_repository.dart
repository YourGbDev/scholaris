// lib/features/provider/data/organization_activity_repository.dart
//
// Repository for organization activity logs backed by
// public.get_organization_activity_logs RPC.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/organization_activity_log.dart';

abstract class OrganizationActivityDataSource {
  Future<List<Map<String, dynamic>>> fetchActivityLogs(
    String organizationId, {
    int limit = 50,
    int offset = 0,
    String? actionFilter,
  });
}

class SupabaseOrganizationActivityDataSource
    implements OrganizationActivityDataSource {
  SupabaseOrganizationActivityDataSource({SupabaseClient? client})
      : _providedClient = client;
  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> fetchActivityLogs(
    String organizationId, {
    int limit = 50,
    int offset = 0,
    String? actionFilter,
  }) async {
    final res = await _client.rpc(
      'get_organization_activity_logs',
      params: {
        'p_organization_id': organizationId,
        'p_limit': limit,
        'p_offset': offset,
        'p_action_filter': actionFilter,
      },
    );
    if (res is List) {
      return List<Map<String, dynamic>>.from(res);
    }
    return const [];
  }
}

class OrganizationActivityRepository {
  OrganizationActivityRepository({
    OrganizationActivityDataSource? dataSource,
  }) : _dataSource = dataSource ?? SupabaseOrganizationActivityDataSource();

  final OrganizationActivityDataSource _dataSource;

  Future<List<OrganizationActivityLog>> fetchActivityLogs(
    String organizationId, {
    int limit = 50,
    int offset = 0,
    String? actionFilter,
  }) async {
    final rows = await _dataSource.fetchActivityLogs(
      organizationId,
      limit: limit,
      offset: offset,
      actionFilter: actionFilter,
    );
    return rows.map(OrganizationActivityLog.fromJson).toList();
  }
}
