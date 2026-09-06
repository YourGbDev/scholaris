import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/services/matching_engine.dart';

StudentProfile _student({
  double gpa = 3.0,
  int yearLevel = 2,
  String course = 'BS Computer Science',
  String nationality = 'Filipino',
  String region = 'NCR',
  double? monthlyFamilyIncome = 15000,
  bool hasDisability = false,
  bool isIndigenous = false,
}) =>
    StudentProfile(
      id: 's1',
      fullName: 'Test Student',
      nationality: nationality,
      region: region,
      province: 'Manila',
      gpa: gpa,
      yearLevel: yearLevel,
      course: course,
      school: 'WLC',
      monthlyFamilyIncome: monthlyFamilyIncome,
      hasDisability: hasDisability,
      isIndigenous: isIndigenous,
      setupComplete: true,
    );

Scholarship _scholarship({
  String id = 'sch1',
  String title = 'Scholarship',
  double minGpa = 2.0,
  List<int>? requiredYearLevels = const [1, 2, 3, 4],
  List<String>? requiredCourses = const [],
  String? locationRestriction,
  double? maxMonthlyIncome,
  bool forPwd = false,
  bool forIndigenous = false,
  int? slots,
  bool isActive = true,
  DateTime? deadline,
}) =>
    Scholarship(
      id: id,
      title: title,
      provider: 'Provider',
      description: 'Description',
      minGpa: minGpa,
      requiredYearLevels: requiredYearLevels,
      requiredCourses: requiredCourses,
      locationRestriction: locationRestriction,
      maxMonthlyIncome: maxMonthlyIncome,
      forPwd: forPwd,
      forIndigenous: forIndigenous,
      slots: slots,
      deadline: deadline ?? DateTime.now().add(const Duration(days: 30)),
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
        requiredYearLevels: const [1],
      );

      final result = engine.getEligible(student, [eligible, ineligible]);

      expect(result.map((s) => s.id), ['allYears']);
    });

    test('filters by course', () {
      final student = _student(course: 'BS Nursing');
      final eligible = _scholarship(id: 'allCourses');
      final ineligible = _scholarship(
        id: 'stemOnly',
        requiredCourses: const ['BS Computer Science', 'BS Engineering'],
      );

      final result = engine.getEligible(student, [eligible, ineligible]);

      expect(result.map((s) => s.id), ['allCourses']);
    });

    test('filters by location restriction', () {
      final student = _student(region: 'Region VII');
      final eligible = _scholarship(id: 'noRestriction');
      final ineligible = _scholarship(
        id: 'ncrOnly',
        locationRestriction: 'NCR',
      );
      final matches = _scholarship(
        id: 'visayas',
        locationRestriction: 'Region VII',
      );

      final result = engine.getEligible(student, [eligible, ineligible, matches]);

      expect(result.map((s) => s.id), ['noRestriction', 'visayas']);
    });

    test('applies income threshold hierarchy derived from income', () {
      final lowOnly = _scholarship(id: 'low', maxMonthlyIncome: 20000);
      final midOnly = _scholarship(id: 'mid', maxMonthlyIncome: 50000);
      final highOnly = _scholarship(id: 'high', maxMonthlyIncome: 100000);
      final any = _scholarship(id: 'any', maxMonthlyIncome: null);

      final lowStudent = _student(monthlyFamilyIncome: 10000); // low
      final midStudent = _student(monthlyFamilyIncome: 40000); // mid
      final highStudent = _student(monthlyFamilyIncome: 90000); // high

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

    test('undisclosed income never matches income-constrained scholarships', () {
      final lowOnly = _scholarship(id: 'low', maxMonthlyIncome: 15000);
      final any = _scholarship(id: 'any', maxMonthlyIncome: null);

      final undisclosed = _student(monthlyFamilyIncome: null);

      final result = engine.getEligible(undisclosed, [lowOnly, any]);

      expect(result.map((s) => s.id), ['any']);
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
    test('sorts by soonest deadline', () {
      final student = _student();
      final base = DateTime.now();
      final inTwoWeeks = _scholarship(
        id: 'twoWeeks',
        deadline: base.add(const Duration(days: 14)),
      );
      final inOneWeekSmall = _scholarship(
        id: 'oneWeekSmall',
        deadline: base.add(const Duration(days: 7)),
      );
      final inOneWeekBig = _scholarship(
        id: 'oneWeekBig',
        deadline: base.add(const Duration(days: 7)),
      );

      final result = engine.rank(
        [inTwoWeeks, inOneWeekSmall, inOneWeekBig],
        student,
      );

      expect(result.map((s) => s.id).toList(), [
        'oneWeekSmall',
        'oneWeekBig',
        'twoWeeks',
      ]);
    });
  });
}
