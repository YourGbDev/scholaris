// Unit tests for the Day 15 application-readiness service. Pure, deterministic
// evaluation: every test uses a fixed reference time so nothing depends on the
// wall clock. Also guards the single-source-of-truth contract between the
// readiness evaluation and the MatchingEngine.

import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/services/application_readiness.dart';
import 'package:scholaris/features/scholarships/services/matching_engine.dart';

/// Fixed reference time: noon on 2026-09-02. Day-granular deadlines are
/// anchored to it so deadline math never depends on today's date.
final _now = DateTime(2026, 9, 2, 12);

StudentProfile _student({
  double gpa = 3.2,
  int yearLevel = 2,
  String course = 'BS Computer Science',
  String nationality = 'Filipino',
  String region = 'NCR',
  double? monthlyFamilyIncome = 15000,
  bool setupComplete = true,
}) =>
    StudentProfile(
      id: 'user-a',
      fullName: 'Maria Santos',
      nationality: nationality,
      region: region,
      gpa: gpa,
      yearLevel: yearLevel,
      course: course,
      monthlyFamilyIncome: monthlyFamilyIncome,
      setupComplete: setupComplete,
    );

Scholarship _scholarship({
  String id = 'sch-1',
  double minGpa = 2.0,
  List<int> yearLevels = const [1, 2, 3, 4, 5],
  List<String> eligibleCourses = const [],
  String citizenshipRequired = 'any',
  List<String> regionsEligible = const [],
  String maxIncomeBracket = 'any',
  bool isActive = true,
  DateTime? deadline,
}) =>
    Scholarship(
      id: id,
      name: 'Test Scholarship',
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
      deadline: deadline ?? DateTime(2026, 10, 15, 23, 59),
      amount: 50000,
      coverageType: 'full',
      tags: const [],
      isActive: isActive,
    );

