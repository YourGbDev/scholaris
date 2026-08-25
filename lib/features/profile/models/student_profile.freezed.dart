// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StudentProfile {

 String get id;@JsonKey(name: 'full_name') String get fullName; String get nationality;@JsonKey(name: 'birth_date', fromJson: _dateFromJson, toJson: _dateToJson) DateTime? get birthDate; String? get gender; String get region; String? get province;@JsonKey(name: 'city_municipality') String? get cityMunicipality; double get gpa;@JsonKey(name: 'year_level') int get yearLevel; String get course; String? get school;@JsonKey(name: 'monthly_family_income') double? get monthlyFamilyIncome;@JsonKey(name: 'has_disability') bool get hasDisability;@JsonKey(name: 'is_indigenous') bool get isIndigenous;@JsonKey(name: 'setup_complete') bool get setupComplete;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentProfileCopyWith<StudentProfile> get copyWith => _$StudentProfileCopyWithImpl<StudentProfile>(this as StudentProfile, _$identity);

  /// Serializes this StudentProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.region, region) || other.region == region)&&(identical(other.province, province) || other.province == province)&&(identical(other.cityMunicipality, cityMunicipality) || other.cityMunicipality == cityMunicipality)&&(identical(other.gpa, gpa) || other.gpa == gpa)&&(identical(other.yearLevel, yearLevel) || other.yearLevel == yearLevel)&&(identical(other.course, course) || other.course == course)&&(identical(other.school, school) || other.school == school)&&(identical(other.monthlyFamilyIncome, monthlyFamilyIncome) || other.monthlyFamilyIncome == monthlyFamilyIncome)&&(identical(other.hasDisability, hasDisability) || other.hasDisability == hasDisability)&&(identical(other.isIndigenous, isIndigenous) || other.isIndigenous == isIndigenous)&&(identical(other.setupComplete, setupComplete) || other.setupComplete == setupComplete)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,nationality,birthDate,gender,region,province,cityMunicipality,gpa,yearLevel,course,school,monthlyFamilyIncome,hasDisability,isIndigenous,setupComplete,createdAt,updatedAt);

