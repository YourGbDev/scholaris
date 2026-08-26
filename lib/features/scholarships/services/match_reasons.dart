// lib/features/scholarships/services/match_reasons.dart
//
// Produces human-readable reason labels for why a scholarship matched a
// student profile. These are surfaced as chips on the personalized cards.

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

  if (scholarship.yearLevels.contains(student.yearLevel)) {
    reasons.add('Your year level matches');
  }

  if (scholarship.eligibleCourses.isNotEmpty &&
      scholarship.eligibleCourses.contains(student.course)) {
    reasons.add('Your course is eligible');
  } else if (scholarship.eligibleCourses.isEmpty) {
    reasons.add('Open to all courses');
  }

  if (scholarship.regionsEligible.isEmpty ||
      scholarship.regionsEligible.contains(student.region)) {
    reasons.add('Your location is eligible');
  }

  if (scholarship.maxIncomeBracket == 'any' ||
      _incomeBracketIndex(student.incomeBracket) <=
          _incomeBracketIndex(scholarship.maxIncomeBracket)) {
    reasons.add('Your income qualifies');
  }

  if (scholarship.isPwdPriority && student.hasDisability) {
    reasons.add('PWD priority applies');
  }

  if (scholarship.isWorkingStudentPriority) {
    reasons.add('Working students welcome');
  }

  return reasons;
}

int _incomeBracketIndex(String? bracket) {
  switch (bracket) {
    case 'low':
      return 0;
    case 'mid':
      return 1;
    case 'high':
      return 2;
    default:
      return 999;
  }
}