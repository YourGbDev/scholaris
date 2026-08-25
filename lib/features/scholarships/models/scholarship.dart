// lib/features/scholarships/models/scholarship.dart
//
// Canonical domain object for a scholarship. This is the object the matching
// engine and the discovery UI consume.
//
// Serialization is explicit: every Dart field that differs from the
// `scholarships` table column carries a @JsonKey(name: 'snake_case') so
// fromJson/toJson round-trip a real Supabase row. Nothing is written to
// Supabase with camelCase keys.
//
// The table contract lives in supabase/migrations/0002_scholarship_discovery.sql
// — the model and the migration must stay in sync.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'scholarship.freezed.dart';
part 'scholarship.g.dart';

DateTime _dateFromJson(Object? value) => DateTime.parse(value as String);

@freezed
abstract class Scholarship with _$Scholarship {
  const factory Scholarship({
    required String id,
    required String name,
    String? provider,
    String? description,
    @JsonKey(name: 'min_gpa') required double minGpa,
    @JsonKey(name: 'year_levels') @Default([1, 2, 3, 4, 5]) List<int> yearLevels,
    @JsonKey(name: 'eligible_courses') @Default([]) List<String> eligibleCourses,
    @JsonKey(name: 'citizenship_required')
    @Default('any')
    String citizenshipRequired,
    @JsonKey(name: 'regions_eligible') @Default([]) List<String> regionsEligible,
    @JsonKey(name: 'max_income_bracket')
    @Default('any')
    String maxIncomeBracket,
    @JsonKey(name: 'is_pwd_priority') @Default(false) bool isPwdPriority,
    @JsonKey(name: 'is_working_student_priority')
    @Default(false)
    bool isWorkingStudentPriority,
    @JsonKey(name: 'slots_available') int? slotsAvailable,
    @JsonKey(name: 'deadline', fromJson: _dateFromJson) required DateTime deadline,
    required double amount,
    @JsonKey(name: 'coverage_type') String? coverageType,
    @JsonKey(name: 'tags') @Default([]) List<String> tags,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _Scholarship;

  factory Scholarship.fromJson(Map<String, dynamic> json) =>
      _$ScholarshipFromJson(json);
}
