// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scholarship.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Scholarship {

 String get id; String get title; String? get provider; String? get description;@JsonKey(name: 'min_gpa') double get minGpa;@JsonKey(name: 'max_monthly_income') double? get maxMonthlyIncome;@JsonKey(name: 'required_year_levels') List<int>? get requiredYearLevels;@JsonKey(name: 'required_courses') List<String>? get requiredCourses;@JsonKey(name: 'location_restriction') String? get locationRestriction;@JsonKey(name: 'for_indigenous') bool? get forIndigenous;@JsonKey(name: 'for_pwd') bool? get forPwd;@JsonKey(name: 'slots') int? get slots;@JsonKey(name: 'deadline', fromJson: _dateFromJson) DateTime get deadline;@JsonKey(name: 'application_url') String? get applicationUrl;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Scholarship
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScholarshipCopyWith<Scholarship> get copyWith => _$ScholarshipCopyWithImpl<Scholarship>(this as Scholarship, _$identity);

  /// Serializes this Scholarship to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Scholarship&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.description, description) || other.description == description)&&(identical(other.minGpa, minGpa) || other.minGpa == minGpa)&&(identical(other.maxMonthlyIncome, maxMonthlyIncome) || other.maxMonthlyIncome == maxMonthlyIncome)&&const DeepCollectionEquality().equals(other.requiredYearLevels, requiredYearLevels)&&const DeepCollectionEquality().equals(other.requiredCourses, requiredCourses)&&(identical(other.locationRestriction, locationRestriction) || other.locationRestriction == locationRestriction)&&(identical(other.forIndigenous, forIndigenous) || other.forIndigenous == forIndigenous)&&(identical(other.forPwd, forPwd) || other.forPwd == forPwd)&&(identical(other.slots, slots) || other.slots == slots)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.applicationUrl, applicationUrl) || other.applicationUrl == applicationUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,provider,description,minGpa,maxMonthlyIncome,const DeepCollectionEquality().hash(requiredYearLevels),const DeepCollectionEquality().hash(requiredCourses),locationRestriction,forIndigenous,forPwd,slots,deadline,applicationUrl,isActive,createdAt);

