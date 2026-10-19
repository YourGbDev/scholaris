// test/features/provider/org_controls_security_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/provider/data/organization_activity_repository.dart';
import 'package:scholaris/features/provider/data/organization_team_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship_capacity.dart';

/// Models backend PostgreSQL RLS & RPC authorization guards for Organization-Admin Controls.
class SecurityEnforcingOrgControlsDataSource
    implements OrganizationTeamDataSource, OrganizationActivityDataSource {
  SecurityEnforcingOrgControlsDataSource({
    required this.currentUserId,
    required this.currentUserRole,
    required this.userOrgId,
  });

  final String? Function() currentUserId;
  final String? Function() currentUserRole;
  final String? Function() userOrgId;

  // Multi-tenant Org A & Org B data stores
  final Map<String, List<Map<String, dynamic>>> _rosters = {
    'org-alpha': [
      {
        'user_id': 'admin-alpha',
        'full_name': 'Atty. Maria Santos',
        'role': 'org_admin',
        'active': true,
        'assigned_scholarship_count': 3,
      },
      {
        'user_id': 'reviewer-alpha',
        'full_name': 'Prof. Juan Luna',
        'role': 'reviewer',
        'active': true,
        'assigned_scholarship_count': 2,
      },
    ],
    'org-beta': [
      {
        'user_id': 'admin-beta',
        'full_name': 'Dr. Jose Rizal',
        'role': 'org_admin',
        'active': true,
        'assigned_scholarship_count': 1,
      },
    ],
  };

  final Map<String, List<Map<String, dynamic>>> _activityLogs = {
    'org-alpha': [
      {
        'id': 'log-1',
        'actor_id': 'admin-alpha',
        'actor_name': 'Atty. Maria Santos',
        'action': 'assign_reviewer',
        'target_type': 'scholarship',
        'target_id': 'sch-alpha-1',
        'details': {'reviewer_id': 'reviewer-alpha'},
        'created_at': '2026-10-19T08:00:00Z',
      },
    ],
    'org-beta': [
      {
        'id': 'log-2',
        'actor_id': 'admin-beta',
        'actor_name': 'Dr. Jose Rizal',
        'action': 'create_scholarship',
        'target_type': 'scholarship',
        'target_id': 'sch-beta-1',
        'details': {},
        'created_at': '2026-10-19T09:00:00Z',
      },
    ],
  };

  final List<Map<String, dynamic>> _assignments = [];

  // Scholarships capacity tracking
  final Map<String, Map<String, dynamic>> _scholarshipCapacities = {
    'sch-alpha-1': {
      'scholarship_id': 'sch-alpha-1',
      'organization_id': 'org-alpha',
      'total_slots': 5,
      'occupied_slots': 3,
      'remaining_slots': 2,
      'is_uncapped': false,
    },
  };

  @override
  Future<List<Map<String, dynamic>>> fetchRoster(String organizationId) async {
    final callerId = currentUserId();
    final callerRole = currentUserRole();
    final callerOrg = userOrgId();

    if (callerId == null) {
      throw Exception('42501: Authentication required');
    }

    // Role check: students cannot access provider team roster
    if (callerRole == 'student') {
      return [];
    }

    // Tenant boundary: only members of the organization or platform admins can fetch roster
    if (callerRole != 'admin' && callerOrg != organizationId) {
      return [];
    }

    final raw = _rosters[organizationId] ?? [];
    // Column minimization: ensure no student rows or student PII bleed into roster
    return raw
        .where((m) => m['role'] != 'student')
        .map((m) => {
              'user_id': m['user_id'],
              'full_name': m['full_name'],
              'role': m['role'],
              'active': m['active'],
              'assigned_scholarship_count': m['assigned_scholarship_count'],
            })
        .toList();
  }

  @override
  Future<Map<String, dynamic>> assignReviewer(
    String scholarshipId,
    String reviewerId,
  ) async {
    final callerId = currentUserId();
    final callerRole = currentUserRole();
    final callerOrg = userOrgId();

    if (callerId == null) throw Exception('42501: Authentication required');

    // Only org_admin or platform admin can assign
    if (callerRole != 'admin' && callerRole != 'org_admin') {
      throw Exception('42501: Only organization admins can assign reviewers');
    }

    // Ensure reviewer belongs to caller organization and is active reviewer
    final orgMembers = _rosters[callerOrg] ?? [];
    final reviewerMember = orgMembers.firstWhere(
      (m) => m['user_id'] == reviewerId && m['active'] == true,
      orElse: () => {},
    );

    if (reviewerMember.isEmpty ||
        !['reviewer', 'org_admin'].contains(reviewerMember['role'])) {
      throw Exception('P0002: User is not an active reviewer for this organization');
    }

    final record = {
      'id': 'asg-${_assignments.length + 1}',
      'scholarship_id': scholarshipId,
      'reviewer_id': reviewerId,
      'assigned_by': callerId,
      'assigned_at': DateTime.now().toUtc().toIso8601String(),
    };
    _assignments.add(record);
    return record;
  }

  @override
  Future<bool> unassignReviewer(
    String scholarshipId,
    String reviewerId,
  ) async {
    final callerRole = currentUserRole();
    if (callerRole != 'admin' && callerRole != 'org_admin') {
      throw Exception('42501: Only organization admins can unassign reviewers');
    }
    _assignments.removeWhere(
      (a) =>
          a['scholarship_id'] == scholarshipId &&
          a['reviewer_id'] == reviewerId,
    );
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAssignmentsForScholarship(
    String scholarshipId,
  ) async {
    return _assignments
        .where((a) => a['scholarship_id'] == scholarshipId)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActivityLogs(
    String organizationId, {
    int limit = 50,
    int offset = 0,
    String? actionFilter,
  }) async {
    final callerId = currentUserId();
    final callerRole = currentUserRole();
    final callerOrg = userOrgId();

    if (callerId == null) throw Exception('42501: Authentication required');

    // Cross-tenant boundary check: Org Admin cannot read other organization logs
    if (callerRole != 'admin' && callerOrg != organizationId) {
      return []; // Isolated: 0 rows returned
    }

    var logs = _activityLogs[organizationId] ?? [];
    if (actionFilter != null) {
      logs = logs.where((l) => l['action'] == actionFilter).toList();
    }
    return logs;
  }

  /// Reduces slots for scholarship, strictly guarding against lowering below occupied count
  Future<void> updateScholarshipSlots(String scholarshipId, int newSlots) async {
    final cap = _scholarshipCapacities[scholarshipId];
    if (cap == null) throw Exception('Scholarship not found');

    final occupied = cap['occupied_slots'] as int;
    if (newSlots < occupied) {
      throw Exception(
        'P0002: Cannot reduce total slots to $newSlots: $occupied slots are currently occupied by approved scholars.',
      );
    }
    cap['total_slots'] = newSlots;
    cap['remaining_slots'] = newSlots - occupied;
  }
}

void main() {
  group('Organization-Admin Controls Security & Boundary Tests', () {
    late SecurityEnforcingOrgControlsDataSource dataSource;
    late OrganizationTeamRepository teamRepo;
    late OrganizationActivityRepository activityRepo;

    String? currentUserId;
    String? currentUserRole;
    String? currentOrgId;

    setUp(() {
      currentUserId = 'admin-alpha';
      currentUserRole = 'org_admin';
      currentOrgId = 'org-alpha';

      dataSource = SecurityEnforcingOrgControlsDataSource(
        currentUserId: () => currentUserId,
        currentUserRole: () => currentUserRole,
        userOrgId: () => currentOrgId,
      );

      teamRepo = OrganizationTeamRepository(dataSource: dataSource);
      activityRepo = OrganizationActivityRepository(dataSource: dataSource);
    });

    test('Org Admin Alpha successfully fetches own organization roster with column minimization', () async {
      final roster = await teamRepo.fetchRoster('org-alpha');
      expect(roster.length, 2);
      expect(roster.first.fullName, 'Atty. Maria Santos');
      expect(roster.first.isOrgAdmin, isTrue);

      // Verify no student roles exist in roster
      for (final member in roster) {
        expect(member.role, isNot('student'));
      }
    });

    test('Student attempting to query organization roster receives 0 rows', () async {
      currentUserId = 'student-1';
      currentUserRole = 'student';
      currentOrgId = null;

      final roster = await teamRepo.fetchRoster('org-alpha');
      expect(roster, isEmpty);
    });

    test('Cross-tenant isolation: Org Admin Alpha cannot access Org Beta activity logs', () async {
      // Admin Alpha querying Org Beta logs receives empty list (0 rows)
      final logsBeta = await activityRepo.fetchActivityLogs('org-beta');
      expect(logsBeta, isEmpty);

      // Admin Alpha querying own Org Alpha logs succeeds
      final logsAlpha = await activityRepo.fetchActivityLogs('org-alpha');
      expect(logsAlpha.length, 1);
      expect(logsAlpha.first.action, 'assign_reviewer');
    });

    test('Reviewer assignment guard: non-admin cannot assign reviewers', () async {
      currentUserId = 'reviewer-alpha';
      currentUserRole = 'reviewer';

      expect(
        () => teamRepo.assignReviewer('sch-alpha-1', 'reviewer-alpha'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('42501: Only organization admins can assign reviewers'),
        )),
      );
    });

    test('Reviewer assignment guard: assigning non-member reviewer throws P0002', () async {
      // Attempting to assign admin-beta (who belongs to Org Beta) to Org Alpha grant
      expect(
        () => teamRepo.assignReviewer('sch-alpha-1', 'admin-beta'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('P0002: User is not an active reviewer for this organization'),
        )),
      );
    });

    test('Authorized Org Admin successfully assigns active reviewer and tracks assignment', () async {
      final asg = await teamRepo.assignReviewer('sch-alpha-1', 'reviewer-alpha');
      expect(asg.scholarshipId, 'sch-alpha-1');
      expect(asg.reviewerId, 'reviewer-alpha');
      expect(asg.assignedBy, 'admin-alpha');

      final activeAssignments = await teamRepo.fetchAssignmentsForScholarship('sch-alpha-1');
      expect(activeAssignments.length, 1);
      expect(activeAssignments.first.reviewerId, 'reviewer-alpha');
    });

    test('Capacity reduction guard: lowering slots below occupied count throws P0002', () async {
      // sch-alpha-1 has occupied_slots = 3. Attempting to reduce slots to 2
      expect(
        () => dataSource.updateScholarshipSlots('sch-alpha-1', 2),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('P0002: Cannot reduce total slots to 2: 3 slots are currently occupied'),
        )),
      );

      // Reducing to 3 (exact occupied count) succeeds
      await dataSource.updateScholarshipSlots('sch-alpha-1', 3);
      final cap = dataSource._scholarshipCapacities['sch-alpha-1']!;
      expect(cap['total_slots'], 3);
      expect(cap['remaining_slots'], 0);
    });

    test('Capacity model correctly handles full booking and uncap state', () {
      final fullModel = ScholarshipCapacity.fromJson({
        'scholarship_id': 'sch-1',
        'total_slots': 5,
        'occupied_slots': 5,
        'remaining_slots': 0,
        'is_uncapped': false,
      });
      expect(fullModel.remainingSlots, 0);
      expect(fullModel.remainingLabel, 'Fully Booked');

      final uncappedModel = ScholarshipCapacity.fromJson({
        'scholarship_id': 'sch-2',
        'total_slots': null,
        'occupied_slots': 14,
        'remaining_slots': null,
        'is_uncapped': true,
      });
      expect(uncappedModel.isUncapped, isTrue);
      expect(uncappedModel.remainingLabel, 'Uncapped');
      expect(uncappedModel.occupancyRatioLabel, '14 awarded (Uncapped)');
    });
  });
}
