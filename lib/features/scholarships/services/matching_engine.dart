import '../models/scholarship.dart';
import '../../profile/models/student_profile.dart';

class MatchingEngine {
  List<Scholarship> getEligible(
    StudentProfile student,
    List<Scholarship> all,
  ) {
    final now = DateTime.now();
    return all.where((s) {
      if (student.gpa < s.minGpa) {
        return false;
      }
      if (!s.yearLevels.contains(student.yearLevel)) {
        return false;
      }
      if (s.eligibleCourses.isNotEmpty &&
          !s.eligibleCourses.contains(student.course)) {
        return false;
      }
      if (s.citizenshipRequired != 'any' &&
          s.citizenshipRequired != student.nationality) {
        return false;
      }
      if (s.regionsEligible.isNotEmpty &&
          !s.regionsEligible.contains(student.region)) {
        return false;
      }
      if (!_incomeBracketAllows(student.incomeBracket, s.maxIncomeBracket)) {
        return false;
      }
      if (!s.isActive) {
        return false;
      }
      if (!s.deadline.isAfter(now)) {
        return false;
      }
      return true;
    }).toList();
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

  bool _incomeBracketAllows(String? studentBracket, String scholarshipMax) {
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
