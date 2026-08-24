import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_profile.freezed.dart';
part 'student_profile.g.dart';

@freezed
abstract class StudentProfile with _$StudentProfile {
  const factory StudentProfile({
    required String id,
    required String fullName,
    required String email,
    required int yearLevel,
    required String course,
    required double gpa,
    required String citizenship,
    required String region,
    required String province,
    required String incomeBracket,
    required bool isWorkingStudent,
    required bool isPwd,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _StudentProfile;

  factory StudentProfile.fromJson(Map<String, dynamic> json) =>
      _$StudentProfileFromJson(json);
}
