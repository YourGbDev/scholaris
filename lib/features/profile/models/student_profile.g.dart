// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StudentProfile _$StudentProfileFromJson(Map<String, dynamic> json) =>
    _StudentProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      nationality: json['nationality'] as String? ?? 'Filipino',
      birthDate: _dateFromJson(json['birth_date']),
      gender: json['gender'] as String?,
      region: json['region'] as String,
      province: json['province'] as String?,
      cityMunicipality: json['city_municipality'] as String?,
      gpa: (json['gpa'] as num).toDouble(),
      yearLevel: (json['year_level'] as num).toInt(),
      course: json['course'] as String,
      school: json['school'] as String?,
      monthlyFamilyIncome: (json['monthly_family_income'] as num?)?.toDouble(),
      hasDisability: json['has_disability'] as bool? ?? false,
      isIndigenous: json['is_indigenous'] as bool? ?? false,
      setupComplete: json['setup_complete'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$StudentProfileToJson(_StudentProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'nationality': instance.nationality,
      'birth_date': _dateToJson(instance.birthDate),
      'gender': instance.gender,
      'region': instance.region,
      'province': instance.province,
      'city_municipality': instance.cityMunicipality,
      'gpa': instance.gpa,
      'year_level': instance.yearLevel,
      'course': instance.course,
      'school': instance.school,
      'monthly_family_income': instance.monthlyFamilyIncome,
      'has_disability': instance.hasDisability,
      'is_indigenous': instance.isIndigenous,
      'setup_complete': instance.setupComplete,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
