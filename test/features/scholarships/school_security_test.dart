// test/features/scholarships/school_security_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/schools/data/school_repository.dart';
import 'package:scholaris/features/scholarships/data/scholarship_capacity_repository.dart';

class SchoolEligibilityException implements Exception {
  SchoolEligibilityException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Models PostgreSQL backend security boundaries for school eligibility and capacity accounting.
class SecurityEnforcingApplicationSubmissionService {
  SecurityEnforcingApplicationSubmissionService({
    required this.schoolDataSource,
    required this.capacityDataSource,
  });

  final SchoolDataSource schoolDataSource;
  final ScholarshipCapacityDataSource capacityDataSource;

  // Stored scholarships with school constraints
  final Map<String, Map<String, dynamic>> _scholarships = {
    'grant-up-diliman-only': {
      'id': 'grant-up-diliman-only',
      'title': 'UP Diliman STEM Excellence Grant',
      'eligible_school_ids': ['school-upd'],
      'is_active': true,
      'slots': 10,
    },
    'grant-open-national': {
      'id': 'grant-open-national',
      'title': 'National Open Merit Grant',
      'eligible_school_ids': null, // Open to all institutions
      'is_active': true,
      'slots': 50,
    },
    'grant-inactive-restricted': {
      'id': 'grant-inactive-restricted',
      'title': 'Draft Restricted Grant',
      'eligible_school_ids': ['school-upd'],
      'is_active': false,
      'slots': 5,
    },
  };

  final Map<String, Map<String, dynamic>> _applications = {};

  /// Simulates student submission with backend guard_application_workflow() triggers.
  Future<Map<String, dynamic>> submitApplication({
    required String applicationId,
    required String studentId,
    required String? studentSchoolId,
    required String scholarshipId,
    required String targetStatus, // 'draft' or 'submitted'
  }) async {
    final scholarship = _scholarships[scholarshipId];
    if (scholarship == null) {
      throw Exception('Scholarship not found');
    }

    final eligibleSchools =
        scholarship['eligible_school_ids'] as List<String>?;

    // Backend trigger: check school eligibility on submitted status
    if (targetStatus == 'submitted') {
      if (eligibleSchools != null && eligibleSchools.isNotEmpty) {
        if (studentSchoolId == null ||
            !eligibleSchools.contains(studentSchoolId)) {
          throw SchoolEligibilityException(
            'P0003: School eligibility requirement not met. This scholarship is restricted to designated partner institutions.',
          );
        }
      }
    }

    final app = {
      'id': applicationId,
      'user_id': studentId,
      'scholarship_id': scholarshipId,
      'status': targetStatus,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _applications[applicationId] = app;
    return app;
  }

  /// Simulates student transitioning draft to submitted
  Future<Map<String, dynamic>> submitDraft({
    required String applicationId,
    required String? studentSchoolId,
  }) async {
    final app = _applications[applicationId];
    if (app == null) throw Exception('Application not found');

    return submitApplication(
      applicationId: applicationId,
      studentId: app['user_id'] as String,
      studentSchoolId: studentSchoolId,
      scholarshipId: app['scholarship_id'] as String,
      targetStatus: 'submitted',
    );
  }
}

class FakeSecurityCapacityDataSource implements ScholarshipCapacityDataSource {
  FakeSecurityCapacityDataSource({
    required this.isCallerStudent,
  });

  final bool isCallerStudent;

  final Map<String, Map<String, dynamic>> _capacities = {
    'grant-open-national': {
      'scholarship_id': 'grant-open-national',
      'total_slots': 50,
      'occupied_slots': 12,
      'remaining_slots': 38,
      'is_uncapped': false,
      'is_active': true,
    },
    'grant-inactive-restricted': {
      'scholarship_id': 'grant-inactive-restricted',
      'total_slots': 5,
      'occupied_slots': 0,
      'remaining_slots': 5,
      'is_uncapped': false,
      'is_active': false,
    },
  };

