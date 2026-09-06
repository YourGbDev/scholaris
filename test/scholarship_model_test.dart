// Tests for the reconciled Scholarship model: snake_case DB row ↔ camelCase
// domain object, and the defaults that make legacy/partial rows parse safely.

import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/scholarships/models/scholarship.dart';

Scholarship _scholarship({DateTime? deadline}) => Scholarship(
      id: 'sch-1',
      title: 'DOST-SEI Undergraduate Scholarship',
      provider: 'Department of Science and Technology',
      description: 'Supports students in priority STEM programs.',
      minGpa: 2.0,
      requiredYearLevels: const [1, 2, 3, 4, 5],
      requiredCourses: const [],
      locationRestriction: 'NCR',
      maxMonthlyIncome: null,
      forPwd: false,
      forIndigenous: false,
      slots: 8000,
      deadline: deadline ?? DateTime(2026, 10, 15),
      isActive: true,
    );

void main() {
  group('Scholarship JSON mapping (snake_case DB ↔ camelCase model)', () {
    test('fromJson parses a snake_case Supabase row', () {
      final row = {
        'id': 'sch-1',
        'title': 'DOST-SEI Undergraduate Scholarship',
        'provider': 'Department of Science and Technology',
        'description': 'Supports students in priority STEM programs.',
        'min_gpa': 2.0,
        'required_year_levels': [1, 2, 3, 4, 5],
        'required_courses': <String>[],
        'location_restriction': 'NCR',
        'max_monthly_income': null,
        'for_pwd': false,
        'for_indigenous': false,
        'slots': 8000,
        'deadline': '2026-10-15',
        'is_active': true,
      };

      final scholarship = Scholarship.fromJson(row);

      expect(scholarship.title, 'DOST-SEI Undergraduate Scholarship');
      expect(scholarship.minGpa, 2.0);
      expect(scholarship.requiredYearLevels, [1, 2, 3, 4, 5]);
      expect(scholarship.locationRestriction, 'NCR');
      expect(scholarship.deadline, DateTime(2026, 10, 15));
      expect(scholarship.slots, 8000);
      expect(scholarship.isActive, isTrue);
    });

    test('fromJson applies defaults for omitted optional columns', () {
      final scholarship = Scholarship.fromJson({
        'id': 'sch-2',
        'title': 'Tulong Dunong Program',
        'min_gpa': 2.0,
        'required_year_levels': [1, 2, 3, 4, 5],
        'required_courses': <String>[],
        'location_restriction': null,
        'deadline': '2026-12-10',
      });

      expect(scholarship.provider, isNull);
      expect(scholarship.maxMonthlyIncome, isNull);
      expect(scholarship.forPwd, isFalse);
      expect(scholarship.forIndigenous, isFalse);
      expect(scholarship.isActive, isTrue);
      expect(scholarship.slots, isNull);
    });

    test('toJson round-trips a full scholarship', () {
      final scholarship = _scholarship(deadline: DateTime(2026, 11, 30));
      final decoded = Scholarship.fromJson(scholarship.toJson());

      expect(decoded, scholarship);
    });

    test('toJson writes snake_case keys', () {
      final json = _scholarship().toJson();

      expect(json.containsKey('min_gpa'), isTrue);
      expect(json.containsKey('required_year_levels'), isTrue);
      expect(json.containsKey('location_restriction'), isTrue);
      expect(json.containsKey('max_monthly_income'), isTrue);
      expect(json.containsKey('for_pwd'), isTrue);
      expect(json.containsKey('for_indigenous'), isTrue);
      expect(json.containsKey('slots'), isTrue);
      // No camelCase keys leak into the payload.
      expect(json.containsKey('minGpa'), isFalse);
      expect(json.containsKey('requiredYearLevels'), isFalse);
      expect(json.containsKey('maxMonthlyIncome'), isFalse);
    });
  });
}
