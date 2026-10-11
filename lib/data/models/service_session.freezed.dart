// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceSession {

 String get id; String get queueEntryId; String get counterId; String get staffId; String get serviceId; DateTime get startedAt; DateTime? get completedAt; int? get actualDurationMinutes;
/// Create a copy of ServiceSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceSessionCopyWith<ServiceSession> get copyWith => _$ServiceSessionCopyWithImpl<ServiceSession>(this as ServiceSession, _$identity);

  /// Serializes this ServiceSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ServiceSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceSession&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.queueEntryId, _this.queueEntryId) || other.queueEntryId == _this.queueEntryId)&&(identical(other.counterId, _this.counterId) || other.counterId == _this.counterId)&&(identical(other.staffId, _this.staffId) || other.staffId == _this.staffId)&&(identical(other.serviceId, _this.serviceId) || other.serviceId == _this.serviceId)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt)&&(identical(other.actualDurationMinutes, _this.actualDurationMinutes) || other.actualDurationMinutes == _this.actualDurationMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ServiceSession;
  return Object.hash(runtimeType,_this.id,_this.queueEntryId,_this.counterId,_this.staffId,_this.serviceId,_this.startedAt,_this.completedAt,_this.actualDurationMinutes);
}

@override
String toString() {
  final _this = this as ServiceSession;
  return 'ServiceSession(id: ${_this.id}, queueEntryId: ${_this.queueEntryId}, counterId: ${_this.counterId}, staffId: ${_this.staffId}, serviceId: ${_this.serviceId}, startedAt: ${_this.startedAt}, completedAt: ${_this.completedAt}, actualDurationMinutes: ${_this.actualDurationMinutes})';
}


}

/// @nodoc
abstract mixin class $ServiceSessionCopyWith<$Res>  {
  factory $ServiceSessionCopyWith(ServiceSession value, $Res Function(ServiceSession) _then) = _$ServiceSessionCopyWithImpl;
@useResult
$Res call({
 String id, String queueEntryId, String counterId, String staffId, String serviceId, DateTime startedAt, DateTime? completedAt, int? actualDurationMinutes
});




}
/// @nodoc
class _$ServiceSessionCopyWithImpl<$Res>
    implements $ServiceSessionCopyWith<$Res> {
  _$ServiceSessionCopyWithImpl(this._self, this._then);

  final ServiceSession _self;
  final $Res Function(ServiceSession) _then;

/// Create a copy of ServiceSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? queueEntryId = null,Object? counterId = null,Object? staffId = null,Object? serviceId = null,Object? startedAt = null,Object? completedAt = freezed,Object? actualDurationMinutes = freezed,}) {
  return _then(ServiceSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,queueEntryId: null == queueEntryId ? _self.queueEntryId : queueEntryId // ignore: cast_nullable_to_non_nullable
as String,counterId: null == counterId ? _self.counterId : counterId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,actualDurationMinutes: freezed == actualDurationMinutes ? _self.actualDurationMinutes : actualDurationMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceSession].
extension ServiceSessionPatterns on ServiceSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceSession value)  $default,){
final _that = this;
switch (_that) {
case _ServiceSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceSession value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String queueEntryId,  String counterId,  String staffId,  String serviceId,  DateTime startedAt,  DateTime? completedAt,  int? actualDurationMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceSession() when $default != null:
return $default(_that.id,_that.queueEntryId,_that.counterId,_that.staffId,_that.serviceId,_that.startedAt,_that.completedAt,_that.actualDurationMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String queueEntryId,  String counterId,  String staffId,  String serviceId,  DateTime startedAt,  DateTime? completedAt,  int? actualDurationMinutes)  $default,) {final _that = this;
switch (_that) {
case _ServiceSession():
return $default(_that.id,_that.queueEntryId,_that.counterId,_that.staffId,_that.serviceId,_that.startedAt,_that.completedAt,_that.actualDurationMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String queueEntryId,  String counterId,  String staffId,  String serviceId,  DateTime startedAt,  DateTime? completedAt,  int? actualDurationMinutes)?  $default,) {final _that = this;
switch (_that) {
case _ServiceSession() when $default != null:
return $default(_that.id,_that.queueEntryId,_that.counterId,_that.staffId,_that.serviceId,_that.startedAt,_that.completedAt,_that.actualDurationMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceSession implements ServiceSession {
  const _ServiceSession({required this.id, required this.queueEntryId, required this.counterId, required this.staffId, required this.serviceId, required this.startedAt, this.completedAt, this.actualDurationMinutes});
  factory _ServiceSession.fromJson(Map<String, dynamic> json) => _$ServiceSessionFromJson(json);

@override final  String id;
@override final  String queueEntryId;
@override final  String counterId;
@override final  String staffId;
@override final  String serviceId;
@override final  DateTime startedAt;
@override final  DateTime? completedAt;
@override final  int? actualDurationMinutes;

/// Create a copy of ServiceSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceSessionCopyWith<_ServiceSession> get copyWith => __$ServiceSessionCopyWithImpl<_ServiceSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceSessionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceSession&&(identical(other.id, id) || other.id == id)&&(identical(other.queueEntryId, queueEntryId) || other.queueEntryId == queueEntryId)&&(identical(other.counterId, counterId) || other.counterId == counterId)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.actualDurationMinutes, actualDurationMinutes) || other.actualDurationMinutes == actualDurationMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,queueEntryId,counterId,staffId,serviceId,startedAt,completedAt,actualDurationMinutes);
}

@override
String toString() {
    return 'ServiceSession(id: $id, queueEntryId: $queueEntryId, counterId: $counterId, staffId: $staffId, serviceId: $serviceId, startedAt: $startedAt, completedAt: $completedAt, actualDurationMinutes: $actualDurationMinutes)';
}


}

/// @nodoc
abstract mixin class _$ServiceSessionCopyWith<$Res> implements $ServiceSessionCopyWith<$Res> {
  factory _$ServiceSessionCopyWith(_ServiceSession value, $Res Function(_ServiceSession) _then) = __$ServiceSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String queueEntryId, String counterId, String staffId, String serviceId, DateTime startedAt, DateTime? completedAt, int? actualDurationMinutes
});




}
/// @nodoc
class __$ServiceSessionCopyWithImpl<$Res>
    implements _$ServiceSessionCopyWith<$Res> {
  __$ServiceSessionCopyWithImpl(this._self, this._then);

  final _ServiceSession _self;
  final $Res Function(_ServiceSession) _then;

/// Create a copy of ServiceSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? queueEntryId = null,Object? counterId = null,Object? staffId = null,Object? serviceId = null,Object? startedAt = null,Object? completedAt = freezed,Object? actualDurationMinutes = freezed,}) {
  return _then(_ServiceSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,queueEntryId: null == queueEntryId ? _self.queueEntryId : queueEntryId // ignore: cast_nullable_to_non_nullable
as String,counterId: null == counterId ? _self.counterId : counterId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,actualDurationMinutes: freezed == actualDurationMinutes ? _self.actualDurationMinutes : actualDurationMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
