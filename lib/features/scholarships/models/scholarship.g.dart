// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scholarship.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Scholarship _$ScholarshipFromJson(Map<String, dynamic> json) => _Scholarship(
  id: json['id'] as String,
  name: json['name'] as String,
  provider: json['provider'] as String,
  description: json['description'] as String,
  minGpa: (json['minGpa'] as num).toDouble(),
  yearLevels: (json['yearLevels'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  eligibleCourses: (json['eligibleCourses'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  citizenshipRequired: json['citizenshipRequired'] as String,
  regionsEligible: (json['regionsEligible'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  maxIncomeBracket: json['maxIncomeBracket'] as String,
  isPwdPriority: json['isPwdPriority'] as bool,
  isWorkingStudentPriority: json['isWorkingStudentPriority'] as bool,
  slotsAvailable: (json['slotsAvailable'] as num?)?.toInt(),
  deadline: DateTime.parse(json['deadline'] as String),
  amount: (json['amount'] as num).toDouble(),
  coverageType: json['coverageType'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$ScholarshipToJson(_Scholarship instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'provider': instance.provider,
      'description': instance.description,
      'minGpa': instance.minGpa,
      'yearLevels': instance.yearLevels,
      'eligibleCourses': instance.eligibleCourses,
      'citizenshipRequired': instance.citizenshipRequired,
      'regionsEligible': instance.regionsEligible,
      'maxIncomeBracket': instance.maxIncomeBracket,
      'isPwdPriority': instance.isPwdPriority,
      'isWorkingStudentPriority': instance.isWorkingStudentPriority,
      'slotsAvailable': instance.slotsAvailable,
      'deadline': instance.deadline.toIso8601String(),
      'amount': instance.amount,
      'coverageType': instance.coverageType,
      'tags': instance.tags,
      'isActive': instance.isActive,
    };
