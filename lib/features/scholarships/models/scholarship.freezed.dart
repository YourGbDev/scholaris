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

 String get id; String get name; String? get provider; String? get description;@JsonKey(name: 'min_gpa') double get minGpa;@JsonKey(name: 'year_levels') List<int> get yearLevels;@JsonKey(name: 'eligible_courses') List<String> get eligibleCourses;@JsonKey(name: 'citizenship_required') String get citizenshipRequired;@JsonKey(name: 'regions_eligible') List<String> get regionsEligible;@JsonKey(name: 'max_income_bracket') String get maxIncomeBracket;@JsonKey(name: 'is_pwd_priority') bool get isPwdPriority;@JsonKey(name: 'is_working_student_priority') bool get isWorkingStudentPriority;@JsonKey(name: 'slots_available') int? get slotsAvailable;@JsonKey(name: 'deadline', fromJson: _dateFromJson) DateTime get deadline; double get amount;@JsonKey(name: 'coverage_type') String? get coverageType;@JsonKey(name: 'tags') List<String> get tags;@JsonKey(name: 'is_active') bool get isActive;
/// Create a copy of Scholarship
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScholarshipCopyWith<Scholarship> get copyWith => _$ScholarshipCopyWithImpl<Scholarship>(this as Scholarship, _$identity);

  /// Serializes this Scholarship to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Scholarship&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.description, description) || other.description == description)&&(identical(other.minGpa, minGpa) || other.minGpa == minGpa)&&const DeepCollectionEquality().equals(other.yearLevels, yearLevels)&&const DeepCollectionEquality().equals(other.eligibleCourses, eligibleCourses)&&(identical(other.citizenshipRequired, citizenshipRequired) || other.citizenshipRequired == citizenshipRequired)&&const DeepCollectionEquality().equals(other.regionsEligible, regionsEligible)&&(identical(other.maxIncomeBracket, maxIncomeBracket) || other.maxIncomeBracket == maxIncomeBracket)&&(identical(other.isPwdPriority, isPwdPriority) || other.isPwdPriority == isPwdPriority)&&(identical(other.isWorkingStudentPriority, isWorkingStudentPriority) || other.isWorkingStudentPriority == isWorkingStudentPriority)&&(identical(other.slotsAvailable, slotsAvailable) || other.slotsAvailable == slotsAvailable)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.coverageType, coverageType) || other.coverageType == coverageType)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,provider,description,minGpa,const DeepCollectionEquality().hash(yearLevels),const DeepCollectionEquality().hash(eligibleCourses),citizenshipRequired,const DeepCollectionEquality().hash(regionsEligible),maxIncomeBracket,isPwdPriority,isWorkingStudentPriority,slotsAvailable,deadline,amount,coverageType,const DeepCollectionEquality().hash(tags),isActive);

