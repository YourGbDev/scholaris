// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Application _$ApplicationFromJson(Map<String, dynamic> json) => _Application(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  scholarshipId: json['scholarship_id'] as String,
  status: json['status'] == null
      ? ApplicationStatus.draft
      : _statusFromJson(json['status']),
  notes: json['notes'] as String?,
  appliedAt: _dateTimeFromJson(json['applied_at']),
  updatedAt: _dateTimeFromJson(json['updated_at']),
);

Map<String, dynamic> _$ApplicationToJson(_Application instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'scholarship_id': instance.scholarshipId,
      'status': _statusToJson(instance.status),
      'notes': instance.notes,
      'applied_at': _dateTimeToJson(instance.appliedAt),
      'updated_at': _dateTimeToJson(instance.updatedAt),
    };
