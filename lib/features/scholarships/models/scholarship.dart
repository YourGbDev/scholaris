import 'package:freezed_annotation/freezed_annotation.dart';

part 'scholarship.freezed.dart';
part 'scholarship.g.dart';

@freezed
abstract class Scholarship with _$Scholarship {
  const factory Scholarship({
    required String id,
    required String name,
    required String provider,
    required String description,
    required double minGpa,
    required List<int> yearLevels,
    required List<String> eligibleCourses,
    required String citizenshipRequired,
    required List<String> regionsEligible,
    required String maxIncomeBracket,
    required bool isPwdPriority,
    required bool isWorkingStudentPriority,
    int? slotsAvailable,
    required DateTime deadline,
    required double amount,
    required String coverageType,
    required List<String> tags,
    required bool isActive,
  }) = _Scholarship;

  factory Scholarship.fromJson(Map<String, dynamic> json) =>
      _$ScholarshipFromJson(json);
}
