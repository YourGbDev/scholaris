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
    if (!isGpaEligible(student.gpa, scholarship.minGpa)) {
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

  /// Scale-aware GPA evaluation supporting Philippine standard 1.0–5.0 scale
  /// (where cutoffs <= 1.75 denote Philippine honors where 1.0 is highest honor
  /// and lower numeric values indicate higher standing) as well as standard 4.0
  /// and percentage scales (where higher values indicate higher standing).
  static bool isGpaEligible(double studentGpa, double minGpa) {
    if (studentGpa <= 0) return false;
    // Philippine honors cutoff (e.g. 1.75 Dean's List, 1.5 Magna, 1.25 Summa):
    // In the Philippine grading system, 1.0 is the highest mark, so lower numeric
    // values denote higher academic standing.
    if (minGpa > 0 && minGpa <= 1.75) {
      return studentGpa <= minGpa;
    }
    // Standard 4.0 scale (e.g. minGpa 2.0, 3.0, 3.5) or percentage scale (e.g. 85.0):
    // Higher numeric values denote higher standing.
    return studentGpa >= minGpa;
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
