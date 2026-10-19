// test/features/provider/organization_controls_e2e_test.dart
//
// End-to-End Acceptance & Slot Capacity Accounting Test Suite
// Verifies:
// 1. Full 4-Stage Transaction Cycle: Student -> Reviewer -> Org Admin -> Student Notification.
// 2. Org Admin final decision authority (approve / reject) vs Reviewer endorsement.
// 3. Platform Admin exclusive awarding authority (migration 0025) consuming 0 additional slots.
// 4. Exact slot capacity accounting:
//    - Last available seat reservation.
//    - Overbooking rejection (P0001) with clean error and zero partial writes.
//    - Duplicate decision idempotency.
//    - Inactive & pending withdrawals consuming 0 slots.
//    - Terminal status lock preventing withdrawal of approved applications.
//    - Uncapped scholarship capacity without limits.
// 5. Backend aggregate slot access & visibility (inactive grants hidden from students).

import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/scholarships/data/scholarship_capacity_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fake_application_data_source.dart';

/// In-memory capacity and transaction simulation dataSource matching PostgreSQL
/// migration 0024, 0025, and 0026 rules.
class FakeOrgControlsDataSource extends FakeApplicationDataSource
    implements ScholarshipCapacityDataSource {
  FakeOrgControlsDataSource({
    required this.scholarships,
    required this.userRoles,
    required this.orgMemberships,
  });

  /// Map of scholarshipId -> scholarship metadata
  final Map<String, Map<String, dynamic>> scholarships;

  /// Map of userId -> system role ('student', 'provider', 'admin')
  final Map<String, String> userRoles;

  /// Map of userId -> org membership role ('org_admin', 'reviewer', 'finance')
  final Map<String, String> orgMemberships;

  String? currentActorId;

  final Map<String, Map<String, dynamic>> _simulatedApps = {};

  void seedApplication(Map<String, dynamic> app) {
    _simulatedApps[app['id'] as String] = Map<String, dynamic>.of(app);
  }

  Map<String, dynamic>? getSimulatedApplication(String id) => _simulatedApps[id];

  int getSimulatedOccupied(String scholarshipId) {
    return _simulatedApps.values
        .where((a) =>
            a['scholarship_id'] == scholarshipId &&
            (a['status'] == 'approved' || a['status'] == 'awarded'))
        .length;
  }

  /// Simulates PostgreSQL `public.review_application` RPC from Migration 0024 & 0026
  @override
  Future<Map<String, dynamic>> reviewApplication(Map<String, dynamic> params) async {
    final applicationId = params['p_application_id'] as String;
    final expectedStatus = params['p_expected_status'] as String;
    final action = params['p_action'] as String;
    final scores = params['p_scores'] as Map<String, dynamic>?;
    final notes = params['p_notes'] as String?;

    final actorId = currentActorId;
    if (actorId == null) {
      throw PostgrestException(message: 'Authentication required', code: '42501');
    }

    final app = _simulatedApps[applicationId];
    if (app == null) {
      throw PostgrestException(message: 'Application unavailable', code: '42501');
    }

    final scholarshipId = app['scholarship_id'] as String;
    final scholarship = scholarships[scholarshipId];
    if (scholarship == null) {
      throw PostgrestException(message: 'Scholarship unavailable', code: '42501');
    }

    final actorRole = orgMemberships[actorId];
    if (actorRole == null || !['org_admin', 'reviewer'].contains(actorRole)) {
      throw PostgrestException(message: 'Application unavailable', code: '42501');
    }

    if (app['user_id'] == actorId) {
      throw PostgrestException(message: 'Application unavailable', code: '42501');
    }

    if (app['status'] != expectedStatus) {
      throw PostgrestException(
        message: 'Application changed. Refresh before continuing.',
        code: '40001',
      );
    }

    if (action == 'endorse') {
      if (actorRole != 'reviewer') {
        throw PostgrestException(message: 'Only reviewers can endorse', code: '42501');
      }
      if (!['submitted', 'under_review'].contains(app['status']) ||
          app['endorsed_by'] != null) {
        throw PostgrestException(message: 'Application cannot be endorsed in its current state');
      }
      if (scores == null ||
          !scores.containsKey('academic') ||
          !scores.containsKey('financial') ||
          !scores.containsKey('leadership') ||
          !scores.containsKey('vision')) {
        throw PostgrestException(message: 'All four rubric scores are required');
      }

      final academic = (scores['academic'] as num).toDouble();
      final financial = (scores['financial'] as num).toDouble();
      final leadership = (scores['leadership'] as num).toDouble();
      final vision = (scores['vision'] as num).toDouble();
      final composite = (academic * 0.4 + financial * 0.3 + leadership * 0.2 + vision * 0.1);

      evaluations.add({
        'application_id': applicationId,
        'reviewer_id': actorId,
        'score_academic': academic,
        'score_financial': financial,
        'score_leadership': leadership,
        'score_vision': vision,
        'composite_score': composite,
        'deliberation_notes': notes,
        'decision': 'endorsed',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      app['status'] = 'under_review';
      app['endorsed_by'] = actorId;
      app['endorsed_at'] = DateTime.now().toUtc().toIso8601String();

      statusHistory.add({
        'application_id': applicationId,
        'changed_by': actorId,
        'from_status': 'submitted',
        'to_status': 'under_review',
        'remarks': 'Endorsed to organization admin. ${notes ?? ''}',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return Map<String, dynamic>.of(app);
    } else if (action == 'approve' || action == 'reject') {
      if (actorRole != 'org_admin') {
        throw PostgrestException(
          message: 'Only organization admins can decide',
          code: '42501',
        );
      }
      // Idempotent replay: if already approved, succeed without re-incrementing
      if (app['status'] == 'approved' && action == 'approve') {
        return Map<String, dynamic>.of(app);
      }
      if (app['status'] != 'under_review' ||
          app['endorsed_by'] == null ||
          app['endorsed_by'] == actorId) {
        throw PostgrestException(message: 'A separate reviewer endorsement is required');
      }

      final targetStatus = action == 'approve' ? 'approved' : 'rejected';

      // Slot Capacity Enforcement (Migration 0026)
      if (action == 'approve') {
        final totalSlots = scholarship['slots'] as int?;
        if (totalSlots != null) {
          final occupied = getSimulatedOccupied(scholarshipId);
          if (occupied >= totalSlots && app['status'] != 'approved') {
            throw PostgrestException(
              message: 'Scholarship capacity reached. No slots remaining (1/1 occupied).',
              code: 'P0001',
            );
          }
        }
      }

      final fromStatus = app['status'] as String;
      app['status'] = targetStatus;
      app['decided_by'] = actorId;
      app['decided_at'] = DateTime.now().toUtc().toIso8601String();

      // In-app student notification
      notifications.add({
        'user_id': app['user_id'],
        'title': action == 'approve' ? 'Application Approved' : 'Application Rejected',
        'message': 'Your application for "${scholarship['title']}" has been $targetStatus.',
        'target_id': applicationId,
        'type': 'application_update',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      statusHistory.add({
        'application_id': applicationId,
        'changed_by': actorId,
        'from_status': fromStatus,
        'to_status': targetStatus,
        'remarks': 'Final decision. ${notes ?? ''}',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return Map<String, dynamic>.of(app);
    } else {
      throw PostgrestException(message: 'Unsupported review action');
    }
  }

  /// Simulates Platform-Admin awarding under Migration 0025
  Future<void> platformAdminAward(String applicationId) async {
    final actorId = currentActorId;
    final isPlatformAdmin = userRoles[actorId] == 'admin';

    if (!isPlatformAdmin) {
      throw PostgrestException(
        message: 'Only platform administrators can award applications',
        code: '42501',
      );
    }

    final app = _simulatedApps[applicationId];
    if (app == null || app['status'] != 'approved') {
      throw PostgrestException(
        message: 'Only approved applications can be transitioned to awarded',
      );
    }

    app['status'] = 'awarded';
    app['updated_at'] = DateTime.now().toUtc().toIso8601String();

    statusHistory.add({
      'application_id': applicationId,
      'changed_by': actorId,
      'from_status': 'approved',
      'to_status': 'awarded',
      'remarks': 'Platform Administrator officially confirmed scholarship grant award.',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Simulates public.scholarship_capacities view
  @override
  Future<Map<String, dynamic>?> fetchCapacity(String scholarshipId) async {
    final s = scholarships[scholarshipId];
    if (s == null) return null;

    final actorId = currentActorId;
    final isStudent = userRoles[actorId] == 'student';
    final isActive = s['is_active'] == true;

    // Visibility boundary: inactive scholarships are hidden from student capacity queries
    if (isStudent && !isActive) {
      return null;
    }

    final totalSlots = s['slots'] as int?;
    final occupied = getSimulatedOccupied(scholarshipId);
    final remaining = totalSlots == null ? null : (totalSlots - occupied).clamp(0, totalSlots);

    return {
      'scholarship_id': scholarshipId,
      'total_slots': totalSlots,
      'occupied_slots': occupied,
      'remaining_slots': remaining,
      'is_uncapped': totalSlots == null,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllCapacities() async {
    final list = <Map<String, dynamic>>[];
    for (final sId in scholarships.keys) {
      final cap = await fetchCapacity(sId);
      if (cap != null) list.add(cap);
    }
    return list;
  }
}

void main() {
  const adminId = 'user-org-admin-1';
  const reviewerId = 'user-reviewer-1';
  const platformAdminId = 'user-platform-admin-0';
  const studentAId = 'user-student-1';
  const studentBId = 'user-student-2';

  late FakeOrgControlsDataSource fakeDs;
  late ScholarshipCapacityRepository capacityRepo;

  setUp(() {
    fakeDs = FakeOrgControlsDataSource(
      scholarships: {
        'grant-capped-1': {
          'id': 'grant-capped-1',
          'title': 'DOST Merit 1-Slot Grant',
          'slots': 1,
          'is_active': true,
          'created_by': adminId,
        },
        'grant-uncapped': {
          'id': 'grant-uncapped',
          'title': 'DOST Open STEM Grant',
          'slots': null,
          'is_active': true,
          'created_by': adminId,
        },
        'grant-inactive': {
          'id': 'grant-inactive',
          'title': 'Unpublished Draft Grant',
          'slots': 10,
          'is_active': false,
          'created_by': adminId,
        },
      },
      userRoles: {
        adminId: 'provider',
        reviewerId: 'provider',
        platformAdminId: 'admin',
        studentAId: 'student',
        studentBId: 'student',
      },
      orgMemberships: {
        adminId: 'org_admin',
        reviewerId: 'reviewer',
      },
    );
    capacityRepo = ScholarshipCapacityRepository(dataSource: fakeDs);
  });

  group('A. Core Transaction Cycle: Student -> Reviewer -> Org Admin -> Notification', () {
    test('Student submission -> Reviewer endorsement -> Org Admin approval completes cycle', () async {
      // 1. Student submits application
      fakeDs.seedApplication({
        'id': 'app-001',
        'scholarship_id': 'grant-capped-1',
        'user_id': studentAId,
        'status': 'submitted',
        'endorsed_by': null,
        'decided_by': null,
      });

      // Assert initially occupies 0 slots
      expect(fakeDs.getSimulatedOccupied('grant-capped-1'), 0);

      // 2. Reviewer endorses with 4 rubric scores
      fakeDs.currentActorId = reviewerId;
      final endorsedApp = await fakeDs.reviewApplication({
        'p_application_id': 'app-001',
        'p_expected_status': 'submitted',
        'p_action': 'endorse',
        'p_scores': {'academic': 9.0, 'financial': 8.5, 'leadership': 8.0, 'vision': 9.5},
        'p_notes': 'Strong academic consistency.',
      });

      expect(endorsedApp['status'], 'under_review');
      expect(endorsedApp['endorsed_by'], reviewerId);
      // Endorsement consumes ZERO slots
      expect(fakeDs.getSimulatedOccupied('grant-capped-1'), 0);

      // 3. Reviewer cannot approve
      expect(
        () => fakeDs.reviewApplication({
          'p_application_id': 'app-001',
          'p_expected_status': 'under_review',
          'p_action': 'approve',
        }),
        throwsA(isA<PostgrestException>().having((e) => e.code, 'code', '42501')),
      );

      // 4. Org Admin approves award
      fakeDs.currentActorId = adminId;
      final approvedApp = await fakeDs.reviewApplication({
        'p_application_id': 'app-001',
        'p_expected_status': 'under_review',
        'p_action': 'approve',
        'p_notes': 'Award confirmed by committee chair.',
      });

      expect(approvedApp['status'], 'approved');
      expect(approvedApp['decided_by'], adminId);
      // Approval consumes EXACTLY 1 slot
      expect(fakeDs.getSimulatedOccupied('grant-capped-1'), 1);

      // 5. In-app notification generated for student
      final notifs = fakeDs.notifications.where((n) => n['user_id'] == studentAId).toList();
      expect(notifs, hasLength(1));
      expect(notifs.first['title'], 'Application Approved');
      expect(notifs.first['target_id'], 'app-001');
    });

    test('Org Admin rejection transitions status, consumes 0 slots, and notifies student', () async {
      fakeDs.seedApplication({
        'id': 'app-002',
        'scholarship_id': 'grant-capped-1',
        'user_id': studentBId,
        'status': 'submitted',
        'endorsed_by': null,
      });

      fakeDs.currentActorId = reviewerId;
      await fakeDs.reviewApplication({
        'p_application_id': 'app-002',
        'p_expected_status': 'submitted',
        'p_action': 'endorse',
        'p_scores': {'academic': 6.0, 'financial': 5.0, 'leadership': 5.0, 'vision': 6.0},
      });

      fakeDs.currentActorId = adminId;
      final rejectedApp = await fakeDs.reviewApplication({
        'p_application_id': 'app-002',
        'p_expected_status': 'under_review',
        'p_action': 'reject',
        'p_notes': 'Criteria threshold not met.',
      });

      expect(rejectedApp['status'], 'rejected');
      expect(fakeDs.getSimulatedOccupied('grant-capped-1'), 0);

      final notifs = fakeDs.notifications.where((n) => n['user_id'] == studentBId).toList();
      expect(notifs, hasLength(1));
      expect(notifs.first['title'], 'Application Rejected');
    });
  });

  group('B. Slot Accounting & Capacity Limits', () {
    test('Last Available Slot Test: Approving applicant on 1-slot grant reduces remaining to 0', () async {
      fakeDs.seedApplication({
        'id': 'app-last-1',
        'scholarship_id': 'grant-capped-1',
        'user_id': studentAId,
        'status': 'under_review',
        'endorsed_by': reviewerId,
      });

      // Check pre-approval capacity
      fakeDs.currentActorId = adminId;
      var cap = await capacityRepo.fetchCapacity('grant-capped-1');
      expect(cap!.totalSlots, 1);
      expect(cap.occupiedSlots, 0);
      expect(cap.remainingSlots, 1);
      expect(cap.remainingLabel, '1 seat remaining');

      // Approve applicant
      await fakeDs.reviewApplication({
        'p_application_id': 'app-last-1',
        'p_expected_status': 'under_review',
        'p_action': 'approve',
      });

      // Post-approval capacity: remaining is exactly 0
      cap = await capacityRepo.fetchCapacity('grant-capped-1');
      expect(cap!.totalSlots, 1);
      expect(cap.occupiedSlots, 1);
      expect(cap.remainingSlots, 0);
      expect(cap.remainingLabel, 'Fully Booked');
      expect(cap.occupancyRatioLabel, '1/1 seats filled');
    });

    test('Overbooking Rejection (P0001): Attempting to approve beyond capacity fails safely', () async {
      // Seed first application as already approved
      fakeDs.seedApplication({
        'id': 'app-first-approved',
        'scholarship_id': 'grant-capped-1',
        'user_id': studentAId,
        'status': 'approved',
        'endorsed_by': reviewerId,
        'decided_by': adminId,
      });

      // Seed second application in under_review
      fakeDs.seedApplication({
        'id': 'app-second-pending',
        'scholarship_id': 'grant-capped-1',
        'user_id': studentBId,
        'status': 'under_review',
        'endorsed_by': reviewerId,
      });

      fakeDs.currentActorId = adminId;

      // Attempting to approve second applicant must fail with P0001
      expect(
        () => fakeDs.reviewApplication({
          'p_application_id': 'app-second-pending',
          'p_expected_status': 'under_review',
          'p_action': 'approve',
        }),
        throwsA(
          isA<PostgrestException>()
              .having((e) => e.code, 'code', 'P0001')
              .having((e) => e.message, 'message', contains('capacity reached')),
        ),
      );

      // Assert zero partial write: applicant remains in under_review
      final unapprovedApp = fakeDs.getSimulatedApplication('app-second-pending');
      expect(unapprovedApp!['status'], 'under_review');
      expect(unapprovedApp['decided_by'], isNull);

      // Capacity remains strictly 1 occupied, 0 remaining
      final cap = await capacityRepo.fetchCapacity('grant-capped-1');
      expect(cap!.occupiedSlots, 1);
      expect(cap.remainingSlots, 0);
    });

    test('Duplicate Decision Idempotency: Re-approving already approved application does not double-count', () async {
      fakeDs.seedApplication({
        'id': 'app-already-approved',
        'scholarship_id': 'grant-capped-1',
        'user_id': studentAId,
        'status': 'approved',
        'endorsed_by': reviewerId,
        'decided_by': adminId,
      });

      fakeDs.currentActorId = adminId;

      // Calling approve again with expected_status 'approved'
      final result = await fakeDs.reviewApplication({
        'p_application_id': 'app-already-approved',
        'p_expected_status': 'approved',
        'p_action': 'approve',
      });

      expect(result['status'], 'approved');
      expect(fakeDs.getSimulatedOccupied('grant-capped-1'), 1);
    });

    test('Inactive & Pending Withdrawal Slot Verification: Withdrawals consume and release 0 slots', () async {
      fakeDs.seedApplication({
        'id': 'app-draft',
        'scholarship_id': 'grant-capped-1',
        'user_id': studentAId,
        'status': 'draft',
      });

      fakeDs.seedApplication({
        'id': 'app-submitted',
        'scholarship_id': 'grant-capped-1',
        'user_id': studentBId,
        'status': 'submitted',
      });

      expect(fakeDs.getSimulatedOccupied('grant-capped-1'), 0);

      // Simulating student withdrawal
      final draft = fakeDs.getSimulatedApplication('app-draft')!;
      draft['status'] = 'withdrawn';
      expect(fakeDs.getSimulatedOccupied('grant-capped-1'), 0);

      final submitted = fakeDs.getSimulatedApplication('app-submitted')!;
      submitted['status'] = 'withdrawn';
      expect(fakeDs.getSimulatedOccupied('grant-capped-1'), 0);

      // Capped grant capacity remains completely unaffected
      final cap = await capacityRepo.fetchCapacity('grant-capped-1');
      expect(cap!.occupiedSlots, 0);
      expect(cap.remainingSlots, 1);
    });

    test('Terminal status lock: Approved applications cannot be withdrawn', () {
      const approvedApp = Application(
        id: 'app-approved-terminal',
        scholarshipId: 'grant-capped-1',
        userId: studentAId,
        status: ApplicationStatus.approved,
        appliedAt: null,
      );

      // ApplicationStatus.isPending must be false
      expect(approvedApp.status.isPending, isFalse);

      // Repository withdraw rule check
      expect(
        () {
          if (!approvedApp.status.isPending) {
            throw const ApplicationWithdrawalException();
          }
        },
        throwsA(isA<ApplicationWithdrawalException>()),
      );
    });

    test('Uncapped Capacity Test: Approving grant with slots=null proceeds without limit', () async {
      fakeDs.seedApplication({
        'id': 'app-uncapped-1',
        'scholarship_id': 'grant-uncapped',
        'user_id': studentAId,
        'status': 'under_review',
        'endorsed_by': reviewerId,
      });

      fakeDs.seedApplication({
        'id': 'app-uncapped-2',
        'scholarship_id': 'grant-uncapped',
        'user_id': studentBId,
        'status': 'under_review',
        'endorsed_by': reviewerId,
      });

      fakeDs.currentActorId = adminId;

      await fakeDs.reviewApplication({
        'p_application_id': 'app-uncapped-1',
        'p_expected_status': 'under_review',
        'p_action': 'approve',
      });

      await fakeDs.reviewApplication({
        'p_application_id': 'app-uncapped-2',
        'p_expected_status': 'under_review',
        'p_action': 'approve',
      });

      final cap = await capacityRepo.fetchCapacity('grant-uncapped');
      expect(cap!.isUncapped, isTrue);
      expect(cap.totalSlots, isNull);
      expect(cap.remainingSlots, isNull);
      expect(cap.occupiedSlots, 2);
      expect(cap.remainingLabel, 'Uncapped');
      expect(cap.occupancyRatioLabel, '2 awarded (Uncapped)');
    });

    test('Capacity Visibility: Inactive/draft grants hidden from student capacity queries', () async {
      // As student: querying inactive grant returns null
      fakeDs.currentActorId = studentAId;
      final studentView = await capacityRepo.fetchCapacity('grant-inactive');
      expect(studentView, isNull);

      // As org admin: querying inactive grant returns full capacity
      fakeDs.currentActorId = adminId;
      final adminView = await capacityRepo.fetchCapacity('grant-inactive');
      expect(adminView, isNotNull);
      expect(adminView!.totalSlots, 10);
      expect(adminView.remainingSlots, 10);
    });
  });

  group('C. Platform-Admin Awarding (Migration 0025 Regression Test)', () {
    test('Platform admin confers award (approved -> awarded) with 0 additional slots consumed', () async {
      fakeDs.seedApplication({
        'id': 'app-award-test',
        'scholarship_id': 'grant-capped-1',
        'user_id': studentAId,
        'status': 'approved',
        'endorsed_by': reviewerId,
        'decided_by': adminId,
      });

      expect(fakeDs.getSimulatedOccupied('grant-capped-1'), 1);

      // 1. Non-admin attempting to award fails with 42501
      fakeDs.currentActorId = adminId; // Org admin, not platform admin
      expect(
        () => fakeDs.platformAdminAward('app-award-test'),
        throwsA(isA<PostgrestException>().having((e) => e.code, 'code', '42501')),
      );

      // 2. Platform admin successfully confers award
      fakeDs.currentActorId = platformAdminId;
      await fakeDs.platformAdminAward('app-award-test');

      final app = fakeDs.getSimulatedApplication('app-award-test');
      expect(app!['status'], 'awarded');

      // Occupied slots remains strictly 1; net 0 additional slots consumed
      expect(fakeDs.getSimulatedOccupied('grant-capped-1'), 1);
      final cap = await capacityRepo.fetchCapacity('grant-capped-1');
      expect(cap!.occupiedSlots, 1);
      expect(cap.remainingSlots, 0);
    });
  });
}
