import 'package:freezed_annotation/freezed_annotation.dart';
import 'student_profile.dart'; // To access incomeBracketName

part 'applicant_profile.freezed.dart';
part 'applicant_profile.g.dart';

@freezed
abstract class ApplicantProfile with _$ApplicantProfile {
  const factory ApplicantProfile({
    required String id,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'school') String? school,
    @JsonKey(name: 'course') required String course,
    @JsonKey(name: 'year_level') required int yearLevel,
    @JsonKey(name: 'gpa') required double gpa,
    @JsonKey(name: 'region') required String region,
    @JsonKey(name: 'province') String? province,
    @JsonKey(name: 'city_municipality') String? cityMunicipality,
    @JsonKey(name: 'setup_complete') required bool setupComplete,
    @JsonKey(name: 'monthly_family_income') double? monthlyFamilyIncome,
  }) = _ApplicantProfile;

  factory ApplicantProfile.fromJson(Map<String, dynamic> json) =>
      _$ApplicantProfileFromJson(json);

  const ApplicantProfile._();

  /// Income bracket consumed by the matching engine
  String? get incomeBracket => incomeBracketName(monthlyFamilyIncome);
}
