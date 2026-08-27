// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Application {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'scholarship_id') String get scholarshipId;@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) ApplicationStatus get status; String? get notes;@JsonKey(name: 'applied_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime? get appliedAt;@JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime? get updatedAt;
/// Create a copy of Application
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApplicationCopyWith<Application> get copyWith => _$ApplicationCopyWithImpl<Application>(this as Application, _$identity);

  /// Serializes this Application to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Application&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.scholarshipId, scholarshipId) || other.scholarshipId == scholarshipId)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.appliedAt, appliedAt) || other.appliedAt == appliedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,scholarshipId,status,notes,appliedAt,updatedAt);

@override
String toString() {
  return 'Application(id: $id, userId: $userId, scholarshipId: $scholarshipId, status: $status, notes: $notes, appliedAt: $appliedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ApplicationCopyWith<$Res>  {
  factory $ApplicationCopyWith(Application value, $Res Function(Application) _then) = _$ApplicationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'scholarship_id') String scholarshipId,@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) ApplicationStatus status, String? notes,@JsonKey(name: 'applied_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime? appliedAt,@JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime? updatedAt
});




}
/// @nodoc
class _$ApplicationCopyWithImpl<$Res>
    implements $ApplicationCopyWith<$Res> {
  _$ApplicationCopyWithImpl(this._self, this._then);

  final Application _self;
  final $Res Function(Application) _then;

/// Create a copy of Application
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? scholarshipId = null,Object? status = null,Object? notes = freezed,Object? appliedAt = freezed,Object? updatedAt = freezed,}) {
  return _then(Application(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,scholarshipId: null == scholarshipId ? _self.scholarshipId : scholarshipId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ApplicationStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,appliedAt: freezed == appliedAt ? _self.appliedAt : appliedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Application].
extension ApplicationPatterns on Application {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Application value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Application() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Application value)  $default,){
final _that = this;
switch (_that) {
case _Application():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Application value)?  $default,){
final _that = this;
switch (_that) {
case _Application() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'scholarship_id')  String scholarshipId, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)  ApplicationStatus status,  String? notes, @JsonKey(name: 'applied_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime? appliedAt, @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Application() when $default != null:
return $default(_that.id,_that.userId,_that.scholarshipId,_that.status,_that.notes,_that.appliedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'scholarship_id')  String scholarshipId, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)  ApplicationStatus status,  String? notes, @JsonKey(name: 'applied_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime? appliedAt, @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Application():
return $default(_that.id,_that.userId,_that.scholarshipId,_that.status,_that.notes,_that.appliedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'scholarship_id')  String scholarshipId, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)  ApplicationStatus status,  String? notes, @JsonKey(name: 'applied_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime? appliedAt, @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Application() when $default != null:
return $default(_that.id,_that.userId,_that.scholarshipId,_that.status,_that.notes,_that.appliedAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Application implements Application {
  const _Application({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'scholarship_id') required this.scholarshipId, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) this.status = ApplicationStatus.draft, this.notes, @JsonKey(name: 'applied_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) this.appliedAt, @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) this.updatedAt});
  factory _Application.fromJson(Map<String, dynamic> json) => _$ApplicationFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'scholarship_id') final  String scholarshipId;
@override@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) final  ApplicationStatus status;
@override final  String? notes;
@override@JsonKey(name: 'applied_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) final  DateTime? appliedAt;
@override@JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) final  DateTime? updatedAt;

/// Create a copy of Application
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplicationCopyWith<_Application> get copyWith => __$ApplicationCopyWithImpl<_Application>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApplicationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Application&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.scholarshipId, scholarshipId) || other.scholarshipId == scholarshipId)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.appliedAt, appliedAt) || other.appliedAt == appliedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,scholarshipId,status,notes,appliedAt,updatedAt);

@override
String toString() {
  return 'Application(id: $id, userId: $userId, scholarshipId: $scholarshipId, status: $status, notes: $notes, appliedAt: $appliedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ApplicationCopyWith<$Res> implements $ApplicationCopyWith<$Res> {
  factory _$ApplicationCopyWith(_Application value, $Res Function(_Application) _then) = __$ApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'scholarship_id') String scholarshipId,@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) ApplicationStatus status, String? notes,@JsonKey(name: 'applied_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime? appliedAt,@JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime? updatedAt
});




}
/// @nodoc
class __$ApplicationCopyWithImpl<$Res>
    implements _$ApplicationCopyWith<$Res> {
  __$ApplicationCopyWithImpl(this._self, this._then);

  final _Application _self;
  final $Res Function(_Application) _then;

/// Create a copy of Application
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? scholarshipId = null,Object? status = null,Object? notes = freezed,Object? appliedAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Application(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,scholarshipId: null == scholarshipId ? _self.scholarshipId : scholarshipId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ApplicationStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,appliedAt: freezed == appliedAt ? _self.appliedAt : appliedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
