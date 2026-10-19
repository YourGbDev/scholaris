// test/features/provider/organization_team_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/provider/data/organization_team_repository.dart';
import 'package:scholaris/features/provider/models/organization_team_member.dart';
import 'package:scholaris/features/provider/models/scholarship_reviewer_assignment.dart';

class FakeOrganizationTeamDataSource implements OrganizationTeamDataSource {
  FakeOrganizationTeamDataSource() {
    _roster = [
      {
        'user_id': 'user-admin',
        'full_name': 'DOST Director',
        'role': 'org_admin',
        'active': true,
        'assigned_scholarship_count': 3,
      },
      {
        'user_id': 'user-evaluator',
        'full_name': 'Dr. Renato Solidum Jr.',
        'role': 'reviewer',
        'active': true,
        'assigned_scholarship_count': 2,
      },
    ];
    _assignments = [
      {
        'id': 'asg-1',
        'scholarship_id': 'sch-1',
        'reviewer_id': 'user-evaluator',
        'assigned_by': 'user-admin',
        'assigned_at': '2026-10-19T08:00:00Z',
      },
    ];
  }

  late List<Map<String, dynamic>> _roster;
  late List<Map<String, dynamic>> _assignments;

  @override
  Future<List<Map<String, dynamic>>> fetchRoster(String organizationId) async {
    return List<Map<String, dynamic>>.from(_roster);
  }

  @override
  Future<Map<String, dynamic>> assignReviewer(
    String scholarshipId,
    String reviewerId,
  ) async {
    final existing = _assignments.firstWhere(
      (a) =>
          a['scholarship_id'] == scholarshipId &&
          a['reviewer_id'] == reviewerId,
      orElse: () => {},
    );
    if (existing.isNotEmpty) return existing;

    final newRecord = {
      'id': 'asg-${_assignments.length + 1}',
      'scholarship_id': scholarshipId,
      'reviewer_id': reviewerId,
      'assigned_by': 'caller-admin',
      'assigned_at': DateTime.now().toUtc().toIso8601String(),
    };
    _assignments.add(newRecord);
    return newRecord;
  }

  @override
  Future<bool> unassignReviewer(
    String scholarshipId,
    String reviewerId,
  ) async {
    final initialLength = _assignments.length;
    _assignments.removeWhere(
      (a) =>
          a['scholarship_id'] == scholarshipId &&
          a['reviewer_id'] == reviewerId,
    );
    return _assignments.length < initialLength;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAssignmentsForScholarship(
    String scholarshipId,
  ) async {
    return _assignments
        .where((a) => a['scholarship_id'] == scholarshipId)
        .toList();
  }
}

void main() {
  group('Organization Team Models Tests', () {
    test('OrganizationTeamMember fromJson and role helpers', () {
      final json = {
        'user_id': 'user-1',
        'full_name': 'Dr. Maria Santos',
        'role': 'org_admin',
        'active': true,
        'assigned_scholarship_count': 5,
      };

      final member = OrganizationTeamMember.fromJson(json);
      expect(member.userId, 'user-1');
      expect(member.fullName, 'Dr. Maria Santos');
      expect(member.role, 'org_admin');
      expect(member.isOrgAdmin, isTrue);
      expect(member.isReviewer, isFalse);
      expect(member.roleDisplay, 'Organization Admin');
      expect(member.assignedScholarshipCount, 5);

      final reviewer = OrganizationTeamMember.fromJson({
        'user_id': 'user-2',
        'full_name': 'Academic Reviewer',
        'role': 'reviewer',
      });
      expect(reviewer.isReviewer, isTrue);
      expect(reviewer.roleDisplay, 'Academic Evaluator');
    });

    test('ScholarshipReviewerAssignment fromJson and toJson', () {
      final json = {
        'id': 'asg-1',
        'scholarship_id': 'sch-1',
        'reviewer_id': 'rev-1',
        'assigned_by': 'admin-1',
        'assigned_at': '2026-10-19T08:00:00.000Z',
      };

      final assignment = ScholarshipReviewerAssignment.fromJson(json);
      expect(assignment.id, 'asg-1');
      expect(assignment.scholarshipId, 'sch-1');
      expect(assignment.reviewerId, 'rev-1');

      final out = assignment.toJson();
      expect(out['id'], 'asg-1');
      expect(out['reviewer_id'], 'rev-1');
    });
  });

  group('OrganizationTeamRepository Tests', () {
    late FakeOrganizationTeamDataSource dataSource;
    late OrganizationTeamRepository repository;

    setUp(() {
      dataSource = FakeOrganizationTeamDataSource();
      repository = OrganizationTeamRepository(dataSource: dataSource);
    });

    test('fetchRoster returns all parsed members', () async {
      final roster = await repository.fetchRoster('org-dost');
      expect(roster.length, 2);
      expect(roster.first.isOrgAdmin, isTrue);
      expect(roster.last.isReviewer, isTrue);
    });

    test('fetchAssignmentsForScholarship returns matching assignments',
        () async {
      final assignments =
          await repository.fetchAssignmentsForScholarship('sch-1');
      expect(assignments.length, 1);
      expect(assignments.first.reviewerId, 'user-evaluator');
    });

    test('assignReviewer adds a new assignment', () async {
      final assignment = await repository.assignReviewer('sch-1', 'user-admin');
      expect(assignment.scholarshipId, 'sch-1');
      expect(assignment.reviewerId, 'user-admin');

      final list = await repository.fetchAssignmentsForScholarship('sch-1');
      expect(list.length, 2);
    });

    test('unassignReviewer removes the assignment', () async {
      final success =
          await repository.unassignReviewer('sch-1', 'user-evaluator');
      expect(success, isTrue);

      final list = await repository.fetchAssignmentsForScholarship('sch-1');
      expect(list, isEmpty);
    });
  });
}
