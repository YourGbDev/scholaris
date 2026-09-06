import '../models/scholarship.dart';
import '../../profile/models/student_profile.dart';

/// The profile-vs-scholarship eligibility criteria the engine applies, in its
/// canonical evaluation order. Exposed so other consumers (e.g. the application
/// readiness service) can explain outcomes without re-implementing — and
/// potentially diverging from — the engine's semantics.
enum EligibilityCriterion { gpa, yearLevel, course, region, income, pwd, indigenous }

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
    if (scholarship.requiredYearLevels != null &&
        !scholarship.requiredYearLevels!.contains(student.yearLevel)) {
      failed.add(EligibilityCriterion.yearLevel);
    }
    if (scholarship.requiredCourses != null &&
        scholarship.requiredCourses!.isNotEmpty &&
        !scholarship.requiredCourses!.contains(student.course)) {
      failed.add(EligibilityCriterion.course);
    }
    if (scholarship.locationRestriction != null &&
        scholarship.locationRestriction != student.region) {
      failed.add(EligibilityCriterion.region);
    }
    final income = student.monthlyFamilyIncome;
    final limit = scholarship.maxMonthlyIncome;
    if (limit != null && (income == null || income > limit)) {
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
      return 0;
    });
    return ranked;
  }
}
