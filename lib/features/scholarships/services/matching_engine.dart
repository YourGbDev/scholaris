import '../models/scholarship.dart';
import '../../profile/models/student_profile.dart';

/// The profile-vs-scholarship eligibility criteria the engine applies, in its
/// canonical evaluation order. Exposed so other consumers (e.g. the application
/// readiness service) can explain outcomes without re-implementing — and
/// potentially diverging from — the engine's semantics.
enum EligibilityCriterion { gpa, yearLevel, course, citizenship, region, income }

class MatchingEngine {
  List<Scholarship> getEligible(
    StudentProfile student,
    List<Scholarship> all,
  ) {
    final now = DateTime.now();
    return all.where((s) {
      if (!s.isActive) {
        return false;
      }
      if (!s.deadline.isAfter(now)) {
        return false;
      }
      return failedCriteria(student, s).isEmpty;
    }).toList();
  }

  /// The eligibility criteria [student] fails for [scholarship], in canonical
  /// order; empty when the student qualifies. This is the single definition of
  /// profile-based eligibility — [getEligible] and the readiness service both
  /// derive their verdicts from it.
  static List<EligibilityCriterion> failedCriteria(
    StudentProfile student,
    Scholarship scholarship,
  ) {
    final failed = <EligibilityCriterion>[];
    if (student.gpa < scholarship.minGpa) {
      failed.add(EligibilityCriterion.gpa);
    }
    if (!scholarship.yearLevels.contains(student.yearLevel)) {
      failed.add(EligibilityCriterion.yearLevel);
    }
    if (scholarship.eligibleCourses.isNotEmpty &&
        !scholarship.eligibleCourses.contains(student.course)) {
      failed.add(EligibilityCriterion.course);
    }
    if (scholarship.citizenshipRequired != 'any' &&
        scholarship.citizenshipRequired != student.nationality) {
      failed.add(EligibilityCriterion.citizenship);
    }
    if (scholarship.regionsEligible.isNotEmpty &&
        !scholarship.regionsEligible.contains(student.region)) {
      failed.add(EligibilityCriterion.region);
    }
    if (!_incomeBracketAllows(student.incomeBracket, scholarship.maxIncomeBracket)) {
      failed.add(EligibilityCriterion.income);
    }
    return failed;
  }

  List<Scholarship> rank(
    List<Scholarship> eligible,
    StudentProfile student,
  ) {
    final ranked = List<Scholarship>.of(eligible);
    ranked.sort((a, b) {
      final deadlineCmp = a.deadline.compareTo(b.deadline);
      if (deadlineCmp != 0) return deadlineCmp;
      return b.amount.compareTo(a.amount);
    });
    return ranked;
  }

  static bool _incomeBracketAllows(String? studentBracket, String scholarshipMax) {
    if (scholarshipMax == 'any') return true;
    // An undisclosed income cannot be compared against a scholarship's income
    // ceiling, so income-constrained scholarships simply do not match.
    if (studentBracket == null) return false;
    const hierarchy = ['low', 'mid', 'high'];
    final studentIndex = hierarchy.indexOf(studentBracket);
    final maxIndex = hierarchy.indexOf(scholarshipMax);
    if (studentIndex == -1 || maxIndex == -1) return false;
    return studentIndex <= maxIndex;
  }
}
