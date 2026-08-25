// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scholarship.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Scholarship _$ScholarshipFromJson(Map<String, dynamic> json) => _Scholarship(
  id: json['id'] as String,
  name: json['name'] as String,
  provider: json['provider'] as String?,
  description: json['description'] as String?,
  minGpa: (json['min_gpa'] as num).toDouble(),
  yearLevels:
      (json['year_levels'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [1, 2, 3, 4, 5],
  eligibleCourses:
      (json['eligible_courses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  citizenshipRequired: json['citizenship_required'] as String? ?? 'any',
  regionsEligible:
      (json['regions_eligible'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  maxIncomeBracket: json['max_income_bracket'] as String? ?? 'any',
  isPwdPriority: json['is_pwd_priority'] as bool? ?? false,
  isWorkingStudentPriority:
      json['is_working_student_priority'] as bool? ?? false,
  slotsAvailable: (json['slots_available'] as num?)?.toInt(),
  deadline: _dateFromJson(json['deadline']),
  amount: (json['amount'] as num).toDouble(),
  coverageType: json['coverage_type'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$ScholarshipToJson(_Scholarship instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'provider': instance.provider,
      'description': instance.description,
      'min_gpa': instance.minGpa,
      'year_levels': instance.yearLevels,
      'eligible_courses': instance.eligibleCourses,
      'citizenship_required': instance.citizenshipRequired,
      'regions_eligible': instance.regionsEligible,
      'max_income_bracket': instance.maxIncomeBracket,
      'is_pwd_priority': instance.isPwdPriority,
      'is_working_student_priority': instance.isWorkingStudentPriority,
      'slots_available': instance.slotsAvailable,
      'deadline': instance.deadline.toIso8601String(),
      'amount': instance.amount,
      'coverage_type': instance.coverageType,
      'tags': instance.tags,
      'is_active': instance.isActive,
    };
