// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StudentProfile _$StudentProfileFromJson(Map<String, dynamic> json) =>
    _StudentProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      yearLevel: (json['yearLevel'] as num).toInt(),
      course: json['course'] as String,
      gpa: (json['gpa'] as num).toDouble(),
      citizenship: json['citizenship'] as String,
      region: json['region'] as String,
      province: json['province'] as String,
      incomeBracket: json['incomeBracket'] as String,
      isWorkingStudent: json['isWorkingStudent'] as bool,
      isPwd: json['isPwd'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$StudentProfileToJson(_StudentProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'yearLevel': instance.yearLevel,
      'course': instance.course,
      'gpa': instance.gpa,
      'citizenship': instance.citizenship,
      'region': instance.region,
      'province': instance.province,
      'incomeBracket': instance.incomeBracket,
      'isWorkingStudent': instance.isWorkingStudent,
      'isPwd': instance.isPwd,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
