import 'package:freezed_annotation/freezed_annotation.dart';
import 'student_profile.dart'; // To access incomeBracketName

part 'applicant_profile.freezed.dart';
part 'applicant_profile.g.dart';

@freezed
abstract class ApplicantProfile with _$ApplicantProfile {
  const factory ApplicantProfile({
    required String id,
    @JsonKey(name: 'full_name') @Default('') String fullName,
    @JsonKey(name: 'school') String? school,
    @JsonKey(name: 'course') @Default('') String course,
    @JsonKey(name: 'year_level') @Default(1) int yearLevel,
    @JsonKey(name: 'gpa') @Default(0.0) double gpa,
    @JsonKey(name: 'region') @Default('') String region,
    @JsonKey(name: 'province') String? province,
    @JsonKey(name: 'city_municipality') String? cityMunicipality,
    @JsonKey(name: 'setup_complete') @Default(false) bool setupComplete,
    @JsonKey(name: 'monthly_family_income') double? monthlyFamilyIncome,
  }) = _ApplicantProfile;

  factory ApplicantProfile.fromJson(Map<String, dynamic> json) =>
      _$ApplicantProfileFromJson(json);

  const ApplicantProfile._();

  /// Income bracket consumed by the matching engine
  String? get incomeBracket => incomeBracketName(monthlyFamilyIncome);
}
