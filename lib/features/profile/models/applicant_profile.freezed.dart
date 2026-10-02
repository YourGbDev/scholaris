// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'applicant_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApplicantProfile {

 String get id;@JsonKey(name: 'full_name') String get fullName;@JsonKey(name: 'school') String? get school;@JsonKey(name: 'course') String get course;@JsonKey(name: 'year_level') int get yearLevel;@JsonKey(name: 'gpa') double get gpa;@JsonKey(name: 'region') String get region;@JsonKey(name: 'province') String? get province;@JsonKey(name: 'city_municipality') String? get cityMunicipality;@JsonKey(name: 'setup_complete') bool get setupComplete;@JsonKey(name: 'monthly_family_income') double? get monthlyFamilyIncome;
/// Create a copy of ApplicantProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApplicantProfileCopyWith<ApplicantProfile> get copyWith => _$ApplicantProfileCopyWithImpl<ApplicantProfile>(this as ApplicantProfile, _$identity);

  /// Serializes this ApplicantProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApplicantProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.school, school) || other.school == school)&&(identical(other.course, course) || other.course == course)&&(identical(other.yearLevel, yearLevel) || other.yearLevel == yearLevel)&&(identical(other.gpa, gpa) || other.gpa == gpa)&&(identical(other.region, region) || other.region == region)&&(identical(other.province, province) || other.province == province)&&(identical(other.cityMunicipality, cityMunicipality) || other.cityMunicipality == cityMunicipality)&&(identical(other.setupComplete, setupComplete) || other.setupComplete == setupComplete)&&(identical(other.monthlyFamilyIncome, monthlyFamilyIncome) || other.monthlyFamilyIncome == monthlyFamilyIncome));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,school,course,yearLevel,gpa,region,province,cityMunicipality,setupComplete,monthlyFamilyIncome);

@override
String toString() {
  return 'ApplicantProfile(id: $id, fullName: $fullName, school: $school, course: $course, yearLevel: $yearLevel, gpa: $gpa, region: $region, province: $province, cityMunicipality: $cityMunicipality, setupComplete: $setupComplete, monthlyFamilyIncome: $monthlyFamilyIncome)';
}


}

