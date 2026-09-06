// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scholarship.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Scholarship _$ScholarshipFromJson(Map<String, dynamic> json) => _Scholarship(
  id: json['id'] as String,
  title: json['title'] as String,
  provider: json['provider'] as String?,
  description: json['description'] as String?,
  minGpa: (json['min_gpa'] as num).toDouble(),
  maxMonthlyIncome: (json['max_monthly_income'] as num?)?.toDouble(),
  requiredYearLevels: (json['required_year_levels'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  requiredCourses: (json['required_courses'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  locationRestriction: json['location_restriction'] as String?,
  forIndigenous: json['for_indigenous'] as bool? ?? false,
  forPwd: json['for_pwd'] as bool? ?? false,
  slots: (json['slots'] as num?)?.toInt(),
  deadline: _dateFromJson(json['deadline']),
  applicationUrl: json['application_url'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ScholarshipToJson(_Scholarship instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'provider': instance.provider,
      'description': instance.description,
      'min_gpa': instance.minGpa,
      'max_monthly_income': instance.maxMonthlyIncome,
      'required_year_levels': instance.requiredYearLevels,
      'required_courses': instance.requiredCourses,
      'location_restriction': instance.locationRestriction,
      'for_indigenous': instance.forIndigenous,
      'for_pwd': instance.forPwd,
      'slots': instance.slots,
      'deadline': instance.deadline.toIso8601String(),
      'application_url': instance.applicationUrl,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
    };