@override
String toString() {
  return 'Scholarship(id: $id, title: $title, provider: $provider, description: $description, minGpa: $minGpa, maxMonthlyIncome: $maxMonthlyIncome, requiredYearLevels: $requiredYearLevels, requiredCourses: $requiredCourses, locationRestriction: $locationRestriction, forIndigenous: $forIndigenous, forPwd: $forPwd, slots: $slots, deadline: $deadline, applicationUrl: $applicationUrl, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ScholarshipCopyWith<$Res>  {
  factory $ScholarshipCopyWith(Scholarship value, $Res Function(Scholarship) _then) = _$ScholarshipCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? provider, String? description,@JsonKey(name: 'min_gpa') double minGpa,@JsonKey(name: 'max_monthly_income') double? maxMonthlyIncome,@JsonKey(name: 'required_year_levels') List<int>? requiredYearLevels,@JsonKey(name: 'required_courses') List<String>? requiredCourses,@JsonKey(name: 'location_restriction') String? locationRestriction,@JsonKey(name: 'for_indigenous') bool? forIndigenous,@JsonKey(name: 'for_pwd') bool? forPwd,@JsonKey(name: 'slots') int? slots,@JsonKey(name: 'deadline', fromJson: _dateFromJson) DateTime deadline,@JsonKey(name: 'application_url') String? applicationUrl,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$ScholarshipCopyWithImpl<$Res>
    implements $ScholarshipCopyWith<$Res> {
  _$ScholarshipCopyWithImpl(this._self, this._then);

  final Scholarship _self;
  final $Res Function(Scholarship) _then;

/// Create a copy of Scholarship
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? provider = freezed,Object? description = freezed,Object? minGpa = null,Object? maxMonthlyIncome = freezed,Object? requiredYearLevels = freezed,Object? requiredCourses = freezed,Object? locationRestriction = freezed,Object? forIndigenous = freezed,Object? forPwd = freezed,Object? slots = freezed,Object? deadline = null,Object? applicationUrl = freezed,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(Scholarship(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,minGpa: null == minGpa ? _self.minGpa : minGpa // ignore: cast_nullable_to_non_nullable
as double,maxMonthlyIncome: freezed == maxMonthlyIncome ? _self.maxMonthlyIncome : maxMonthlyIncome // ignore: cast_nullable_to_non_nullable
as double?,requiredYearLevels: freezed == requiredYearLevels ? _self.requiredYearLevels : requiredYearLevels // ignore: cast_nullable_to_non_nullable
as List<int>?,requiredCourses: freezed == requiredCourses ? _self.requiredCourses : requiredCourses // ignore: cast_nullable_to_non_nullable
as List<String>?,locationRestriction: freezed == locationRestriction ? _self.locationRestriction : locationRestriction // ignore: cast_nullable_to_non_nullable
as String?,forIndigenous: freezed == forIndigenous ? _self.forIndigenous : forIndigenous // ignore: cast_nullable_to_non_nullable
as bool?,forPwd: freezed == forPwd ? _self.forPwd : forPwd // ignore: cast_nullable_to_non_nullable
as bool?,slots: freezed == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as int?,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,applicationUrl: freezed == applicationUrl ? _self.applicationUrl : applicationUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Scholarship].
extension ScholarshipPatterns on Scholarship {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Scholarship value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Scholarship() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Scholarship value)  $default,){
final _that = this;
switch (_that) {
case _Scholarship():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Scholarship value)?  $default,){
final _that = this;
switch (_that) {
case _Scholarship() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? provider,  String? description, @JsonKey(name: 'min_gpa')  double minGpa, @JsonKey(name: 'max_monthly_income')  double? maxMonthlyIncome, @JsonKey(name: 'required_year_levels')  List<int>? requiredYearLevels, @JsonKey(name: 'required_courses')  List<String>? requiredCourses, @JsonKey(name: 'location_restriction')  String? locationRestriction, @JsonKey(name: 'for_indigenous')  bool? forIndigenous, @JsonKey(name: 'for_pwd')  bool? forPwd, @JsonKey(name: 'slots')  int? slots, @JsonKey(name: 'deadline', fromJson: _dateFromJson)  DateTime deadline, @JsonKey(name: 'application_url')  String? applicationUrl, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Scholarship() when $default != null:
return $default(_that.id,_that.title,_that.provider,_that.description,_that.minGpa,_that.maxMonthlyIncome,_that.requiredYearLevels,_that.requiredCourses,_that.locationRestriction,_that.forIndigenous,_that.forPwd,_that.slots,_that.deadline,_that.applicationUrl,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? provider,  String? description, @JsonKey(name: 'min_gpa')  double minGpa, @JsonKey(name: 'max_monthly_income')  double? maxMonthlyIncome, @JsonKey(name: 'required_year_levels')  List<int>? requiredYearLevels, @JsonKey(name: 'required_courses')  List<String>? requiredCourses, @JsonKey(name: 'location_restriction')  String? locationRestriction, @JsonKey(name: 'for_indigenous')  bool? forIndigenous, @JsonKey(name: 'for_pwd')  bool? forPwd, @JsonKey(name: 'slots')  int? slots, @JsonKey(name: 'deadline', fromJson: _dateFromJson)  DateTime deadline, @JsonKey(name: 'application_url')  String? applicationUrl, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Scholarship():
return $default(_that.id,_that.title,_that.provider,_that.description,_that.minGpa,_that.maxMonthlyIncome,_that.requiredYearLevels,_that.requiredCourses,_that.locationRestriction,_that.forIndigenous,_that.forPwd,_that.slots,_that.deadline,_that.applicationUrl,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? provider,  String? description, @JsonKey(name: 'min_gpa')  double minGpa, @JsonKey(name: 'max_monthly_income')  double? maxMonthlyIncome, @JsonKey(name: 'required_year_levels')  List<int>? requiredYearLevels, @JsonKey(name: 'required_courses')  List<String>? requiredCourses, @JsonKey(name: 'location_restriction')  String? locationRestriction, @JsonKey(name: 'for_indigenous')  bool? forIndigenous, @JsonKey(name: 'for_pwd')  bool? forPwd, @JsonKey(name: 'slots')  int? slots, @JsonKey(name: 'deadline', fromJson: _dateFromJson)  DateTime deadline, @JsonKey(name: 'application_url')  String? applicationUrl, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Scholarship() when $default != null:
return $default(_that.id,_that.title,_that.provider,_that.description,_that.minGpa,_that.maxMonthlyIncome,_that.requiredYearLevels,_that.requiredCourses,_that.locationRestriction,_that.forIndigenous,_that.forPwd,_that.slots,_that.deadline,_that.applicationUrl,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Scholarship implements Scholarship {
  const _Scholarship({required this.id, required this.title, this.provider, this.description, @JsonKey(name: 'min_gpa') required this.minGpa, @JsonKey(name: 'max_monthly_income') this.maxMonthlyIncome, @JsonKey(name: 'required_year_levels')  List<int>? requiredYearLevels, @JsonKey(name: 'required_courses')  List<String>? requiredCourses, @JsonKey(name: 'location_restriction') this.locationRestriction, @JsonKey(name: 'for_indigenous') this.forIndigenous = false, @JsonKey(name: 'for_pwd') this.forPwd = false, @JsonKey(name: 'slots') this.slots, @JsonKey(name: 'deadline', fromJson: _dateFromJson) required this.deadline, @JsonKey(name: 'application_url') this.applicationUrl, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'created_at') this.createdAt}): _requiredYearLevels = requiredYearLevels,_requiredCourses = requiredCourses;
  factory _Scholarship.fromJson(Map<String, dynamic> json) => _$ScholarshipFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? provider;
@override final  String? description;
@override@JsonKey(name: 'min_gpa') final  double minGpa;
@override@JsonKey(name: 'max_monthly_income') final  double? maxMonthlyIncome;
 final  List<int>? _requiredYearLevels;
@override@JsonKey(name: 'required_year_levels') List<int>? get requiredYearLevels {
  final value = _requiredYearLevels;
  if (value == null) return null;
  if (_requiredYearLevels is EqualUnmodifiableListView) return _requiredYearLevels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _requiredCourses;
@override@JsonKey(name: 'required_courses') List<String>? get requiredCourses {
  final value = _requiredCourses;
  if (value == null) return null;
  if (_requiredCourses is EqualUnmodifiableListView) return _requiredCourses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'location_restriction') final  String? locationRestriction;
@override@JsonKey(name: 'for_indigenous') final  bool? forIndigenous;
@override@JsonKey(name: 'for_pwd') final  bool? forPwd;
@override@JsonKey(name: 'slots') final  int? slots;
@override@JsonKey(name: 'deadline', fromJson: _dateFromJson) final  DateTime deadline;
@override@JsonKey(name: 'application_url') final  String? applicationUrl;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Scholarship
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScholarshipCopyWith<_Scholarship> get copyWith => __$ScholarshipCopyWithImpl<_Scholarship>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScholarshipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Scholarship&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.description, description) || other.description == description)&&(identical(other.minGpa, minGpa) || other.minGpa == minGpa)&&(identical(other.maxMonthlyIncome, maxMonthlyIncome) || other.maxMonthlyIncome == maxMonthlyIncome)&&const DeepCollectionEquality().equals(other._requiredYearLevels, _requiredYearLevels)&&const DeepCollectionEquality().equals(other._requiredCourses, _requiredCourses)&&(identical(other.locationRestriction, locationRestriction) || other.locationRestriction == locationRestriction)&&(identical(other.forIndigenous, forIndigenous) || other.forIndigenous == forIndigenous)&&(identical(other.forPwd, forPwd) || other.forPwd == forPwd)&&(identical(other.slots, slots) || other.slots == slots)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.applicationUrl, applicationUrl) || other.applicationUrl == applicationUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,provider,description,minGpa,maxMonthlyIncome,const DeepCollectionEquality().hash(_requiredYearLevels),const DeepCollectionEquality().hash(_requiredCourses),locationRestriction,forIndigenous,forPwd,slots,deadline,applicationUrl,isActive,createdAt);

@override
String toString() {
  return 'Scholarship(id: $id, title: $title, provider: $provider, description: $description, minGpa: $minGpa, maxMonthlyIncome: $maxMonthlyIncome, requiredYearLevels: $requiredYearLevels, requiredCourses: $requiredCourses, locationRestriction: $locationRestriction, forIndigenous: $forIndigenous, forPwd: $forPwd, slots: $slots, deadline: $deadline, applicationUrl: $applicationUrl, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ScholarshipCopyWith<$Res> implements $ScholarshipCopyWith<$Res> {
  factory _$ScholarshipCopyWith(_Scholarship value, $Res Function(_Scholarship) _then) = __$ScholarshipCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? provider, String? description,@JsonKey(name: 'min_gpa') double minGpa,@JsonKey(name: 'max_monthly_income') double? maxMonthlyIncome,@JsonKey(name: 'required_year_levels') List<int>? requiredYearLevels,@JsonKey(name: 'required_courses') List<String>? requiredCourses,@JsonKey(name: 'location_restriction') String? locationRestriction,@JsonKey(name: 'for_indigenous') bool? forIndigenous,@JsonKey(name: 'for_pwd') bool? forPwd,@JsonKey(name: 'slots') int? slots,@JsonKey(name: 'deadline', fromJson: _dateFromJson) DateTime deadline,@JsonKey(name: 'application_url') String? applicationUrl,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$ScholarshipCopyWithImpl<$Res>
    implements _$ScholarshipCopyWith<$Res> {
  __$ScholarshipCopyWithImpl(this._self, this._then);

  final _Scholarship _self;
  final $Res Function(_Scholarship) _then;

/// Create a copy of Scholarship
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? provider = freezed,Object? description = freezed,Object? minGpa = null,Object? maxMonthlyIncome = freezed,Object? requiredYearLevels = freezed,Object? requiredCourses = freezed,Object? locationRestriction = freezed,Object? forIndigenous = freezed,Object? forPwd = freezed,Object? slots = freezed,Object? deadline = null,Object? applicationUrl = freezed,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_Scholarship(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,minGpa: null == minGpa ? _self.minGpa : minGpa // ignore: cast_nullable_to_non_nullable
as double,maxMonthlyIncome: freezed == maxMonthlyIncome ? _self.maxMonthlyIncome : maxMonthlyIncome // ignore: cast_nullable_to_non_nullable
as double?,requiredYearLevels: freezed == requiredYearLevels ? _self._requiredYearLevels : requiredYearLevels // ignore: cast_nullable_to_non_nullable
as List<int>?,requiredCourses: freezed == requiredCourses ? _self._requiredCourses : requiredCourses // ignore: cast_nullable_to_non_nullable
as List<String>?,locationRestriction: freezed == locationRestriction ? _self.locationRestriction : locationRestriction // ignore: cast_nullable_to_non_nullable
as String?,forIndigenous: freezed == forIndigenous ? _self.forIndigenous : forIndigenous // ignore: cast_nullable_to_non_nullable
as bool?,forPwd: freezed == forPwd ? _self.forPwd : forPwd // ignore: cast_nullable_to_non_nullable
as bool?,slots: freezed == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as int?,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,applicationUrl: freezed == applicationUrl ? _self.applicationUrl : applicationUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