void main() {
  group('scholarship state', () {
    test('active + future deadline is eligible for a qualifying profile', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: _scholarship(),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.eligible);
      expect(readiness.canApply, isTrue);
      expect(readiness.missingCriteria, isEmpty);
      expect(readiness.reasons, isEmpty);
    });

    test('active + expired deadline is closed', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: _scholarship(deadline: DateTime(2026, 9, 1, 23, 59)),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.closed);
      expect(readiness.canApply, isFalse);
    });

    test('inactive + future deadline is inactive (not eligible, not closed)',
        () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: _scholarship(isActive: false),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.inactive);
      expect(readiness.canApply, isFalse);
    });

    test('inactive + expired deadline is inactive — inactivity wins', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: _scholarship(
          isActive: false,
          deadline: DateTime(2026, 9, 1, 23, 59),
        ),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.inactive);
      expect(readiness.canApply, isFalse);
    });

    test('deadline exactly equal to the reference time is closed', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: _scholarship(deadline: _now),
        referenceNow: _now,
      );

      // Mirrors MatchingEngine's `deadline.isAfter(now)` semantics.
      expect(readiness.state, ApplicationReadinessState.closed);
    });

    test('deadline later the same calendar day is still open', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: _scholarship(deadline: DateTime(2026, 9, 2, 23, 59)),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.eligible);
    });
  });

  group('profile state', () {
    test('no profile is profileIncomplete — not an eligibility verdict', () {
      final readiness = evaluateApplicationReadiness(
        profile: null,
        scholarship: _scholarship(minGpa: 3.5),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.profileIncomplete);
      expect(readiness.canApply, isFalse);
      expect(readiness.missingCriteria, isEmpty);
      expect(readiness.reasons, isEmpty);
    });

    test('profile that has not completed setup is profileIncomplete', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(setupComplete: false, gpa: 1.0),
        scholarship: _scholarship(minGpa: 3.5),
        referenceNow: _now,
      );

      // Even a profile whose values would fail is reported as incomplete —
      // the `setup_complete` flag is the app's single completeness definition.
      expect(readiness.state, ApplicationReadinessState.profileIncomplete);
      expect(readiness.canApply, isFalse);
    });

    test('complete eligible profile is eligible', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: _scholarship(),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.eligible);
      expect(readiness.canApply, isTrue);
    });

    test('complete ineligible profile is notEligible with reasons', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(gpa: 2.0),
        scholarship: _scholarship(minGpa: 3.5),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.notEligible);
      expect(readiness.canApply, isFalse);
      expect(readiness.missingCriteria, [EligibilityCriterion.gpa]);
      expect(readiness.reasons, hasLength(1));
    });
  });

  group('eligibility criteria (each mirrors the MatchingEngine)', () {
    test('GPA failure reports the requirement and the actual value', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(gpa: 3.2),
        scholarship: _scholarship(minGpa: 3.5),
        referenceNow: _now,
      );

      expect(readiness.missingCriteria, [EligibilityCriterion.gpa]);
      expect(readiness.reasons.single, contains('Minimum GPA 3.50'));
      expect(readiness.reasons.single, contains('your GPA is 3.20'));
    });

    test('GPA boundary: equal to the minimum passes', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(gpa: 3.5),
        scholarship: _scholarship(minGpa: 3.5),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.eligible);
    });

    test('year-level failure reports the open years and the actual year', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(yearLevel: 5),
        scholarship: _scholarship(yearLevels: [1, 2, 3]),
        referenceNow: _now,
      );

      expect(readiness.missingCriteria, [EligibilityCriterion.yearLevel]);
      expect(readiness.reasons.single, contains('year 1, 2, 3'));
      expect(readiness.reasons.single, contains('you are in year 5'));
    });

    test('course failure names the ineligible course', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(course: 'BS Nursing'),
        scholarship: _scholarship(
          eligibleCourses: ['BS Computer Science', 'BS Engineering'],
        ),
        referenceNow: _now,
      );

      expect(readiness.missingCriteria, [EligibilityCriterion.course]);
      expect(readiness.reasons.single, contains('BS Nursing'));
    });

    test('open course list never fails the course criterion', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(course: 'BS Nursing'),
        scholarship: _scholarship(eligibleCourses: []),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.eligible);
    });

    test('citizenship failure reports requirement and actual nationality', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(nationality: 'Canadian'),
        scholarship: _scholarship(citizenshipRequired: 'Filipino'),
        referenceNow: _now,
      );

      expect(readiness.missingCriteria, [EligibilityCriterion.citizenship]);
      expect(readiness.reasons.single, contains('Filipino'));
      expect(readiness.reasons.single, contains('Canadian'));
    });

    test('region failure reports the open regions and the actual region', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(region: 'Region VII'),
        scholarship: _scholarship(regionsEligible: ['NCR', 'Region IV-A (CALABARZON)']),
        referenceNow: _now,
      );

      expect(readiness.missingCriteria, [EligibilityCriterion.region]);
      expect(readiness.reasons.single, contains('NCR'));
      expect(readiness.reasons.single, contains('Region VII'));
    });

    test('open region list never fails the region criterion', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(region: 'Region VII'),
        scholarship: _scholarship(regionsEligible: []),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.eligible);
    });

    test('income failure reports the bracket comparison', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(monthlyFamilyIncome: 90000), // high
        scholarship: _scholarship(maxIncomeBracket: 'low'),
        referenceNow: _now,
      );

      expect(readiness.missingCriteria, [EligibilityCriterion.income]);
      expect(readiness.reasons.single, contains('high'));
      expect(readiness.reasons.single, contains('low'));
    });

    test('undisclosed income fails income-constrained scholarships', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(monthlyFamilyIncome: null),
        scholarship: _scholarship(maxIncomeBracket: 'low'),
        referenceNow: _now,
      );

      expect(readiness.missingCriteria, [EligibilityCriterion.income]);
      expect(readiness.reasons.single, contains('undisclosed'));
    });

    test('undisclosed income passes income-unconstrained scholarships', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(monthlyFamilyIncome: null),
        scholarship: _scholarship(maxIncomeBracket: 'any'),
        referenceNow: _now,
      );

      expect(readiness.state, ApplicationReadinessState.eligible);
    });

    test('multiple failures are reported in engine order', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(
          gpa: 2.0,
          yearLevel: 5,
          region: 'Region VII',
          monthlyFamilyIncome: 90000,
        ),
        scholarship: _scholarship(
          minGpa: 3.5,
          yearLevels: [1, 2],
          regionsEligible: ['NCR'],
          maxIncomeBracket: 'low',
        ),
        referenceNow: _now,
      );

      expect(
        readiness.missingCriteria,
        [
          EligibilityCriterion.gpa,
          EligibilityCriterion.yearLevel,
          EligibilityCriterion.region,
          EligibilityCriterion.income,
        ],
      );
      expect(readiness.reasons, hasLength(4));
    });

    test('priority flags are never eligibility criteria', () {
      final readiness = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: _scholarship(),
        referenceNow: _now,
      );

      // Eligible with no priority flags set on the profile: PWD/working-student
      // priorities are not hard requirements in the MatchingEngine.
      expect(readiness.state, ApplicationReadinessState.eligible);
    });
  });

  group('reference time behavior', () {
    test('the same inputs are deterministic', () {
      final scholarship = _scholarship(minGpa: 3.5);

      final first = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: scholarship,
        referenceNow: _now,
      );
      final second = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: scholarship,
        referenceNow: _now,
      );

      expect(first.state, second.state);
      expect(first.missingCriteria, second.missingCriteria);
      expect(first.reasons, second.reasons);
    });

    test('a future deadline becomes closed as the reference time advances',
        () {
      final scholarship = _scholarship(deadline: DateTime(2026, 10, 15, 23, 59));

      final before = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: scholarship,
        referenceNow: _now,
      );
      final after = evaluateApplicationReadiness(
        profile: _student(),
        scholarship: scholarship,
        referenceNow: DateTime(2026, 10, 16, 12),
      );

      expect(before.state, ApplicationReadinessState.eligible);
      expect(after.state, ApplicationReadinessState.closed);
    });
  });

  group('single source of truth (readiness ↔ MatchingEngine)', () {
    test('verdicts agree with the engine for eligible and ineligible profiles',
        () {
      final engine = MatchingEngine();
      final scholarship = _scholarship(minGpa: 3.0);
      final student = _student(gpa: 3.2);

      final readiness = evaluateApplicationReadiness(
        profile: student,
        scholarship: scholarship,
        referenceNow: _now,
      );
      final engineEligible =
          engine.getEligible(student, [scholarship]).isNotEmpty;

      expect(readiness.state, ApplicationReadinessState.eligible);
      expect(engineEligible, isTrue);
    });

    test('every engine-rejected profile yields notEligible with the same '
        'failed criteria', () {
      final engine = MatchingEngine();
      final scholarship = _scholarship(
        minGpa: 3.5,
        eligibleCourses: ['BS Computer Science'],
        regionsEligible: ['NCR'],
        maxIncomeBracket: 'low',
      );
      final student = _student(
        gpa: 3.2,
        course: 'BS Nursing',
        region: 'Region VII',
        monthlyFamilyIncome: 90000,
      );

      final readiness = evaluateApplicationReadiness(
        profile: student,
        scholarship: scholarship,
        referenceNow: _now,
      );
      final engineEligible =
          engine.getEligible(student, [scholarship]).isNotEmpty;

      expect(engineEligible, isFalse);
      expect(readiness.state, ApplicationReadinessState.notEligible);
      expect(
        readiness.missingCriteria,
        MatchingEngine.failedCriteria(student, scholarship),
      );
      expect(
        readiness.missingCriteria,
        [
          EligibilityCriterion.gpa,
          EligibilityCriterion.course,
          EligibilityCriterion.region,
          EligibilityCriterion.income,
        ],
      );
    });

    test('active + open + engine-eligible ⇔ readiness eligible', () {
      final engine = MatchingEngine();
      final scholarship = _scholarship(
        minGpa: 2.0,
        yearLevels: [2],
        eligibleCourses: ['BS Computer Science'],
        citizenshipRequired: 'Filipino',
        regionsEligible: ['NCR'],
        maxIncomeBracket: 'mid',
      );
      final student = _student();

      final readiness = evaluateApplicationReadiness(
        profile: student,
        scholarship: scholarship,
        referenceNow: _now,
      );
      final engineEligible =
          engine.getEligible(student, [scholarship]).isNotEmpty;

      expect(readiness.canApply, engineEligible);
    });
  });
}
