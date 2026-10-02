// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'applicant_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApplicantProfile _$ApplicantProfileFromJson(Map<String, dynamic> json) =>
    _ApplicantProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      school: json['school'] as String?,
      course: json['course'] as String,
      yearLevel: (json['year_level'] as num).toInt(),
      gpa: (json['gpa'] as num).toDouble(),
      region: json['region'] as String,
      province: json['province'] as String?,
      cityMunicipality: json['city_municipality'] as String?,
      setupComplete: json['setup_complete'] as bool,
      monthlyFamilyIncome: (json['monthly_family_income'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ApplicantProfileToJson(_ApplicantProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'school': instance.school,
      'course': instance.course,
      'year_level': instance.yearLevel,
      'gpa': instance.gpa,
      'region': instance.region,
      'province': instance.province,
      'city_municipality': instance.cityMunicipality,
      'setup_complete': instance.setupComplete,
      'monthly_family_income': instance.monthlyFamilyIncome,
    };
