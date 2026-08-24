import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/services/matching_engine.dart';

StudentProfile _student({
  double gpa = 3.0,
  int yearLevel = 2,
  String course = 'BS Computer Science',
  String citizenship = 'Filipino',
  String region = 'NCR',
  String incomeBracket = 'low',
}) =>
    StudentProfile(
      id: 's1',
      fullName: 'Test Student',
      email: 'student@example.com',
      yearLevel: yearLevel,
      course: course,
      gpa: gpa,
      citizenship: citizenship,
      region: region,
      province: 'Manila',
      incomeBracket: incomeBracket,
      isWorkingStudent: false,
      isPwd: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Scholarship _scholarship({
  String id = 'sch1',
  String name = 'Scholarship',
  double minGpa = 2.0,
  List<int> yearLevels = const [1, 2, 3, 4],
  List<String> eligibleCourses = const [],
  String citizenshipRequired = 'any',
  List<String> regionsEligible = const [],
  String maxIncomeBracket = 'any',
  bool isActive = true,
  DateTime? deadline,
  double amount = 10000,
}) =>
    Scholarship(
      id: id,
      name: name,
      provider: 'Provider',
      description: 'Description',
      minGpa: minGpa,
      yearLevels: yearLevels,
      eligibleCourses: eligibleCourses,
      citizenshipRequired: citizenshipRequired,
      regionsEligible: regionsEligible,
      maxIncomeBracket: maxIncomeBracket,
      isPwdPriority: false,
      isWorkingStudentPriority: false,
      slotsAvailable: null,
      deadline: deadline ?? DateTime.now().add(const Duration(days: 30)),
      amount: amount,
      coverageType: 'full',
      tags: const [],
      isActive: isActive,
    );

void main() {
  final engine = MatchingEngine();

  group('getEligible', () {
    test('filters by GPA', () {
      final student = _student(gpa: 2.5);
      final eligible = _scholarship(id: 'lowBar', minGpa: 2.0);
      final ineligible = _scholarship(id: 'highBar', minGpa: 3.0);

      final result = engine.getEligible(student, [eligible, ineligible]);

      expect(result.map((s) => s.id), ['lowBar']);
    });

    test('filters by year level', () {
      final student = _student(yearLevel: 4);
      final eligible = _scholarship(id: 'allYears');
      final ineligible = _scholarship(
        id: 'freshmenOnly',
        yearLevels: const [1],
      );

      final result = engine.getEligible(student, [eligible, ineligible]);

      expect(result.map((s) => s.id), ['allYears']);
    });

    test('applies income bracket hierarchy', () {
      final lowOnly = _scholarship(id: 'low', maxIncomeBracket: 'low');
      final midOnly = _scholarship(id: 'mid', maxIncomeBracket: 'mid');
      final highOnly = _scholarship(id: 'high', maxIncomeBracket: 'high');
      final any = _scholarship(id: 'any', maxIncomeBracket: 'any');

      final lowStudent = _student(incomeBracket: 'low');
      final midStudent = _student(incomeBracket: 'mid');
      final highStudent = _student(incomeBracket: 'high');

      final all = [lowOnly, midOnly, highOnly, any];

      expect(
        engine.getEligible(lowStudent, all).map((s) => s.id).toList(),
        ['low', 'mid', 'high', 'any'],
      );
      expect(
        engine.getEligible(midStudent, all).map((s) => s.id).toList(),
        ['mid', 'high', 'any'],
      );
      expect(
        engine.getEligible(highStudent, all).map((s) => s.id).toList(),
        ['high', 'any'],
      );
    });

    test('filters out expired deadlines', () {
      final student = _student();
      final expired = _scholarship(
        id: 'expired',
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      final upcoming = _scholarship(id: 'upcoming');

      final result = engine.getEligible(student, [expired, upcoming]);

      expect(result.map((s) => s.id), ['upcoming']);
    });
  });

  group('rank', () {
    test('sorts by soonest deadline then highest amount', () {
      final student = _student();
      final inTwoWeeks = _scholarship(
        id: 'twoWeeks',
        deadline: DateTime.now().add(const Duration(days: 14)),
        amount: 5000,
      );
      final inOneWeekSmall = _scholarship(
        id: 'oneWeekSmall',
        deadline: DateTime.now().add(const Duration(days: 7)),
        amount: 1000,
      );
      final inOneWeekBig = _scholarship(
        id: 'oneWeekBig',
        deadline: DateTime.now().add(const Duration(days: 7)),
        amount: 9000,
      );

      final result = engine.rank(
        [inTwoWeeks, inOneWeekSmall, inOneWeekBig],
        student,
      );

      expect(result.map((s) => s.id).toList(), [
        'oneWeekBig',
        'oneWeekSmall',
        'twoWeeks',
      ]);
    });
  });
}