@override
String toString() {
  return 'StudentProfile(id: $id, fullName: $fullName, nationality: $nationality, birthDate: $birthDate, gender: $gender, region: $region, province: $province, cityMunicipality: $cityMunicipality, gpa: $gpa, yearLevel: $yearLevel, course: $course, school: $school, monthlyFamilyIncome: $monthlyFamilyIncome, hasDisability: $hasDisability, isIndigenous: $isIndigenous, setupComplete: $setupComplete, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $StudentProfileCopyWith<$Res>  {
  factory $StudentProfileCopyWith(StudentProfile value, $Res Function(StudentProfile) _then) = _$StudentProfileCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName, String nationality,@JsonKey(name: 'birth_date', fromJson: _dateFromJson, toJson: _dateToJson) DateTime? birthDate, String? gender, String region, String? province,@JsonKey(name: 'city_municipality') String? cityMunicipality, double gpa,@JsonKey(name: 'year_level') int yearLevel, String course, String? school,@JsonKey(name: 'monthly_family_income') double? monthlyFamilyIncome,@JsonKey(name: 'has_disability') bool hasDisability,@JsonKey(name: 'is_indigenous') bool isIndigenous,@JsonKey(name: 'setup_complete') bool setupComplete,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$StudentProfileCopyWithImpl<$Res>
    implements $StudentProfileCopyWith<$Res> {
  _$StudentProfileCopyWithImpl(this._self, this._then);

  final StudentProfile _self;
  final $Res Function(StudentProfile) _then;

/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? nationality = null,Object? birthDate = freezed,Object? gender = freezed,Object? region = null,Object? province = freezed,Object? cityMunicipality = freezed,Object? gpa = null,Object? yearLevel = null,Object? course = null,Object? school = freezed,Object? monthlyFamilyIncome = freezed,Object? hasDisability = null,Object? isIndigenous = null,Object? setupComplete = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(StudentProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,nationality: null == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,province: freezed == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String?,cityMunicipality: freezed == cityMunicipality ? _self.cityMunicipality : cityMunicipality // ignore: cast_nullable_to_non_nullable
as String?,gpa: null == gpa ? _self.gpa : gpa // ignore: cast_nullable_to_non_nullable
as double,yearLevel: null == yearLevel ? _self.yearLevel : yearLevel // ignore: cast_nullable_to_non_nullable
as int,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as String,school: freezed == school ? _self.school : school // ignore: cast_nullable_to_non_nullable
as String?,monthlyFamilyIncome: freezed == monthlyFamilyIncome ? _self.monthlyFamilyIncome : monthlyFamilyIncome // ignore: cast_nullable_to_non_nullable
as double?,hasDisability: null == hasDisability ? _self.hasDisability : hasDisability // ignore: cast_nullable_to_non_nullable
as bool,isIndigenous: null == isIndigenous ? _self.isIndigenous : isIndigenous // ignore: cast_nullable_to_non_nullable
as bool,setupComplete: null == setupComplete ? _self.setupComplete : setupComplete // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentProfile].
extension StudentProfilePatterns on StudentProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentProfile value)  $default,){
final _that = this;
switch (_that) {
case _StudentProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentProfile value)?  $default,){
final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName,  String nationality, @JsonKey(name: 'birth_date', fromJson: _dateFromJson, toJson: _dateToJson)  DateTime? birthDate,  String? gender,  String region,  String? province, @JsonKey(name: 'city_municipality')  String? cityMunicipality,  double gpa, @JsonKey(name: 'year_level')  int yearLevel,  String course,  String? school, @JsonKey(name: 'monthly_family_income')  double? monthlyFamilyIncome, @JsonKey(name: 'has_disability')  bool hasDisability, @JsonKey(name: 'is_indigenous')  bool isIndigenous, @JsonKey(name: 'setup_complete')  bool setupComplete, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
return $default(_that.id,_that.fullName,_that.nationality,_that.birthDate,_that.gender,_that.region,_that.province,_that.cityMunicipality,_that.gpa,_that.yearLevel,_that.course,_that.school,_that.monthlyFamilyIncome,_that.hasDisability,_that.isIndigenous,_that.setupComplete,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName,  String nationality, @JsonKey(name: 'birth_date', fromJson: _dateFromJson, toJson: _dateToJson)  DateTime? birthDate,  String? gender,  String region,  String? province, @JsonKey(name: 'city_municipality')  String? cityMunicipality,  double gpa, @JsonKey(name: 'year_level')  int yearLevel,  String course,  String? school, @JsonKey(name: 'monthly_family_income')  double? monthlyFamilyIncome, @JsonKey(name: 'has_disability')  bool hasDisability, @JsonKey(name: 'is_indigenous')  bool isIndigenous, @JsonKey(name: 'setup_complete')  bool setupComplete, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _StudentProfile():
return $default(_that.id,_that.fullName,_that.nationality,_that.birthDate,_that.gender,_that.region,_that.province,_that.cityMunicipality,_that.gpa,_that.yearLevel,_that.course,_that.school,_that.monthlyFamilyIncome,_that.hasDisability,_that.isIndigenous,_that.setupComplete,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'full_name')  String fullName,  String nationality, @JsonKey(name: 'birth_date', fromJson: _dateFromJson, toJson: _dateToJson)  DateTime? birthDate,  String? gender,  String region,  String? province, @JsonKey(name: 'city_municipality')  String? cityMunicipality,  double gpa, @JsonKey(name: 'year_level')  int yearLevel,  String course,  String? school, @JsonKey(name: 'monthly_family_income')  double? monthlyFamilyIncome, @JsonKey(name: 'has_disability')  bool hasDisability, @JsonKey(name: 'is_indigenous')  bool isIndigenous, @JsonKey(name: 'setup_complete')  bool setupComplete, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
return $default(_that.id,_that.fullName,_that.nationality,_that.birthDate,_that.gender,_that.region,_that.province,_that.cityMunicipality,_that.gpa,_that.yearLevel,_that.course,_that.school,_that.monthlyFamilyIncome,_that.hasDisability,_that.isIndigenous,_that.setupComplete,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentProfile extends StudentProfile {
  const _StudentProfile({required this.id, @JsonKey(name: 'full_name') required this.fullName, this.nationality = 'Filipino', @JsonKey(name: 'birth_date', fromJson: _dateFromJson, toJson: _dateToJson) this.birthDate, this.gender, required this.region, this.province, @JsonKey(name: 'city_municipality') this.cityMunicipality, required this.gpa, @JsonKey(name: 'year_level') required this.yearLevel, required this.course, this.school, @JsonKey(name: 'monthly_family_income') this.monthlyFamilyIncome, @JsonKey(name: 'has_disability') this.hasDisability = false, @JsonKey(name: 'is_indigenous') this.isIndigenous = false, @JsonKey(name: 'setup_complete') this.setupComplete = false, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): super._();
  factory _StudentProfile.fromJson(Map<String, dynamic> json) => _$StudentProfileFromJson(json);

@override final  String id;
@override@JsonKey(name: 'full_name') final  String fullName;
@override@JsonKey() final  String nationality;
@override@JsonKey(name: 'birth_date', fromJson: _dateFromJson, toJson: _dateToJson) final  DateTime? birthDate;
@override final  String? gender;
@override final  String region;
@override final  String? province;
@override@JsonKey(name: 'city_municipality') final  String? cityMunicipality;
@override final  double gpa;
@override@JsonKey(name: 'year_level') final  int yearLevel;
@override final  String course;
@override final  String? school;
@override@JsonKey(name: 'monthly_family_income') final  double? monthlyFamilyIncome;
@override@JsonKey(name: 'has_disability') final  bool hasDisability;
@override@JsonKey(name: 'is_indigenous') final  bool isIndigenous;
@override@JsonKey(name: 'setup_complete') final  bool setupComplete;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentProfileCopyWith<_StudentProfile> get copyWith => __$StudentProfileCopyWithImpl<_StudentProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.region, region) || other.region == region)&&(identical(other.province, province) || other.province == province)&&(identical(other.cityMunicipality, cityMunicipality) || other.cityMunicipality == cityMunicipality)&&(identical(other.gpa, gpa) || other.gpa == gpa)&&(identical(other.yearLevel, yearLevel) || other.yearLevel == yearLevel)&&(identical(other.course, course) || other.course == course)&&(identical(other.school, school) || other.school == school)&&(identical(other.monthlyFamilyIncome, monthlyFamilyIncome) || other.monthlyFamilyIncome == monthlyFamilyIncome)&&(identical(other.hasDisability, hasDisability) || other.hasDisability == hasDisability)&&(identical(other.isIndigenous, isIndigenous) || other.isIndigenous == isIndigenous)&&(identical(other.setupComplete, setupComplete) || other.setupComplete == setupComplete)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,nationality,birthDate,gender,region,province,cityMunicipality,gpa,yearLevel,course,school,monthlyFamilyIncome,hasDisability,isIndigenous,setupComplete,createdAt,updatedAt);

@override
String toString() {
  return 'StudentProfile(id: $id, fullName: $fullName, nationality: $nationality, birthDate: $birthDate, gender: $gender, region: $region, province: $province, cityMunicipality: $cityMunicipality, gpa: $gpa, yearLevel: $yearLevel, course: $course, school: $school, monthlyFamilyIncome: $monthlyFamilyIncome, hasDisability: $hasDisability, isIndigenous: $isIndigenous, setupComplete: $setupComplete, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$StudentProfileCopyWith<$Res> implements $StudentProfileCopyWith<$Res> {
  factory _$StudentProfileCopyWith(_StudentProfile value, $Res Function(_StudentProfile) _then) = __$StudentProfileCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName, String nationality,@JsonKey(name: 'birth_date', fromJson: _dateFromJson, toJson: _dateToJson) DateTime? birthDate, String? gender, String region, String? province,@JsonKey(name: 'city_municipality') String? cityMunicipality, double gpa,@JsonKey(name: 'year_level') int yearLevel, String course, String? school,@JsonKey(name: 'monthly_family_income') double? monthlyFamilyIncome,@JsonKey(name: 'has_disability') bool hasDisability,@JsonKey(name: 'is_indigenous') bool isIndigenous,@JsonKey(name: 'setup_complete') bool setupComplete,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$StudentProfileCopyWithImpl<$Res>
    implements _$StudentProfileCopyWith<$Res> {
  __$StudentProfileCopyWithImpl(this._self, this._then);

  final _StudentProfile _self;
  final $Res Function(_StudentProfile) _then;

/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? nationality = null,Object? birthDate = freezed,Object? gender = freezed,Object? region = null,Object? province = freezed,Object? cityMunicipality = freezed,Object? gpa = null,Object? yearLevel = null,Object? course = null,Object? school = freezed,Object? monthlyFamilyIncome = freezed,Object? hasDisability = null,Object? isIndigenous = null,Object? setupComplete = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_StudentProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,nationality: null == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,province: freezed == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String?,cityMunicipality: freezed == cityMunicipality ? _self.cityMunicipality : cityMunicipality // ignore: cast_nullable_to_non_nullable
as String?,gpa: null == gpa ? _self.gpa : gpa // ignore: cast_nullable_to_non_nullable
as double,yearLevel: null == yearLevel ? _self.yearLevel : yearLevel // ignore: cast_nullable_to_non_nullable
as int,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as String,school: freezed == school ? _self.school : school // ignore: cast_nullable_to_non_nullable
as String?,monthlyFamilyIncome: freezed == monthlyFamilyIncome ? _self.monthlyFamilyIncome : monthlyFamilyIncome // ignore: cast_nullable_to_non_nullable
as double?,hasDisability: null == hasDisability ? _self.hasDisability : hasDisability // ignore: cast_nullable_to_non_nullable
as bool,isIndigenous: null == isIndigenous ? _self.isIndigenous : isIndigenous // ignore: cast_nullable_to_non_nullable
as bool,setupComplete: null == setupComplete ? _self.setupComplete : setupComplete // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
