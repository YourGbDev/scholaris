// lib/features/provider/providers/organization_team_provider.dart
//
// Riverpod providers for organization team roster and reviewer assignments.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/organization_team_repository.dart';
import '../models/organization_team_member.dart';
import '../models/scholarship_reviewer_assignment.dart';
import 'provider_sub_role_provider.dart';

final organizationTeamRepositoryProvider =
    Provider<OrganizationTeamRepository>((ref) {
  return OrganizationTeamRepository();
});

final organizationRosterProvider =
    FutureProvider<List<OrganizationTeamMember>>((ref) async {
  final orgId = ref.watch(currentOrganizationIdProvider);
  if (orgId == null) return const [];
  return ref.watch(organizationTeamRepositoryProvider).fetchRoster(orgId);
});

final scholarshipReviewerAssignmentsProvider =
    FutureProvider.family<List<ScholarshipReviewerAssignment>, String>(
        (ref, scholarshipId) async {
  return ref
      .watch(organizationTeamRepositoryProvider)
      .fetchAssignmentsForScholarship(scholarshipId);
});
