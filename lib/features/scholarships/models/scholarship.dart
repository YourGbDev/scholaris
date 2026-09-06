// lib/features/scholarships/models/scholarship.dart
//
// Canonical domain object for a scholarship. This is the object the matching
// engine and the discovery UI consume.
//
// Serialization is explicit: every Dart field that differs from the
// `scholarships` table column carries a @JsonKey(name: 'snake_case') so
// fromJson/toJson round-trip a real Supabase row. Nothing is written to
// Supabase with camelCase keys.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'scholarship.freezed.dart';
part 'scholarship.g.dart';

DateTime _dateFromJson(Object? value) => DateTime.parse(value as String);

@freezed
abstract class Scholarship with _$Scholarship {
  const factory Scholarship({
    required String id,
    required String title,
    String? provider,
    String? description,
    @JsonKey(name: 'min_gpa') required double minGpa,
    @JsonKey(name: 'max_monthly_income') double? maxMonthlyIncome,
    @JsonKey(name: 'required_year_levels') List<int>? requiredYearLevels,
    @JsonKey(name: 'required_courses') List<String>? requiredCourses,
    @JsonKey(name: 'location_restriction') String? locationRestriction,
    @JsonKey(name: 'for_indigenous') @Default(false) bool? forIndigenous,
    @JsonKey(name: 'for_pwd') @Default(false) bool? forPwd,
    @JsonKey(name: 'slots') int? slots,
    @JsonKey(name: 'deadline', fromJson: _dateFromJson) required DateTime deadline,
    @JsonKey(name: 'application_url') String? applicationUrl,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Scholarship;

  factory Scholarship.fromJson(Map<String, dynamic> json) =>
      _$ScholarshipFromJson(json);
}