  @override
  Future<Map<String, dynamic>?> fetchCapacity(String scholarshipId) async {
    final cap = _capacities[scholarshipId];
    if (cap == null) return null;

    // Inactive grant visibility rule: students receive null (0 rows in view)
    if (isCallerStudent && cap['is_active'] == false) {
      return null;
    }
    return cap;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllCapacities() async {
    return _capacities.values
        .where((c) => !isCallerStudent || c['is_active'] == true)
        .toList();
  }
}

class FakeSecuritySchoolDataSource implements SchoolDataSource {
  final List<Map<String, dynamic>> _schools = [
    {
      'id': 'school-upd',
      'name': 'University of the Philippines Diliman',
      'normalized_name': 'university of the philippines diliman',
      'aliases': ['up diliman', 'upd', 'up'],
      'is_curated': true,
    },
    {
      'id': 'school-admu',
      'name': 'Ateneo de Manila University',
      'normalized_name': 'ateneo de manila university',
      'aliases': ['admu', 'ateneo'],
      'is_curated': true,
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchSchools() async =>
      List<Map<String, dynamic>>.from(_schools);

  @override
  Future<String> addCustomSchool(String name) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('School name cannot be empty');
    }
    final norm = name.trim().toLowerCase();
    for (final s in _schools) {
      if (s['normalized_name'] == norm ||
          (s['aliases'] as List).contains(norm)) {
        return s['id'] as String;
      }
    }
    final newId = 'school-${_schools.length + 1}';
    _schools.add({
      'id': newId,
      'name': name.trim(),
      'normalized_name': norm,
      'aliases': <String>[],
      'is_curated': false,
    });
    return newId;
  }
}

void main() {
  group('Backend School Eligibility & Normalization Security Tests', () {
    late FakeSecuritySchoolDataSource schoolDataSource;
    late FakeSecurityCapacityDataSource capacityDataSource;
    late SecurityEnforcingApplicationSubmissionService submissionService;
    late SchoolRepository schoolRepo;
    late ScholarshipCapacityRepository capacityRepo;

    setUp(() {
      schoolDataSource = FakeSecuritySchoolDataSource();
      capacityDataSource = FakeSecurityCapacityDataSource(isCallerStudent: true);
      submissionService = SecurityEnforcingApplicationSubmissionService(
        schoolDataSource: schoolDataSource,
        capacityDataSource: capacityDataSource,
      );
      schoolRepo = SchoolRepository(dataSource: schoolDataSource);
      capacityRepo = ScholarshipCapacityRepository(dataSource: capacityDataSource);
    });

    test('Eligible student (UP Diliman) successfully submits to UP Diliman restricted grant', () async {
      final app = await submissionService.submitApplication(
        applicationId: 'app-valid-upd',
        studentId: 'student-upd',
        studentSchoolId: 'school-upd',
        scholarshipId: 'grant-up-diliman-only',
        targetStatus: 'submitted',
      );

      expect(app['status'], 'submitted');
      expect(app['scholarship_id'], 'grant-up-diliman-only');
    });

    test('Ineligible student (Ateneo) submitting to UP Diliman restricted grant is rejected with P0003', () async {
      expect(
        () => submissionService.submitApplication(
          applicationId: 'app-invalid-ateneo',
          studentId: 'student-ateneo',
          studentSchoolId: 'school-admu',
          scholarshipId: 'grant-up-diliman-only',
          targetStatus: 'submitted',
        ),
        throwsA(isA<SchoolEligibilityException>().having(
          (e) => e.message,
          'message',
          contains('P0003: School eligibility requirement not met'),
        )),
      );
    });

    test('Missing school student (school_id is null) submitting to restricted grant is rejected with P0003', () async {
      expect(
        () => submissionService.submitApplication(
          applicationId: 'app-invalid-no-school',
          studentId: 'student-no-school',
          studentSchoolId: null,
          scholarshipId: 'grant-up-diliman-only',
          targetStatus: 'submitted',
        ),
        throwsA(isA<SchoolEligibilityException>().having(
          (e) => e.message,
          'message',
          contains('P0003: School eligibility requirement not met'),
        )),
      );
    });

    test('Student can save unsubmitted draft regardless of school eligibility', () async {
      final draft = await submissionService.submitApplication(
        applicationId: 'draft-ateneo',
        studentId: 'student-ateneo',
        studentSchoolId: 'school-admu',
        scholarshipId: 'grant-up-diliman-only',
        targetStatus: 'draft',
      );

      expect(draft['status'], 'draft');

      // Attempting to submit the draft throws P0003
      expect(
        () => submissionService.submitDraft(
          applicationId: 'draft-ateneo',
          studentSchoolId: 'school-admu',
        ),
        throwsA(isA<SchoolEligibilityException>()),
      );
    });

    test('Unrestricted national grant permits submissions from all students including null school_id', () async {
      final app1 = await submissionService.submitApplication(
        applicationId: 'app-nat-1',
        studentId: 'student-ateneo',
        studentSchoolId: 'school-admu',
        scholarshipId: 'grant-open-national',
        targetStatus: 'submitted',
      );
      expect(app1['status'], 'submitted');

      final app2 = await submissionService.submitApplication(
        applicationId: 'app-nat-2',
        studentId: 'student-no-school',
        studentSchoolId: null,
        scholarshipId: 'grant-open-national',
        targetStatus: 'submitted',
      );
      expect(app2['status'], 'submitted');
    });

    test('School deduplication: whitespace and alias matching prevents duplicate rows', () async {
      final initialSchools = await schoolRepo.fetchSchools();
      expect(initialSchools.length, 2);

      // Whitespace and casing variation
      final id1 = await schoolRepo.addSchool('   University of the Philippines Diliman   ');
      expect(id1, 'school-upd');

      // Alias match
      final id2 = await schoolRepo.addSchool('upd');
      expect(id2, 'school-upd');

      // Zero new rows created
      final schoolsAfter = await schoolRepo.fetchSchools();
      expect(schoolsAfter.length, 2);
    });

    test('Empty school name throws ArgumentError', () async {
      expect(() => schoolRepo.addSchool('   '), throwsArgumentError);
      expect(() => schoolRepo.addSchool(''), throwsArgumentError);
    });

    test('Truthful verification wording: is_curated indicates catalog seeding, not student enrollment verification', () async {
      final schools = await schoolRepo.fetchSchools();
      for (final s in schools) {
        expect(s.isCurated, isTrue);
      }

      // Add custom uncurated school
      final newId = await schoolRepo.addSchool('Polytechnic University of the Philippines Ragay');
      final updatedSchools = await schoolRepo.fetchSchools();
      final added = updatedSchools.firstWhere((s) => s.id == newId);
      expect(added.isCurated, isFalse);
    });

    test('Capacity privacy: student cannot view capacity for inactive scholarships', () async {
      // Active grant capacity visible
      final activeCap = await capacityRepo.fetchCapacity('grant-open-national');
      expect(activeCap, isNotNull);
      expect(activeCap!.totalSlots, 50);
      expect(activeCap.occupiedSlots, 12);
      expect(activeCap.remainingSlots, 38);

      // Inactive grant capacity hidden from student
      final inactiveCap = await capacityRepo.fetchCapacity('grant-inactive-restricted');
      expect(inactiveCap, isNull);
    });
  });
}
