// lib/features/profile/models/student_profile.dart
//
// Canonical domain object for a student's profile. This is the object the
// future eligibility engine and matching system consume.
//
// Serialization is explicit: every Dart field that differs from the `profiles`
// table column name carries a @JsonKey(name: 'snake_case') so fromJson/toJson
// round-trip a real Supabase row. Nothing is written to Supabase with camelCase
// keys.
//
// Deterministic eligibility inputs (required):
//   - gpa                 (GPA)
//   - yearLevel           (Year Level)
//   - course              (Course)
//   - monthlyFamilyIncome (Household/Family Income)
//   - region              (Location)
//   - nationality         (citizenship-based eligibility)
// Personalization inputs (optional):
//   - fullName, birthDate, gender, school, province, cityMunicipality
// Eligibility modifiers (optional, default false):
//   - hasDisability, isIndigenous

import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_profile.freezed.dart';
part 'student_profile.g.dart';

/// Coarse income brackets used by the deterministic matching rules. These are
/// derived from [monthlyFamilyIncome] at read time; they are NOT stored.
enum IncomeBracket { low, mid, high }

/// Monthly family income (PHP) below which a family is considered `low`.
const double kLowIncomeThreshold = 25000;

/// Monthly family income (PHP) at or below which a family is considered `mid`.
const double kMidIncomeThreshold = 70000;

/// Philippine regions offered in the location selector. The values are kept
/// stable so scholarship `regions_eligible` entries can match exactly.
const List<String> kPhilippineRegions = [
  'NCR',
  'CAR',
  'Region I',
  'Region II',
  'Region III',
  'Region IV-A (CALABARZON)',
  'MIMAROPA',
  'Region V',
  'Region VI',
  'Region VII',
  'Region VIII',
  'Region IX',
  'Region X',
  'Region XI',
  'Region XII',
  'Region XIII (Caraga)',
  'BARMM',
];

/// Formats a [DateTime] as `yyyy-MM-dd` (matches the `date` DB column format).
String formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Derives the income bracket from a monthly income, or null when the student
/// did not disclose their income. Null is safe for matching: income-based
/// scholarships simply do not match undisclosed profiles.
IncomeBracket? incomeBracketFor(double? monthlyIncome) {
  if (monthlyIncome == null) return null;
  if (monthlyIncome < kLowIncomeThreshold) return IncomeBracket.low;
  if (monthlyIncome <= kMidIncomeThreshold) return IncomeBracket.mid;
  return IncomeBracket.high;
}

String? incomeBracketName(double? monthlyIncome) =>
    incomeBracketFor(monthlyIncome)?.name;

DateTime? _dateFromJson(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.parse(value) : null;

String? _dateToJson(DateTime? value) => value == null ? null : formatDate(value);

@freezed
abstract class StudentProfile with _$StudentProfile {
  const factory StudentProfile({
    required String id,
    @JsonKey(name: 'full_name') required String fullName,
    @Default('Filipino') String nationality,
    @JsonKey(name: 'birth_date', fromJson: _dateFromJson, toJson: _dateToJson)
    DateTime? birthDate,
    String? gender,
    required String region,
    String? province,
    @JsonKey(name: 'city_municipality') String? cityMunicipality,
    required double gpa,
    @JsonKey(name: 'year_level') required int yearLevel,
    required String course,
    String? school,
    @JsonKey(name: 'monthly_family_income') double? monthlyFamilyIncome,
    @JsonKey(name: 'has_disability') @Default(false) bool hasDisability,
    @JsonKey(name: 'is_indigenous') @Default(false) bool isIndigenous,
    @JsonKey(name: 'setup_complete') @Default(false) bool setupComplete,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _StudentProfile;

  factory StudentProfile.fromJson(Map<String, dynamic> json) =>
      _$StudentProfileFromJson(json);

  const StudentProfile._();

  /// Maps this profile to the snake_case columns the `profiles` table accepts.
  /// System columns (`id`, `created_at`, `updated_at`) are excluded — they are
  /// managed by the database.
  Map<String, dynamic> toDbRow() => {
        'full_name': fullName,
        'birth_date': birthDate == null ? null : formatDate(birthDate!),
        'gender': gender,
        'nationality': nationality,
        'region': region,
        'province': province,
        'city_municipality': cityMunicipality,
        'gpa': gpa,
        'year_level': yearLevel,
        'course': course,
        'school': school,
        'monthly_family_income': monthlyFamilyIncome,
        'has_disability': hasDisability,
        'is_indigenous': isIndigenous,
        'setup_complete': setupComplete,
      };

  /// Income bracket consumed by the matching engine (derived, never stored).
  String? get incomeBracket => incomeBracketName(monthlyFamilyIncome);
}
