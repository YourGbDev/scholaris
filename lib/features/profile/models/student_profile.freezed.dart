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

 String get id; String get fullName; String get email; int get yearLevel; String get course; double get gpa; String get citizenship; String get region; String get province; String get incomeBracket; bool get isWorkingStudent; bool get isPwd; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentProfileCopyWith<StudentProfile> get copyWith => _$StudentProfileCopyWithImpl<StudentProfile>(this as StudentProfile, _$identity);

  /// Serializes this StudentProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.yearLevel, yearLevel) || other.yearLevel == yearLevel)&&(identical(other.course, course) || other.course == course)&&(identical(other.gpa, gpa) || other.gpa == gpa)&&(identical(other.citizenship, citizenship) || other.citizenship == citizenship)&&(identical(other.region, region) || other.region == region)&&(identical(other.province, province) || other.province == province)&&(identical(other.incomeBracket, incomeBracket) || other.incomeBracket == incomeBracket)&&(identical(other.isWorkingStudent, isWorkingStudent) || other.isWorkingStudent == isWorkingStudent)&&(identical(other.isPwd, isPwd) || other.isPwd == isPwd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,email,yearLevel,course,gpa,citizenship,region,province,incomeBracket,isWorkingStudent,isPwd,createdAt,updatedAt);

@override
String toString() {
  return 'StudentProfile(id: $id, fullName: $fullName, email: $email, yearLevel: $yearLevel, course: $course, gpa: $gpa, citizenship: $citizenship, region: $region, province: $province, incomeBracket: $incomeBracket, isWorkingStudent: $isWorkingStudent, isPwd: $isPwd, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $StudentProfileCopyWith<$Res>  {
  factory $StudentProfileCopyWith(StudentProfile value, $Res Function(StudentProfile) _then) = _$StudentProfileCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, String email, int yearLevel, String course, double gpa, String citizenship, String region, String province, String incomeBracket, bool isWorkingStudent, bool isPwd, DateTime createdAt, DateTime updatedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? yearLevel = null,Object? course = null,Object? gpa = null,Object? citizenship = null,Object? region = null,Object? province = null,Object? incomeBracket = null,Object? isWorkingStudent = null,Object? isPwd = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(StudentProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,yearLevel: null == yearLevel ? _self.yearLevel : yearLevel // ignore: cast_nullable_to_non_nullable
as int,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as String,gpa: null == gpa ? _self.gpa : gpa // ignore: cast_nullable_to_non_nullable
as double,citizenship: null == citizenship ? _self.citizenship : citizenship // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,province: null == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String,incomeBracket: null == incomeBracket ? _self.incomeBracket : incomeBracket // ignore: cast_nullable_to_non_nullable
as String,isWorkingStudent: null == isWorkingStudent ? _self.isWorkingStudent : isWorkingStudent // ignore: cast_nullable_to_non_nullable
as bool,isPwd: null == isPwd ? _self.isPwd : isPwd // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  String email,  int yearLevel,  String course,  double gpa,  String citizenship,  String region,  String province,  String incomeBracket,  bool isWorkingStudent,  bool isPwd,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.yearLevel,_that.course,_that.gpa,_that.citizenship,_that.region,_that.province,_that.incomeBracket,_that.isWorkingStudent,_that.isPwd,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  String email,  int yearLevel,  String course,  double gpa,  String citizenship,  String region,  String province,  String incomeBracket,  bool isWorkingStudent,  bool isPwd,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _StudentProfile():
return $default(_that.id,_that.fullName,_that.email,_that.yearLevel,_that.course,_that.gpa,_that.citizenship,_that.region,_that.province,_that.incomeBracket,_that.isWorkingStudent,_that.isPwd,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  String email,  int yearLevel,  String course,  double gpa,  String citizenship,  String region,  String province,  String incomeBracket,  bool isWorkingStudent,  bool isPwd,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.yearLevel,_that.course,_that.gpa,_that.citizenship,_that.region,_that.province,_that.incomeBracket,_that.isWorkingStudent,_that.isPwd,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentProfile implements StudentProfile {
  const _StudentProfile({required this.id, required this.fullName, required this.email, required this.yearLevel, required this.course, required this.gpa, required this.citizenship, required this.region, required this.province, required this.incomeBracket, required this.isWorkingStudent, required this.isPwd, required this.createdAt, required this.updatedAt});
  factory _StudentProfile.fromJson(Map<String, dynamic> json) => _$StudentProfileFromJson(json);

@override final  String id;
@override final  String fullName;
@override final  String email;
@override final  int yearLevel;
@override final  String course;
@override final  double gpa;
@override final  String citizenship;
@override final  String region;
@override final  String province;
@override final  String incomeBracket;
@override final  bool isWorkingStudent;
@override final  bool isPwd;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.yearLevel, yearLevel) || other.yearLevel == yearLevel)&&(identical(other.course, course) || other.course == course)&&(identical(other.gpa, gpa) || other.gpa == gpa)&&(identical(other.citizenship, citizenship) || other.citizenship == citizenship)&&(identical(other.region, region) || other.region == region)&&(identical(other.province, province) || other.province == province)&&(identical(other.incomeBracket, incomeBracket) || other.incomeBracket == incomeBracket)&&(identical(other.isWorkingStudent, isWorkingStudent) || other.isWorkingStudent == isWorkingStudent)&&(identical(other.isPwd, isPwd) || other.isPwd == isPwd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,email,yearLevel,course,gpa,citizenship,region,province,incomeBracket,isWorkingStudent,isPwd,createdAt,updatedAt);

@override
String toString() {
  return 'StudentProfile(id: $id, fullName: $fullName, email: $email, yearLevel: $yearLevel, course: $course, gpa: $gpa, citizenship: $citizenship, region: $region, province: $province, incomeBracket: $incomeBracket, isWorkingStudent: $isWorkingStudent, isPwd: $isPwd, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$StudentProfileCopyWith<$Res> implements $StudentProfileCopyWith<$Res> {
  factory _$StudentProfileCopyWith(_StudentProfile value, $Res Function(_StudentProfile) _then) = __$StudentProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, String email, int yearLevel, String course, double gpa, String citizenship, String region, String province, String incomeBracket, bool isWorkingStudent, bool isPwd, DateTime createdAt, DateTime updatedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? yearLevel = null,Object? course = null,Object? gpa = null,Object? citizenship = null,Object? region = null,Object? province = null,Object? incomeBracket = null,Object? isWorkingStudent = null,Object? isPwd = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_StudentProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,yearLevel: null == yearLevel ? _self.yearLevel : yearLevel // ignore: cast_nullable_to_non_nullable
as int,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as String,gpa: null == gpa ? _self.gpa : gpa // ignore: cast_nullable_to_non_nullable
as double,citizenship: null == citizenship ? _self.citizenship : citizenship // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,province: null == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String,incomeBracket: null == incomeBracket ? _self.incomeBracket : incomeBracket // ignore: cast_nullable_to_non_nullable
as String,isWorkingStudent: null == isWorkingStudent ? _self.isWorkingStudent : isWorkingStudent // ignore: cast_nullable_to_non_nullable
as bool,isPwd: null == isPwd ? _self.isPwd : isPwd // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
