// lib/features/profile/models/profile_validator.dart
//
// Domain-layer validation for StudentProfile fields. Used by the profile-setup
// provider AND by tests. The UI merely surfaces errors returned here.

/// Per-field validation errors returned by [ProfileValidator].
class ProfileFieldErrors {
  const ProfileFieldErrors({
    this.fullName,
    this.nationality,
    this.gpa,
    this.yearLevel,
    this.course,
    this.monthlyFamilyIncome,
    this.region,
  });

  final String? fullName;
  final String? nationality;
  final String? gpa;
  final String? yearLevel;
  final String? course;
  final String? monthlyFamilyIncome;
  final String? region;

  bool get isValid =>
      fullName == null &&
      nationality == null &&
      gpa == null &&
      yearLevel == null &&
      course == null &&
      monthlyFamilyIncome == null &&
      region == null;

  /// Returns a copy with [gpa] replaced (used to clear a single field error).
  ProfileFieldErrors copyWith({
    String? fullName,
    String? nationality,
    String? gpa,
    String? yearLevel,
    String? course,
    String? monthlyFamilyIncome,
    String? region,
  }) =>
      ProfileFieldErrors(
        fullName: fullName ?? this.fullName,
        nationality: nationality ?? this.nationality,
        gpa: gpa ?? this.gpa,
        yearLevel: yearLevel ?? this.yearLevel,
        course: course ?? this.course,
        monthlyFamilyIncome: monthlyFamilyIncome ?? this.monthlyFamilyIncome,
        region: region ?? this.region,
      );
}

/// Pure domain validation. Every method is stateless and testable.
class ProfileValidator {
  const ProfileValidator();

  ProfileFieldErrors validate({
    required String fullName,
    required String nationality,
    required double? gpa,
    required int? yearLevel,
    required String course,
    required String monthlyFamilyIncome,
    required bool incomeUndisclosed,
    required String? region,
    String gpaScale = '4.0 Scale',
  }) {
    return ProfileFieldErrors(
      fullName: _fullNameError(fullName),
      nationality: _nationalityError(nationality),
      gpa: _gpaError(gpa, gpaScale),
      yearLevel: _yearLevelError(yearLevel),
      course: _courseError(course),
      monthlyFamilyIncome: _incomeError(monthlyFamilyIncome, incomeUndisclosed),
      region: _regionError(region),
    );
  }

  String? _fullNameError(String v) =>
      v.trim().isEmpty ? 'Enter your full name.' : null;

  String? _nationalityError(String v) =>
      v.trim().isEmpty ? 'Nationality is required.' : null;

  String? validateGpa(double? gpa, [String gpaScale = '4.0 Scale']) =>
      _gpaError(gpa, gpaScale);

  String? _gpaError(double? gpa, [String gpaScale = '4.0 Scale']) {
    if (gpa == null) return 'Enter your GPA.';
    final normalizedScale = gpaScale.toLowerCase();
    if (normalizedScale.contains('5.0') ||
        normalizedScale.contains('ph standard') ||
        normalizedScale.contains('1.0 – 5.0') ||
        normalizedScale.contains('1.0 - 5.0')) {
      if (gpa < 1.0 || gpa > 5.0) return 'GPA must be between 1.0 and 5.0.';
      return null;
    }
    if (normalizedScale.contains('%') ||
        normalizedScale.contains('percentage')) {
      if (gpa < 60.0 || gpa > 100.0) {
        return 'Percentage grade must be between 60.0 and 100.0.';
      }
      return null;
    }
    if (gpa < 1.0 || gpa > 4.0) return 'GPA must be between 1.0 and 4.0.';
    return null;
  }

  String? _yearLevelError(int? yearLevel) {
    if (yearLevel == null || yearLevel < 1 || yearLevel > 5) {
      return 'Select a valid year level.';
    }
    return null;
  }

  String? _courseError(String v) =>
      v.trim().isEmpty ? 'Course is required.' : null;

  String? _incomeError(String input, bool undisclosed) {
    if (undisclosed) return null;
    final value = double.tryParse(input.trim());
    if (value == null) {
      return 'Enter your monthly family income, or choose "Prefer not to say".';
    }
    if (value < 0) return 'Income cannot be negative.';
    return null;
  }

  String? _regionError(String? v) =>
      v == null || v.trim().isEmpty ? 'Select your region.' : null;
}