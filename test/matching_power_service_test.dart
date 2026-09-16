// test/matching_power_service_test.dart
//
// Unit tests for MatchingPowerService evaluating completeness percentage,
// checklist items, and dynamic guidance tips.

import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/services/matching_power_service.dart';

void main() {
  group('MatchingPowerService', () {
    test('evaluates null profile gracefully with 0% power', () {
      final report = MatchingPowerService.evaluate(null);

      expect(report.percentage, equals(0));
      expect(report.ratio, equals(0.0));
      expect(report.completedCount, equals(0));
      expect(report.totalCount, equals(8));
      expect(report.isFullyComplete, isFalse);
      expect(report.items.length, equals(8));
      expect(report.advice, contains('Complete your profile setup'));
    });

    test('evaluates partial profile without school and income', () {
      const profile = StudentProfile(
        id: 'std_1',
        fullName: 'Juan Dela Cruz',
        nationality: 'Filipino',
        region: 'NCR',
        gpa: 1.75,
        yearLevel: 3,
        course: 'BS Computer Science',
        setupComplete: true,
      );

      final report = MatchingPowerService.evaluate(profile);

      // Name, nationality, location, course, year level, gpa are complete. School and income are null.
      // 6 complete out of 8 = 75%.
      expect(report.completedCount, equals(6));
      expect(report.totalCount, equals(8));
      expect(report.percentage, equals(75));
      expect(report.isFullyComplete, isFalse);
      expect(report.advice, contains('Add your school & family income'));

      final schoolItem = report.items.firstWhere((i) => i.id == 'school');
      expect(schoolItem.isComplete, isFalse);
      expect(schoolItem.subtitle, equals('Not yet added'));

      final incomeItem = report.items.firstWhere((i) => i.id == 'income');
      expect(incomeItem.isComplete, isFalse);
      expect(incomeItem.subtitle, equals('Not yet specified'));
    });

    test('evaluates profile missing only income', () {
      const profile = StudentProfile(
        id: 'std_2',
        fullName: 'Maria Santos',
        nationality: 'Filipino',
        region: 'Region IV-A',
        gpa: 1.5,
        yearLevel: 2,
        course: 'BS Accountancy',
        school: 'University of the Philippines Diliman',
        gender: 'Female',
        setupComplete: true,
      );

      final report = MatchingPowerService.evaluate(profile);

      expect(report.completedCount, equals(7)); // all except income
      expect(report.totalCount, equals(8));
      expect(report.percentage, equals(88));
      expect(report.advice, contains('Add your family income bracket'));
    });

    test('evaluates fully complete profile at 100%', () {
      const profile = StudentProfile(
        id: 'std_3',
        fullName: 'Jose Rizal',
        nationality: 'Filipino',
        region: 'Region IV-A',
        cityMunicipality: 'Calamba',
        gpa: 1.25,
        yearLevel: 4,
        course: 'BS Biology',
        school: 'Ateneo de Manila University',
        monthlyFamilyIncome: 45000,
        gender: 'Male',
        hasDisability: false,
        isIndigenous: false,
        setupComplete: true,
      );

      final report = MatchingPowerService.evaluate(profile);

      expect(report.completedCount, equals(8));
      expect(report.totalCount, equals(8));
      expect(report.percentage, equals(100));
      expect(report.ratio, equals(1.0));
      expect(report.isFullyComplete, isTrue);
      expect(report.advice, contains('100% complete'));
      expect(report.items.every((i) => i.isComplete), isTrue);

      final incomeItem = report.items.firstWhere((i) => i.id == 'income');
      expect(incomeItem.subtitle, equals('Income details provided'));
      expect(incomeItem.subtitle, isNot(contains('45000')));
    });
  });
}