@override
String toString() {
  return 'Scholarship(id: $id, name: $name, provider: $provider, description: $description, minGpa: $minGpa, yearLevels: $yearLevels, eligibleCourses: $eligibleCourses, citizenshipRequired: $citizenshipRequired, regionsEligible: $regionsEligible, maxIncomeBracket: $maxIncomeBracket, isPwdPriority: $isPwdPriority, isWorkingStudentPriority: $isWorkingStudentPriority, slotsAvailable: $slotsAvailable, deadline: $deadline, amount: $amount, coverageType: $coverageType, tags: $tags, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $ScholarshipCopyWith<$Res>  {
  factory $ScholarshipCopyWith(Scholarship value, $Res Function(Scholarship) _then) = _$ScholarshipCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? provider, String? description,@JsonKey(name: 'min_gpa') double minGpa,@JsonKey(name: 'year_levels') List<int> yearLevels,@JsonKey(name: 'eligible_courses') List<String> eligibleCourses,@JsonKey(name: 'citizenship_required') String citizenshipRequired,@JsonKey(name: 'regions_eligible') List<String> regionsEligible,@JsonKey(name: 'max_income_bracket') String maxIncomeBracket,@JsonKey(name: 'is_pwd_priority') bool isPwdPriority,@JsonKey(name: 'is_working_student_priority') bool isWorkingStudentPriority,@JsonKey(name: 'slots_available') int? slotsAvailable,@JsonKey(name: 'deadline', fromJson: _dateFromJson) DateTime deadline, double amount,@JsonKey(name: 'coverage_type') String? coverageType,@JsonKey(name: 'tags') List<String> tags,@JsonKey(name: 'is_active') bool isActive
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? provider = freezed,Object? description = freezed,Object? minGpa = null,Object? yearLevels = null,Object? eligibleCourses = null,Object? citizenshipRequired = null,Object? regionsEligible = null,Object? maxIncomeBracket = null,Object? isPwdPriority = null,Object? isWorkingStudentPriority = null,Object? slotsAvailable = freezed,Object? deadline = null,Object? amount = null,Object? coverageType = freezed,Object? tags = null,Object? isActive = null,}) {
  return _then(Scholarship(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,minGpa: null == minGpa ? _self.minGpa : minGpa // ignore: cast_nullable_to_non_nullable
as double,yearLevels: null == yearLevels ? _self.yearLevels : yearLevels // ignore: cast_nullable_to_non_nullable
as List<int>,eligibleCourses: null == eligibleCourses ? _self.eligibleCourses : eligibleCourses // ignore: cast_nullable_to_non_nullable
as List<String>,citizenshipRequired: null == citizenshipRequired ? _self.citizenshipRequired : citizenshipRequired // ignore: cast_nullable_to_non_nullable
as String,regionsEligible: null == regionsEligible ? _self.regionsEligible : regionsEligible // ignore: cast_nullable_to_non_nullable
as List<String>,maxIncomeBracket: null == maxIncomeBracket ? _self.maxIncomeBracket : maxIncomeBracket // ignore: cast_nullable_to_non_nullable
as String,isPwdPriority: null == isPwdPriority ? _self.isPwdPriority : isPwdPriority // ignore: cast_nullable_to_non_nullable
as bool,isWorkingStudentPriority: null == isWorkingStudentPriority ? _self.isWorkingStudentPriority : isWorkingStudentPriority // ignore: cast_nullable_to_non_nullable
as bool,slotsAvailable: freezed == slotsAvailable ? _self.slotsAvailable : slotsAvailable // ignore: cast_nullable_to_non_nullable
as int?,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,coverageType: freezed == coverageType ? _self.coverageType : coverageType // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? provider,  String? description, @JsonKey(name: 'min_gpa')  double minGpa, @JsonKey(name: 'year_levels')  List<int> yearLevels, @JsonKey(name: 'eligible_courses')  List<String> eligibleCourses, @JsonKey(name: 'citizenship_required')  String citizenshipRequired, @JsonKey(name: 'regions_eligible')  List<String> regionsEligible, @JsonKey(name: 'max_income_bracket')  String maxIncomeBracket, @JsonKey(name: 'is_pwd_priority')  bool isPwdPriority, @JsonKey(name: 'is_working_student_priority')  bool isWorkingStudentPriority, @JsonKey(name: 'slots_available')  int? slotsAvailable, @JsonKey(name: 'deadline', fromJson: _dateFromJson)  DateTime deadline,  double amount, @JsonKey(name: 'coverage_type')  String? coverageType, @JsonKey(name: 'tags')  List<String> tags, @JsonKey(name: 'is_active')  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Scholarship() when $default != null:
return $default(_that.id,_that.name,_that.provider,_that.description,_that.minGpa,_that.yearLevels,_that.eligibleCourses,_that.citizenshipRequired,_that.regionsEligible,_that.maxIncomeBracket,_that.isPwdPriority,_that.isWorkingStudentPriority,_that.slotsAvailable,_that.deadline,_that.amount,_that.coverageType,_that.tags,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? provider,  String? description, @JsonKey(name: 'min_gpa')  double minGpa, @JsonKey(name: 'year_levels')  List<int> yearLevels, @JsonKey(name: 'eligible_courses')  List<String> eligibleCourses, @JsonKey(name: 'citizenship_required')  String citizenshipRequired, @JsonKey(name: 'regions_eligible')  List<String> regionsEligible, @JsonKey(name: 'max_income_bracket')  String maxIncomeBracket, @JsonKey(name: 'is_pwd_priority')  bool isPwdPriority, @JsonKey(name: 'is_working_student_priority')  bool isWorkingStudentPriority, @JsonKey(name: 'slots_available')  int? slotsAvailable, @JsonKey(name: 'deadline', fromJson: _dateFromJson)  DateTime deadline,  double amount, @JsonKey(name: 'coverage_type')  String? coverageType, @JsonKey(name: 'tags')  List<String> tags, @JsonKey(name: 'is_active')  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _Scholarship():
return $default(_that.id,_that.name,_that.provider,_that.description,_that.minGpa,_that.yearLevels,_that.eligibleCourses,_that.citizenshipRequired,_that.regionsEligible,_that.maxIncomeBracket,_that.isPwdPriority,_that.isWorkingStudentPriority,_that.slotsAvailable,_that.deadline,_that.amount,_that.coverageType,_that.tags,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? provider,  String? description, @JsonKey(name: 'min_gpa')  double minGpa, @JsonKey(name: 'year_levels')  List<int> yearLevels, @JsonKey(name: 'eligible_courses')  List<String> eligibleCourses, @JsonKey(name: 'citizenship_required')  String citizenshipRequired, @JsonKey(name: 'regions_eligible')  List<String> regionsEligible, @JsonKey(name: 'max_income_bracket')  String maxIncomeBracket, @JsonKey(name: 'is_pwd_priority')  bool isPwdPriority, @JsonKey(name: 'is_working_student_priority')  bool isWorkingStudentPriority, @JsonKey(name: 'slots_available')  int? slotsAvailable, @JsonKey(name: 'deadline', fromJson: _dateFromJson)  DateTime deadline,  double amount, @JsonKey(name: 'coverage_type')  String? coverageType, @JsonKey(name: 'tags')  List<String> tags, @JsonKey(name: 'is_active')  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _Scholarship() when $default != null:
return $default(_that.id,_that.name,_that.provider,_that.description,_that.minGpa,_that.yearLevels,_that.eligibleCourses,_that.citizenshipRequired,_that.regionsEligible,_that.maxIncomeBracket,_that.isPwdPriority,_that.isWorkingStudentPriority,_that.slotsAvailable,_that.deadline,_that.amount,_that.coverageType,_that.tags,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Scholarship implements Scholarship {
  const _Scholarship({required this.id, required this.name, this.provider, this.description, @JsonKey(name: 'min_gpa') required this.minGpa, @JsonKey(name: 'year_levels')  List<int> yearLevels = const [1, 2, 3, 4, 5], @JsonKey(name: 'eligible_courses')  List<String> eligibleCourses = const [], @JsonKey(name: 'citizenship_required') this.citizenshipRequired = 'any', @JsonKey(name: 'regions_eligible')  List<String> regionsEligible = const [], @JsonKey(name: 'max_income_bracket') this.maxIncomeBracket = 'any', @JsonKey(name: 'is_pwd_priority') this.isPwdPriority = false, @JsonKey(name: 'is_working_student_priority') this.isWorkingStudentPriority = false, @JsonKey(name: 'slots_available') this.slotsAvailable, @JsonKey(name: 'deadline', fromJson: _dateFromJson) required this.deadline, required this.amount, @JsonKey(name: 'coverage_type') this.coverageType, @JsonKey(name: 'tags')  List<String> tags = const [], @JsonKey(name: 'is_active') this.isActive = true}): _yearLevels = yearLevels,_eligibleCourses = eligibleCourses,_regionsEligible = regionsEligible,_tags = tags;
  factory _Scholarship.fromJson(Map<String, dynamic> json) => _$ScholarshipFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? provider;
@override final  String? description;
@override@JsonKey(name: 'min_gpa') final  double minGpa;
 final  List<int> _yearLevels;
@override@JsonKey(name: 'year_levels') List<int> get yearLevels {
  if (_yearLevels is EqualUnmodifiableListView) return _yearLevels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_yearLevels);
}

 final  List<String> _eligibleCourses;
@override@JsonKey(name: 'eligible_courses') List<String> get eligibleCourses {
  if (_eligibleCourses is EqualUnmodifiableListView) return _eligibleCourses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_eligibleCourses);
}

@override@JsonKey(name: 'citizenship_required') final  String citizenshipRequired;
 final  List<String> _regionsEligible;
@override@JsonKey(name: 'regions_eligible') List<String> get regionsEligible {
  if (_regionsEligible is EqualUnmodifiableListView) return _regionsEligible;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_regionsEligible);
}

@override@JsonKey(name: 'max_income_bracket') final  String maxIncomeBracket;
@override@JsonKey(name: 'is_pwd_priority') final  bool isPwdPriority;
@override@JsonKey(name: 'is_working_student_priority') final  bool isWorkingStudentPriority;
@override@JsonKey(name: 'slots_available') final  int? slotsAvailable;
@override@JsonKey(name: 'deadline', fromJson: _dateFromJson) final  DateTime deadline;
@override final  double amount;
@override@JsonKey(name: 'coverage_type') final  String? coverageType;
 final  List<String> _tags;
@override@JsonKey(name: 'tags') List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey(name: 'is_active') final  bool isActive;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Scholarship&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.description, description) || other.description == description)&&(identical(other.minGpa, minGpa) || other.minGpa == minGpa)&&const DeepCollectionEquality().equals(other._yearLevels, _yearLevels)&&const DeepCollectionEquality().equals(other._eligibleCourses, _eligibleCourses)&&(identical(other.citizenshipRequired, citizenshipRequired) || other.citizenshipRequired == citizenshipRequired)&&const DeepCollectionEquality().equals(other._regionsEligible, _regionsEligible)&&(identical(other.maxIncomeBracket, maxIncomeBracket) || other.maxIncomeBracket == maxIncomeBracket)&&(identical(other.isPwdPriority, isPwdPriority) || other.isPwdPriority == isPwdPriority)&&(identical(other.isWorkingStudentPriority, isWorkingStudentPriority) || other.isWorkingStudentPriority == isWorkingStudentPriority)&&(identical(other.slotsAvailable, slotsAvailable) || other.slotsAvailable == slotsAvailable)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.coverageType, coverageType) || other.coverageType == coverageType)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,provider,description,minGpa,const DeepCollectionEquality().hash(_yearLevels),const DeepCollectionEquality().hash(_eligibleCourses),citizenshipRequired,const DeepCollectionEquality().hash(_regionsEligible),maxIncomeBracket,isPwdPriority,isWorkingStudentPriority,slotsAvailable,deadline,amount,coverageType,const DeepCollectionEquality().hash(_tags),isActive);

