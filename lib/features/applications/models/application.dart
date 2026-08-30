// lib/features/applications/models/application.dart
//
// Canonical domain object for a scholarship application. Mirrors the
// `applications` table in supabase/migrations/0001_init.sql exactly:
//
//   id             uuid primary key default gen_random_uuid()
//   user_id        uuid not null references auth.users (id) on delete cascade
//   scholarship_id uuid not null references public.scholarships (id) on delete cascade
//   status         text not null default 'draft'
//                  check (status in ('draft','submitted','under_review','approved','rejected'))
//   notes          text
//   applied_at     timestamptz
//   updated_at     timestamptz not null default now()
//
// Serialization is explicit: every Dart field that differs from the table
// column name carries a @JsonKey(name: 'snake_case') so fromJson/toJson
// round-trip a real Supabase row. Nothing is written to Supabase with
// camelCase keys. The model and the migration must stay in sync.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'application.freezed.dart';
part 'application.g.dart';

/// The lifecycle states a scholarship application can be in. Values mirror the
/// `applications.status` CHECK constraint exactly; [dbValue] is the literal
/// stored in the column.
enum ApplicationStatus {
  draft('draft'),
  submitted('submitted'),
  underReview('under_review'),
  approved('approved'),
  rejected('rejected'),
  withdrawn('withdrawn');

  const ApplicationStatus(this.dbValue);

  final String dbValue;

  static ApplicationStatus fromDbValue(String value) => values.firstWhere(
        (status) => status.dbValue == value,
        orElse: () => throw ArgumentError('Unknown application status: $value'),
      );

  /// Draft, submitted and under review are the in-flight (pending) statuses.
  /// Terminal statuses (approved, rejected, withdrawn) are not pending.
  bool get isPending => this == draft || this == submitted || this == underReview;
}

ApplicationStatus _statusFromJson(Object? value) =>
    ApplicationStatus.fromDbValue(value as String);

String _statusToJson(ApplicationStatus value) => value.dbValue;

DateTime? _dateTimeFromJson(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.parse(value) : null;

String? _dateTimeToJson(DateTime? value) =>
    value?.toUtc().toIso8601String();

@freezed
abstract class Application with _$Application {
  const factory Application({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'scholarship_id') required String scholarshipId,
    @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
    @Default(ApplicationStatus.draft)
    ApplicationStatus status,
    String? notes,
    @JsonKey(name: 'applied_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime? appliedAt,
    @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime? updatedAt,
  }) = _Application;

  factory Application.fromJson(Map<String, dynamic> json) =>
      _$ApplicationFromJson(json);
}
