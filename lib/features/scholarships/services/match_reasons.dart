import '../../profile/models/student_profile.dart';
import '../models/scholarship.dart';

/// Returns a list of short reason labels explaining why [scholarship] is
/// eligible for [student]. Each label is at most ~25 characters and is derived
/// only from the same criteria the matching engine applies, so a reason can
/// never claim something the data does not support.
List<String> matchReasonsFor(StudentProfile student, Scholarship scholarship) {
  final reasons = <String>[];

  if (student.gpa >= scholarship.minGpa) {
    reasons.add('Your GPA qualifies');
  }

  if (scholarship.requiredYearLevels == null ||
      scholarship.requiredYearLevels!.isEmpty ||
      scholarship.requiredYearLevels!.contains(student.yearLevel)) {
    reasons.add('Your year level matches');
  }

  if (scholarship.requiredCourses == null ||
      scholarship.requiredCourses!.isEmpty ||
      scholarship.requiredCourses!.contains(student.course)) {
    reasons.add('Your course is eligible');
  }

  if (scholarship.locationRestriction == null ||
      scholarship.locationRestriction == student.region) {
    reasons.add('Your location is eligible');
  }

  final income = student.monthlyFamilyIncome;
  final limit = scholarship.maxMonthlyIncome;
  if (limit == null) {
    reasons.add('Your income qualifies');
  } else if (income != null && income <= limit) {
    reasons.add('Your income qualifies');
  }

  if (scholarship.forPwd == true && student.hasDisability) {
    reasons.add('PWD priority applies');
  }

  if (scholarship.forIndigenous == true && student.isIndigenous) {
    reasons.add('Indigenous priority applies');
  }

  return reasons;
}