@override
String toString() {
  return 'Scholarship(id: $id, name: $name, provider: $provider, description: $description, minGpa: $minGpa, yearLevels: $yearLevels, eligibleCourses: $eligibleCourses, citizenshipRequired: $citizenshipRequired, regionsEligible: $regionsEligible, maxIncomeBracket: $maxIncomeBracket, isPwdPriority: $isPwdPriority, isWorkingStudentPriority: $isWorkingStudentPriority, slotsAvailable: $slotsAvailable, deadline: $deadline, amount: $amount, coverageType: $coverageType, tags: $tags, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$ScholarshipCopyWith<$Res> implements $ScholarshipCopyWith<$Res> {
  factory _$ScholarshipCopyWith(_Scholarship value, $Res Function(_Scholarship) _then) = __$ScholarshipCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? provider, String? description,@JsonKey(name: 'min_gpa') double minGpa,@JsonKey(name: 'year_levels') List<int> yearLevels,@JsonKey(name: 'eligible_courses') List<String> eligibleCourses,@JsonKey(name: 'citizenship_required') String citizenshipRequired,@JsonKey(name: 'regions_eligible') List<String> regionsEligible,@JsonKey(name: 'max_income_bracket') String maxIncomeBracket,@JsonKey(name: 'is_pwd_priority') bool isPwdPriority,@JsonKey(name: 'is_working_student_priority') bool isWorkingStudentPriority,@JsonKey(name: 'slots_available') int? slotsAvailable,@JsonKey(name: 'deadline', fromJson: _dateFromJson) DateTime deadline, double amount,@JsonKey(name: 'coverage_type') String? coverageType,@JsonKey(name: 'tags') List<String> tags,@JsonKey(name: 'is_active') bool isActive
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? provider = freezed,Object? description = freezed,Object? minGpa = null,Object? yearLevels = null,Object? eligibleCourses = null,Object? citizenshipRequired = null,Object? regionsEligible = null,Object? maxIncomeBracket = null,Object? isPwdPriority = null,Object? isWorkingStudentPriority = null,Object? slotsAvailable = freezed,Object? deadline = null,Object? amount = null,Object? coverageType = freezed,Object? tags = null,Object? isActive = null,}) {
  return _then(_Scholarship(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,minGpa: null == minGpa ? _self.minGpa : minGpa // ignore: cast_nullable_to_non_nullable
as double,yearLevels: null == yearLevels ? _self._yearLevels : yearLevels // ignore: cast_nullable_to_non_nullable
as List<int>,eligibleCourses: null == eligibleCourses ? _self._eligibleCourses : eligibleCourses // ignore: cast_nullable_to_non_nullable
as List<String>,citizenshipRequired: null == citizenshipRequired ? _self.citizenshipRequired : citizenshipRequired // ignore: cast_nullable_to_non_nullable
as String,regionsEligible: null == regionsEligible ? _self._regionsEligible : regionsEligible // ignore: cast_nullable_to_non_nullable
as List<String>,maxIncomeBracket: null == maxIncomeBracket ? _self.maxIncomeBracket : maxIncomeBracket // ignore: cast_nullable_to_non_nullable
as String,isPwdPriority: null == isPwdPriority ? _self.isPwdPriority : isPwdPriority // ignore: cast_nullable_to_non_nullable
as bool,isWorkingStudentPriority: null == isWorkingStudentPriority ? _self.isWorkingStudentPriority : isWorkingStudentPriority // ignore: cast_nullable_to_non_nullable
as bool,slotsAvailable: freezed == slotsAvailable ? _self.slotsAvailable : slotsAvailable // ignore: cast_nullable_to_non_nullable
as int?,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,coverageType: freezed == coverageType ? _self.coverageType : coverageType // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
