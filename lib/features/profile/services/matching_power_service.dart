// lib/features/profile/services/matching_power_service.dart
//
// Calculates matching completeness and diagnostic breakdown for a student's profile.
// Provides deterministic score, percentage, items checklist, and actionable advice.

import '../models/student_profile.dart';

/// A diagnostic item in the matching power checklist.
class MatchingPowerItem {
  const MatchingPowerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isComplete,
    required this.impactHint,
    required this.routeTarget,
  });

  final String id;
  final String title;
  final String subtitle;
  final bool isComplete;
  final String impactHint;
  final String routeTarget;
}

/// Comprehensive report on the student's profile strength and matching readiness.
class MatchingPowerReport {
  const MatchingPowerReport({
    required this.percentage,
    required this.ratio,
    required this.completedCount,
    required this.totalCount,
    required this.items,
    required this.advice,
  });

  final int percentage;
  final double ratio;
  final int completedCount;
  final int totalCount;
  final List<MatchingPowerItem> items;
  final String advice;

  bool get isFullyComplete => percentage == 100;
}

/// Service that evaluates profile completeness and matching power.
class MatchingPowerService {
  const MatchingPowerService._();

  static MatchingPowerReport evaluate(StudentProfile? profile) {
    if (profile == null) {
      return const MatchingPowerReport(
        percentage: 0,
        ratio: 0.0,
        completedCount: 0,
        totalCount: 8,
        items: [
          MatchingPowerItem(
            id: 'name',
            title: 'Full Name',
            subtitle: 'Missing name',
            isComplete: false,
            impactHint: 'Establishes applicant identity and legal matching.',
            routeTarget: '/profile-setup/personal',
          ),
          MatchingPowerItem(
            id: 'nationality',
            title: 'Citizenship',
            subtitle: 'Missing nationality',
            isComplete: false,
            impactHint: 'Establishes citizenship eligibility for Philippine scholarships.',
            routeTarget: '/profile-setup/personal',
          ),
          MatchingPowerItem(
            id: 'location',
            title: 'Location & Region',
            subtitle: 'Missing region',
            isComplete: false,
            impactHint: 'Matches localized and LGU-sponsored educational grants.',
            routeTarget: '/profile-setup/personal',
          ),
          MatchingPowerItem(
            id: 'course',
            title: 'Course / Degree Program',
            subtitle: 'Missing degree course',
            isComplete: false,
            impactHint: 'Matches priority STEM, business, and degree-specific funding.',
            routeTarget: '/profile-setup/academic',
          ),
          MatchingPowerItem(
            id: 'year_level',
            title: 'Academic Standing',
            subtitle: 'Missing year level',
            isComplete: false,
            impactHint: 'Matches programs accepting your current matriculation year.',
            routeTarget: '/profile-setup/academic',
          ),
          MatchingPowerItem(
            id: 'gpa',
            title: 'Academic Standing & GPA',
            subtitle: 'Missing GPA records',
            isComplete: false,
            impactHint: 'Unlocks merit-based and academic honors scholarships.',
            routeTarget: '/profile-setup/academic',
          ),
          MatchingPowerItem(
            id: 'school',
            title: 'School or University',
            subtitle: 'Not yet added',
            isComplete: false,
            impactHint: 'Unlocks campus-partnered grants and university tuition assistance.',
            routeTarget: '/profile-setup/academic',
          ),
          MatchingPowerItem(
            id: 'income',
            title: 'Family Income Bracket',
            subtitle: 'Not yet specified',
            isComplete: false,
            impactHint: 'Unlocks need-based subsidies and government stipend allowances.',
            routeTarget: '/profile-setup/financial',
          ),
        ],
        advice: 'Complete your profile setup to unlock personalized scholarship matches!',
      );
    }

    final hasName = profile.fullName.trim().isNotEmpty;
    final hasNationality = profile.nationality.trim().isNotEmpty;
    final hasLocation = profile.region.trim().isNotEmpty;
    final hasCourse = profile.course.trim().isNotEmpty;
    final hasYearLevel = profile.yearLevel > 0;
    final hasGpa = profile.gpa > 0.0;
    final hasSchool =
        profile.school != null && profile.school!.trim().isNotEmpty;
    final hasIncome = profile.monthlyFamilyIncome != null;

    final items = <MatchingPowerItem>[
      MatchingPowerItem(
        id: 'name',
        title: 'Full Name',
        subtitle: hasName ? profile.fullName : 'Missing name',
        isComplete: hasName,
        impactHint: 'Establishes applicant identity and legal matching.',
        routeTarget: '/profile-setup/personal',
      ),
      MatchingPowerItem(
        id: 'nationality',
        title: 'Citizenship',
        subtitle: hasNationality ? profile.nationality : 'Missing nationality',
        isComplete: hasNationality,
        impactHint: 'Establishes citizenship eligibility for Philippine scholarships.',
        routeTarget: '/profile-setup/personal',
      ),
      MatchingPowerItem(
        id: 'location',
        title: 'Location & Region',
        subtitle: hasLocation
            ? (profile.cityMunicipality != null &&
                    profile.cityMunicipality!.isNotEmpty
                ? '${profile.cityMunicipality}, ${profile.region}'
                : profile.region)
            : 'Missing region',
        isComplete: hasLocation,
        impactHint: 'Matches localized and LGU-sponsored educational grants.',
        routeTarget: '/profile-setup/personal',
      ),
      MatchingPowerItem(
        id: 'course',
        title: 'Course / Degree Program',
        subtitle: hasCourse ? profile.course : 'Missing degree course',
        isComplete: hasCourse,
        impactHint: 'Matches priority STEM, business, and degree-specific funding.',
        routeTarget: '/profile-setup/academic',
      ),
      MatchingPowerItem(
        id: 'year_level',
        title: 'Academic Standing',
        subtitle: hasYearLevel ? 'Year ${profile.yearLevel}' : 'Missing year level',
        isComplete: hasYearLevel,
        impactHint: 'Matches programs accepting your current matriculation year.',
        routeTarget: '/profile-setup/academic',
      ),
      MatchingPowerItem(
        id: 'gpa',
        title: 'Academic Standing & GPA',
        subtitle: hasGpa
            ? 'GPA: ${profile.gpa.toStringAsFixed(2)}'
            : 'Missing GPA records',
        isComplete: hasGpa,
        impactHint: 'Unlocks merit-based and academic honors scholarships.',
        routeTarget: '/profile-setup/academic',
      ),
      MatchingPowerItem(
        id: 'school',
        title: 'School or University',
        subtitle: hasSchool ? profile.school! : 'Not yet added',
        isComplete: hasSchool,
        impactHint: 'Unlocks campus-partnered grants and university tuition assistance.',
        routeTarget: '/profile-setup/academic',
      ),
      MatchingPowerItem(
        id: 'income',
        title: 'Family Income Bracket',
        subtitle: hasIncome ? 'Income details provided' : 'Not yet specified',
        isComplete: hasIncome,
        impactHint: 'Unlocks need-based subsidies and government stipend allowances.',
        routeTarget: '/profile-setup/financial',
      ),
    ];

    final completedCount = items.where((item) => item.isComplete).length;
    final totalCount = items.length;
    final ratio = completedCount / totalCount;
    final percentage = (ratio * 100).round();

    final String advice;
    if (percentage == 100) {
      advice =
          'Outstanding! Your matching profile is 100% complete. You have all the details unlocked to find your highest-match scholarships!';
    } else if (!hasSchool && !hasIncome) {
      advice =
          'Scholaris Tip: Add your school & family income to unlock university grants and need-based tuition assistance!';
    } else if (!hasSchool) {
      advice =
          'Scholaris Tip: Add your school or university to qualify for campus-partnered grants!';
    } else if (!hasIncome) {
      advice =
          'Scholaris Tip: Add your family income bracket to qualify for need-based tuition waivers!';
    } else if (!hasGpa) {
      advice =
          'Scholaris Tip: Enter your latest GPA to qualify for academic merit honors!';
    } else {
      advice =
          'Scholaris Tip: Complete any remaining fields to boost your matching accuracy!';
    }

    return MatchingPowerReport(
      percentage: percentage,
      ratio: ratio,
      completedCount: completedCount,
      totalCount: totalCount,
      items: items,
      advice: advice,
    );
  }
}
