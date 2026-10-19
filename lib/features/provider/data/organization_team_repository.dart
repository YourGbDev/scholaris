// lib/features/provider/data/organization_team_repository.dart
//
// Repository for organization team roster and reviewer assignments backed by
// public.get_organization_roster, public.assign_scholarship_reviewer, and
// public.unassign_scholarship_reviewer RPCs.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/organization_team_member.dart';
import '../models/scholarship_reviewer_assignment.dart';

abstract class OrganizationTeamDataSource {
  Future<List<Map<String, dynamic>>> fetchRoster(String organizationId);
  Future<Map<String, dynamic>> assignReviewer(
    String scholarshipId,
    String reviewerId,
  );
  Future<bool> unassignReviewer(
    String scholarshipId,
    String reviewerId,
  );
  Future<List<Map<String, dynamic>>> fetchAssignmentsForScholarship(
    String scholarshipId,
  );
}

class SupabaseOrganizationTeamDataSource
    implements OrganizationTeamDataSource {
  SupabaseOrganizationTeamDataSource({SupabaseClient? client})
      : _providedClient = client;
  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> fetchRoster(String organizationId) async {
    final res = await _client.rpc(
      'get_organization_roster',
      params: {'p_organization_id': organizationId},
    );
    if (res is List) {
      return List<Map<String, dynamic>>.from(res);
    }
    return const [];
  }

  @override
  Future<Map<String, dynamic>> assignReviewer(
    String scholarshipId,
    String reviewerId,
  ) async {
    final res = await _client.rpc(
      'assign_scholarship_reviewer',
      params: {
        'p_scholarship_id': scholarshipId,
        'p_reviewer_id': reviewerId,
      },
    );
    if (res is Map<String, dynamic>) {
      return res;
    }
    if (res is List && res.isNotEmpty && res.first is Map<String, dynamic>) {
      return res.first as Map<String, dynamic>;
    }
    return <String, dynamic>{
      'scholarship_id': scholarshipId,
      'reviewer_id': reviewerId,
    };
  }

  @override
  Future<bool> unassignReviewer(
    String scholarshipId,
    String reviewerId,
  ) async {
    final res = await _client.rpc(
      'unassign_scholarship_reviewer',
      params: {
        'p_scholarship_id': scholarshipId,
        'p_reviewer_id': reviewerId,
      },
    );
    return res == true;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAssignmentsForScholarship(
    String scholarshipId,
  ) async {
    final res = await _client
        .from('scholarship_reviewer_assignments')
        .select()
        .eq('scholarship_id', scholarshipId);
    return List<Map<String, dynamic>>.from(res);
  }
}

class OrganizationTeamRepository {
  OrganizationTeamRepository({
    OrganizationTeamDataSource? dataSource,
  }) : _dataSource = dataSource ?? SupabaseOrganizationTeamDataSource();

  final OrganizationTeamDataSource _dataSource;

  Future<List<OrganizationTeamMember>> fetchRoster(
    String organizationId,
  ) async {
    final rows = await _dataSource.fetchRoster(organizationId);
    return rows.map(OrganizationTeamMember.fromJson).toList();
  }

  Future<ScholarshipReviewerAssignment> assignReviewer(
    String scholarshipId,
    String reviewerId,
  ) async {
    final row = await _dataSource.assignReviewer(scholarshipId, reviewerId);
    return ScholarshipReviewerAssignment.fromJson(row);
  }

  Future<bool> unassignReviewer(
    String scholarshipId,
    String reviewerId,
  ) async {
    return _dataSource.unassignReviewer(scholarshipId, reviewerId);
  }

  Future<List<ScholarshipReviewerAssignment>> fetchAssignmentsForScholarship(
    String scholarshipId,
  ) async {
    final rows =
        await _dataSource.fetchAssignmentsForScholarship(scholarshipId);
    return rows.map(ScholarshipReviewerAssignment.fromJson).toList();
  }
}
