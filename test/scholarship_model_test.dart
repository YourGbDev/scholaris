// Tests for the reconciled Scholarship model: snake_case DB row ↔ camelCase
// domain object, and the defaults that make legacy/partial rows parse safely.

import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/scholarships/models/scholarship.dart';

Scholarship _scholarship({DateTime? deadline}) => Scholarship(
      id: 'sch-1',
      name: 'DOST-SEI Undergraduate Scholarship',
      provider: 'Department of Science and Technology',
      description: 'Supports students in priority STEM programs.',
      minGpa: 2.0,
      yearLevels: const [1, 2, 3, 4, 5],
      eligibleCourses: const [],
      citizenshipRequired: 'Filipino',
      regionsEligible: const ['NCR', 'Region VII'],
      maxIncomeBracket: 'any',
      isPwdPriority: false,
      isWorkingStudentPriority: false,
      slotsAvailable: 8000,
      deadline: deadline ?? DateTime(2026, 10, 15),
      amount: 70000,
      coverageType: 'full',
      tags: const ['stem', 'stipend'],
      isActive: true,
    );

void main() {
  group('Scholarship JSON mapping (snake_case DB ↔ camelCase model)', () {
    test('fromJson parses a snake_case Supabase row', () {
      final row = {
        'id': 'sch-1',
        'name': 'DOST-SEI Undergraduate Scholarship',
        'provider': 'Department of Science and Technology',
        'description': 'Supports students in priority STEM programs.',
        'min_gpa': 2.0,
        'year_levels': [1, 2, 3, 4, 5],
        'eligible_courses': <String>[],
        'citizenship_required': 'Filipino',
        'regions_eligible': ['NCR', 'Region VII'],
        'max_income_bracket': 'any',
        'is_pwd_priority': false,
        'is_working_student_priority': false,
        'slots_available': 8000,
        'deadline': '2026-10-15',
        'amount': 70000,
        'coverage_type': 'full',
        'tags': ['stem', 'stipend'],
        'is_active': true,
      };

      final scholarship = Scholarship.fromJson(row);

      expect(scholarship.name, 'DOST-SEI Undergraduate Scholarship');
      expect(scholarship.minGpa, 2.0);
      expect(scholarship.yearLevels, [1, 2, 3, 4, 5]);
      expect(scholarship.regionsEligible, ['NCR', 'Region VII']);
      expect(scholarship.citizenshipRequired, 'Filipino');
      expect(scholarship.deadline, DateTime(2026, 10, 15));
      expect(scholarship.amount, 70000);
      expect(scholarship.tags, ['stem', 'stipend']);
      expect(scholarship.isActive, isTrue);
    });

    test('fromJson applies defaults for omitted optional columns', () {
      final scholarship = Scholarship.fromJson({
        'id': 'sch-2',
        'name': 'Tulong Dunong Program',
        'min_gpa': 2.0,
        'year_levels': [1, 2, 3, 4, 5],
        'eligible_courses': <String>[],
        'regions_eligible': <String>[],
        'deadline': '2026-12-10',
        'amount': 30000,
      });

      expect(scholarship.citizenshipRequired, 'any');
      expect(scholarship.maxIncomeBracket, 'any');
      expect(scholarship.isPwdPriority, isFalse);
      expect(scholarship.isWorkingStudentPriority, isFalse);
      expect(scholarship.isActive, isTrue);
      expect(scholarship.provider, isNull);
      expect(scholarship.slotsAvailable, isNull);
      expect(scholarship.tags, isEmpty);
    });

    test('toJson round-trips a full scholarship', () {
      final scholarship = _scholarship(deadline: DateTime(2026, 11, 30));
      final decoded = Scholarship.fromJson(scholarship.toJson());

      expect(decoded, scholarship);
    });

    test('toJson writes snake_case keys', () {
      final json = _scholarship().toJson();

      expect(json.containsKey('min_gpa'), isTrue);
      expect(json.containsKey('year_levels'), isTrue);
      expect(json.containsKey('citizenship_required'), isTrue);
      expect(json.containsKey('max_income_bracket'), isTrue);
      expect(json.containsKey('is_pwd_priority'), isTrue);
      expect(json.containsKey('is_working_student_priority'), isTrue);
      // No camelCase keys leak into the payload.
      expect(json.containsKey('minGpa'), isFalse);
      expect(json.containsKey('yearLevels'), isFalse);
      expect(json.containsKey('maxIncomeBracket'), isFalse);
    });
  });
}