/// @nodoc
abstract mixin class $ApplicantProfileCopyWith<$Res>  {
  factory $ApplicantProfileCopyWith(ApplicantProfile value, $Res Function(ApplicantProfile) _then) = _$ApplicantProfileCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'school') String? school,@JsonKey(name: 'course') String course,@JsonKey(name: 'year_level') int yearLevel,@JsonKey(name: 'gpa') double gpa,@JsonKey(name: 'region') String region,@JsonKey(name: 'province') String? province,@JsonKey(name: 'city_municipality') String? cityMunicipality,@JsonKey(name: 'setup_complete') bool setupComplete,@JsonKey(name: 'monthly_family_income') double? monthlyFamilyIncome
});




}
/// @nodoc
class _$ApplicantProfileCopyWithImpl<$Res>
    implements $ApplicantProfileCopyWith<$Res> {
  _$ApplicantProfileCopyWithImpl(this._self, this._then);

  final ApplicantProfile _self;
  final $Res Function(ApplicantProfile) _then;

/// Create a copy of ApplicantProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? school = freezed,Object? course = null,Object? yearLevel = null,Object? gpa = null,Object? region = null,Object? province = freezed,Object? cityMunicipality = freezed,Object? setupComplete = null,Object? monthlyFamilyIncome = freezed,}) {
  return _then(ApplicantProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,school: freezed == school ? _self.school : school // ignore: cast_nullable_to_non_nullable
as String?,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as String,yearLevel: null == yearLevel ? _self.yearLevel : yearLevel // ignore: cast_nullable_to_non_nullable
as int,gpa: null == gpa ? _self.gpa : gpa // ignore: cast_nullable_to_non_nullable
as double,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,province: freezed == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String?,cityMunicipality: freezed == cityMunicipality ? _self.cityMunicipality : cityMunicipality // ignore: cast_nullable_to_non_nullable
as String?,setupComplete: null == setupComplete ? _self.setupComplete : setupComplete // ignore: cast_nullable_to_non_nullable
as bool,monthlyFamilyIncome: freezed == monthlyFamilyIncome ? _self.monthlyFamilyIncome : monthlyFamilyIncome // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [ApplicantProfile].
extension ApplicantProfilePatterns on ApplicantProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApplicantProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApplicantProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApplicantProfile value)  $default,){
final _that = this;
switch (_that) {
case _ApplicantProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApplicantProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ApplicantProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'school')  String? school, @JsonKey(name: 'course')  String course, @JsonKey(name: 'year_level')  int yearLevel, @JsonKey(name: 'gpa')  double gpa, @JsonKey(name: 'region')  String region, @JsonKey(name: 'province')  String? province, @JsonKey(name: 'city_municipality')  String? cityMunicipality, @JsonKey(name: 'setup_complete')  bool setupComplete, @JsonKey(name: 'monthly_family_income')  double? monthlyFamilyIncome)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApplicantProfile() when $default != null:
return $default(_that.id,_that.fullName,_that.school,_that.course,_that.yearLevel,_that.gpa,_that.region,_that.province,_that.cityMunicipality,_that.setupComplete,_that.monthlyFamilyIncome);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'school')  String? school, @JsonKey(name: 'course')  String course, @JsonKey(name: 'year_level')  int yearLevel, @JsonKey(name: 'gpa')  double gpa, @JsonKey(name: 'region')  String region, @JsonKey(name: 'province')  String? province, @JsonKey(name: 'city_municipality')  String? cityMunicipality, @JsonKey(name: 'setup_complete')  bool setupComplete, @JsonKey(name: 'monthly_family_income')  double? monthlyFamilyIncome)  $default,) {final _that = this;
switch (_that) {
case _ApplicantProfile():
return $default(_that.id,_that.fullName,_that.school,_that.course,_that.yearLevel,_that.gpa,_that.region,_that.province,_that.cityMunicipality,_that.setupComplete,_that.monthlyFamilyIncome);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'school')  String? school, @JsonKey(name: 'course')  String course, @JsonKey(name: 'year_level')  int yearLevel, @JsonKey(name: 'gpa')  double gpa, @JsonKey(name: 'region')  String region, @JsonKey(name: 'province')  String? province, @JsonKey(name: 'city_municipality')  String? cityMunicipality, @JsonKey(name: 'setup_complete')  bool setupComplete, @JsonKey(name: 'monthly_family_income')  double? monthlyFamilyIncome)?  $default,) {final _that = this;
switch (_that) {
case _ApplicantProfile() when $default != null:
return $default(_that.id,_that.fullName,_that.school,_that.course,_that.yearLevel,_that.gpa,_that.region,_that.province,_that.cityMunicipality,_that.setupComplete,_that.monthlyFamilyIncome);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApplicantProfile extends ApplicantProfile {
  const _ApplicantProfile({required this.id, @JsonKey(name: 'full_name') required this.fullName, @JsonKey(name: 'school') this.school, @JsonKey(name: 'course') required this.course, @JsonKey(name: 'year_level') required this.yearLevel, @JsonKey(name: 'gpa') required this.gpa, @JsonKey(name: 'region') required this.region, @JsonKey(name: 'province') this.province, @JsonKey(name: 'city_municipality') this.cityMunicipality, @JsonKey(name: 'setup_complete') required this.setupComplete, @JsonKey(name: 'monthly_family_income') this.monthlyFamilyIncome}): super._();
  factory _ApplicantProfile.fromJson(Map<String, dynamic> json) => _$ApplicantProfileFromJson(json);

@override final  String id;
@override@JsonKey(name: 'full_name') final  String fullName;
@override@JsonKey(name: 'school') final  String? school;
@override@JsonKey(name: 'course') final  String course;
@override@JsonKey(name: 'year_level') final  int yearLevel;
@override@JsonKey(name: 'gpa') final  double gpa;
@override@JsonKey(name: 'region') final  String region;
@override@JsonKey(name: 'province') final  String? province;
@override@JsonKey(name: 'city_municipality') final  String? cityMunicipality;
@override@JsonKey(name: 'setup_complete') final  bool setupComplete;
@override@JsonKey(name: 'monthly_family_income') final  double? monthlyFamilyIncome;

/// Create a copy of ApplicantProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplicantProfileCopyWith<_ApplicantProfile> get copyWith => __$ApplicantProfileCopyWithImpl<_ApplicantProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApplicantProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApplicantProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.school, school) || other.school == school)&&(identical(other.course, course) || other.course == course)&&(identical(other.yearLevel, yearLevel) || other.yearLevel == yearLevel)&&(identical(other.gpa, gpa) || other.gpa == gpa)&&(identical(other.region, region) || other.region == region)&&(identical(other.province, province) || other.province == province)&&(identical(other.cityMunicipality, cityMunicipality) || other.cityMunicipality == cityMunicipality)&&(identical(other.setupComplete, setupComplete) || other.setupComplete == setupComplete)&&(identical(other.monthlyFamilyIncome, monthlyFamilyIncome) || other.monthlyFamilyIncome == monthlyFamilyIncome));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,school,course,yearLevel,gpa,region,province,cityMunicipality,setupComplete,monthlyFamilyIncome);

@override
String toString() {
  return 'ApplicantProfile(id: $id, fullName: $fullName, school: $school, course: $course, yearLevel: $yearLevel, gpa: $gpa, region: $region, province: $province, cityMunicipality: $cityMunicipality, setupComplete: $setupComplete, monthlyFamilyIncome: $monthlyFamilyIncome)';
}


}

/// @nodoc
abstract mixin class _$ApplicantProfileCopyWith<$Res> implements $ApplicantProfileCopyWith<$Res> {
  factory _$ApplicantProfileCopyWith(_ApplicantProfile value, $Res Function(_ApplicantProfile) _then) = __$ApplicantProfileCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'school') String? school,@JsonKey(name: 'course') String course,@JsonKey(name: 'year_level') int yearLevel,@JsonKey(name: 'gpa') double gpa,@JsonKey(name: 'region') String region,@JsonKey(name: 'province') String? province,@JsonKey(name: 'city_municipality') String? cityMunicipality,@JsonKey(name: 'setup_complete') bool setupComplete,@JsonKey(name: 'monthly_family_income') double? monthlyFamilyIncome
});




}
/// @nodoc
class __$ApplicantProfileCopyWithImpl<$Res>
    implements _$ApplicantProfileCopyWith<$Res> {
  __$ApplicantProfileCopyWithImpl(this._self, this._then);

  final _ApplicantProfile _self;
  final $Res Function(_ApplicantProfile) _then;

/// Create a copy of ApplicantProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? school = freezed,Object? course = null,Object? yearLevel = null,Object? gpa = null,Object? region = null,Object? province = freezed,Object? cityMunicipality = freezed,Object? setupComplete = null,Object? monthlyFamilyIncome = freezed,}) {
  return _then(_ApplicantProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,school: freezed == school ? _self.school : school // ignore: cast_nullable_to_non_nullable
as String?,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as String,yearLevel: null == yearLevel ? _self.yearLevel : yearLevel // ignore: cast_nullable_to_non_nullable
as int,gpa: null == gpa ? _self.gpa : gpa // ignore: cast_nullable_to_non_nullable
as double,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,province: freezed == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String?,cityMunicipality: freezed == cityMunicipality ? _self.cityMunicipality : cityMunicipality // ignore: cast_nullable_to_non_nullable
as String?,setupComplete: null == setupComplete ? _self.setupComplete : setupComplete // ignore: cast_nullable_to_non_nullable
as bool,monthlyFamilyIncome: freezed == monthlyFamilyIncome ? _self.monthlyFamilyIncome : monthlyFamilyIncome // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
