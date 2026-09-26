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

double _amountFromJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 50000.0;
  return 50000.0;
}

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
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'amount', fromJson: _amountFromJson) @Default(50000.0) double amount,
    @JsonKey(name: 'coverage') @Default('Tuition + Allowance') String coverage,
    @JsonKey(name: 'frequency') @Default('annual') String frequency,
  }) = _Scholarship;

  factory Scholarship.fromJson(Map<String, dynamic> json) =>
      _$ScholarshipFromJson(json);
}

extension ScholarshipAwardExt on Scholarship {
  int get awardAmount => amount.round();

  String get formattedAmount {
    final whole = awardAmount;
    final formatted = whole.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₱$formatted';
  }

  String get formattedFrequency {
    switch (frequency.toLowerCase()) {
      case 'per_semester':
      case 'semester':
        return '/ semester';
      case 'one_time':
      case 'onetime':
        return 'One-time';
      case 'annual':
      case 'year':
      default:
        return '/ year (Renewable)';
    }
  }
}
