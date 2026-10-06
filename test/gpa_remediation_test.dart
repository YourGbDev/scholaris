import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/profile/models/profile_validator.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/services/matching_engine.dart';

void main() {
  group('GPA Scale Validation & Matching Remediation', () {
    test('ProfileValidator validates Philippine 1.0–5.0 scale', () {
      const validator = ProfileValidator();
      // 1.25 on 5.0 scale passes
      final res1 = validator.validate(
        fullName: 'Juan Dela Cruz',
        nationality: 'Filipino',
        gpa: 1.25,
        yearLevel: 2,
        course: 'BS Computer Science',
        monthlyFamilyIncome: '25000',
        incomeUndisclosed: false,
        region: 'NCR',
        gpaScale: '1.0 – 5.0 (PH Standard)',
      );
      expect(res1.gpa, isNull);

      // 4.5 on 5.0 scale passes
      final res2 = validator.validate(
        fullName: 'Juan Dela Cruz',
        nationality: 'Filipino',
        gpa: 4.5,
        yearLevel: 2,
        course: 'BS Computer Science',
        monthlyFamilyIncome: '25000',
        incomeUndisclosed: false,
        region: 'NCR',
        gpaScale: '1.0 – 5.0',
      );
      expect(res2.gpa, isNull);

      // 5.5 on 5.0 scale fails
      final res3 = validator.validate(
        fullName: 'Juan Dela Cruz',
        nationality: 'Filipino',
        gpa: 5.5,
        yearLevel: 2,
        course: 'BS Computer Science',
        monthlyFamilyIncome: '25000',
        incomeUndisclosed: false,
        region: 'NCR',
        gpaScale: '1.0 – 5.0',
      );
      expect(res3.gpa, contains('between 1.0 and 5.0'));
    });

    test('ProfileValidator validates Percentage scale', () {
      const validator = ProfileValidator();
      // 88.5% passes
      final res1 = validator.validate(
        fullName: 'Maria Santos',
        nationality: 'Filipino',
        gpa: 88.5,
        yearLevel: 3,
        course: 'BS Nursing',
        monthlyFamilyIncome: '30000',
        incomeUndisclosed: false,
        region: 'Region IV-A (CALABARZON)',
        gpaScale: '% Percentage',
      );
      expect(res1.gpa, isNull);

      // 55% fails
      final res2 = validator.validate(
        fullName: 'Maria Santos',
        nationality: 'Filipino',
        gpa: 55.0,
        yearLevel: 3,
        course: 'BS Nursing',
        monthlyFamilyIncome: '30000',
        incomeUndisclosed: false,
        region: 'Region IV-A (CALABARZON)',
        gpaScale: '% Percentage',
      );
      expect(res2.gpa, contains('between 60.0 and 100.0'));
    });

    test('MatchingEngine is scale-aware for Philippine 1.0–5.0 scale', () {
      // Philippine scale: 1.25 is higher honor than 1.75 requirement
      expect(MatchingEngine.isGpaEligible(1.25, 1.75), isTrue);

      // Philippine scale: 2.50 fails 1.75 requirement
      expect(MatchingEngine.isGpaEligible(2.50, 1.75), isFalse);

      // Standard 4.0 scale: 3.50 passes 3.00 requirement
      expect(MatchingEngine.isGpaEligible(3.50, 3.00), isTrue);

      // Standard 4.0 scale: 2.80 fails 3.00 requirement
      expect(MatchingEngine.isGpaEligible(2.80, 3.00), isFalse);

      // Percentage scale: 92% passes 85% requirement
      expect(MatchingEngine.isGpaEligible(92.0, 85.0), isTrue);
    });

    test('MatchingEngine.failedCriteria correctly evaluates Philippine student GPA', () {
      final student = const StudentProfile(
        id: 'student-1',
        fullName: 'Isagani Cruz',
        gpa: 1.25, // High honor in PH
        yearLevel: 2,
        course: 'BS Computer Science',
        region: 'NCR',
        monthlyFamilyIncome: 20000,
      );

      final scholarship = Scholarship(
        id: 'dost-merit',
        title: 'DOST-SEI Merit Scholarship',
        minGpa: 1.75, // PH cutoff
        deadline: DateTime.now().add(const Duration(days: 30)),
        requiredYearLevels: [2],
        requiredCourses: ['BS Computer Science'],
        locationRestriction: 'NCR',
      );

      final failed = MatchingEngine.failedCriteria(student, scholarship);
      expect(failed, isEmpty, reason: '1.25 GWA must meet 1.75 PH cutoff');
    });
  });
}
