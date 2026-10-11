// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QueueEntry {

 String get id; String get queueId; String get userId; String get serviceId; int get tokenNumber; QueueEntryStatus get status; int get priority; DateTime get joinedAt; DateTime? get calledAt; DateTime? get serviceStartedAt; DateTime? get completedAt; String? get counterId; int? get estimatedWaitMinutes; String? get userName; String? get serviceName; String? get counterName;
/// Create a copy of QueueEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueEntryCopyWith<QueueEntry> get copyWith => _$QueueEntryCopyWithImpl<QueueEntry>(this as QueueEntry, _$identity);

  /// Serializes this QueueEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as QueueEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.queueId, _this.queueId) || other.queueId == _this.queueId)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.serviceId, _this.serviceId) || other.serviceId == _this.serviceId)&&(identical(other.tokenNumber, _this.tokenNumber) || other.tokenNumber == _this.tokenNumber)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.joinedAt, _this.joinedAt) || other.joinedAt == _this.joinedAt)&&(identical(other.calledAt, _this.calledAt) || other.calledAt == _this.calledAt)&&(identical(other.serviceStartedAt, _this.serviceStartedAt) || other.serviceStartedAt == _this.serviceStartedAt)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt)&&(identical(other.counterId, _this.counterId) || other.counterId == _this.counterId)&&(identical(other.estimatedWaitMinutes, _this.estimatedWaitMinutes) || other.estimatedWaitMinutes == _this.estimatedWaitMinutes)&&(identical(other.userName, _this.userName) || other.userName == _this.userName)&&(identical(other.serviceName, _this.serviceName) || other.serviceName == _this.serviceName)&&(identical(other.counterName, _this.counterName) || other.counterName == _this.counterName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as QueueEntry;
  return Object.hash(runtimeType,_this.id,_this.queueId,_this.userId,_this.serviceId,_this.tokenNumber,_this.status,_this.priority,_this.joinedAt,_this.calledAt,_this.serviceStartedAt,_this.completedAt,_this.counterId,_this.estimatedWaitMinutes,_this.userName,_this.serviceName,_this.counterName);
}

@override
String toString() {
  final _this = this as QueueEntry;
  return 'QueueEntry(id: ${_this.id}, queueId: ${_this.queueId}, userId: ${_this.userId}, serviceId: ${_this.serviceId}, tokenNumber: ${_this.tokenNumber}, status: ${_this.status}, priority: ${_this.priority}, joinedAt: ${_this.joinedAt}, calledAt: ${_this.calledAt}, serviceStartedAt: ${_this.serviceStartedAt}, completedAt: ${_this.completedAt}, counterId: ${_this.counterId}, estimatedWaitMinutes: ${_this.estimatedWaitMinutes}, userName: ${_this.userName}, serviceName: ${_this.serviceName}, counterName: ${_this.counterName})';
}


}

/// @nodoc
abstract mixin class $QueueEntryCopyWith<$Res>  {
  factory $QueueEntryCopyWith(QueueEntry value, $Res Function(QueueEntry) _then) = _$QueueEntryCopyWithImpl;
@useResult
$Res call({
 String id, String queueId, String userId, String serviceId, int tokenNumber, QueueEntryStatus status, int priority, DateTime joinedAt, DateTime? calledAt, DateTime? serviceStartedAt, DateTime? completedAt, String? counterId, int? estimatedWaitMinutes, String? userName, String? serviceName, String? counterName
});




}
/// @nodoc
class _$QueueEntryCopyWithImpl<$Res>
    implements $QueueEntryCopyWith<$Res> {
  _$QueueEntryCopyWithImpl(this._self, this._then);

  final QueueEntry _self;
  final $Res Function(QueueEntry) _then;

/// Create a copy of QueueEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? queueId = null,Object? userId = null,Object? serviceId = null,Object? tokenNumber = null,Object? status = null,Object? priority = null,Object? joinedAt = null,Object? calledAt = freezed,Object? serviceStartedAt = freezed,Object? completedAt = freezed,Object? counterId = freezed,Object? estimatedWaitMinutes = freezed,Object? userName = freezed,Object? serviceName = freezed,Object? counterName = freezed,}) {
  return _then(QueueEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,queueId: null == queueId ? _self.queueId : queueId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,tokenNumber: null == tokenNumber ? _self.tokenNumber : tokenNumber // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QueueEntryStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,calledAt: freezed == calledAt ? _self.calledAt : calledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serviceStartedAt: freezed == serviceStartedAt ? _self.serviceStartedAt : serviceStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,counterId: freezed == counterId ? _self.counterId : counterId // ignore: cast_nullable_to_non_nullable
as String?,estimatedWaitMinutes: freezed == estimatedWaitMinutes ? _self.estimatedWaitMinutes : estimatedWaitMinutes // ignore: cast_nullable_to_non_nullable
as int?,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String?,counterName: freezed == counterName ? _self.counterName : counterName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueEntry].
extension QueueEntryPatterns on QueueEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueEntry value)  $default,){
final _that = this;
switch (_that) {
case _QueueEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueEntry value)?  $default,){
final _that = this;
switch (_that) {
case _QueueEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String queueId,  String userId,  String serviceId,  int tokenNumber,  QueueEntryStatus status,  int priority,  DateTime joinedAt,  DateTime? calledAt,  DateTime? serviceStartedAt,  DateTime? completedAt,  String? counterId,  int? estimatedWaitMinutes,  String? userName,  String? serviceName,  String? counterName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueEntry() when $default != null:
return $default(_that.id,_that.queueId,_that.userId,_that.serviceId,_that.tokenNumber,_that.status,_that.priority,_that.joinedAt,_that.calledAt,_that.serviceStartedAt,_that.completedAt,_that.counterId,_that.estimatedWaitMinutes,_that.userName,_that.serviceName,_that.counterName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String queueId,  String userId,  String serviceId,  int tokenNumber,  QueueEntryStatus status,  int priority,  DateTime joinedAt,  DateTime? calledAt,  DateTime? serviceStartedAt,  DateTime? completedAt,  String? counterId,  int? estimatedWaitMinutes,  String? userName,  String? serviceName,  String? counterName)  $default,) {final _that = this;
switch (_that) {
case _QueueEntry():
return $default(_that.id,_that.queueId,_that.userId,_that.serviceId,_that.tokenNumber,_that.status,_that.priority,_that.joinedAt,_that.calledAt,_that.serviceStartedAt,_that.completedAt,_that.counterId,_that.estimatedWaitMinutes,_that.userName,_that.serviceName,_that.counterName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String queueId,  String userId,  String serviceId,  int tokenNumber,  QueueEntryStatus status,  int priority,  DateTime joinedAt,  DateTime? calledAt,  DateTime? serviceStartedAt,  DateTime? completedAt,  String? counterId,  int? estimatedWaitMinutes,  String? userName,  String? serviceName,  String? counterName)?  $default,) {final _that = this;
switch (_that) {
case _QueueEntry() when $default != null:
return $default(_that.id,_that.queueId,_that.userId,_that.serviceId,_that.tokenNumber,_that.status,_that.priority,_that.joinedAt,_that.calledAt,_that.serviceStartedAt,_that.completedAt,_that.counterId,_that.estimatedWaitMinutes,_that.userName,_that.serviceName,_that.counterName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueEntry implements QueueEntry {
  const _QueueEntry({required this.id, required this.queueId, required this.userId, required this.serviceId, required this.tokenNumber, required this.status, this.priority = 0, required this.joinedAt, this.calledAt, this.serviceStartedAt, this.completedAt, this.counterId, this.estimatedWaitMinutes, this.userName, this.serviceName, this.counterName});
  factory _QueueEntry.fromJson(Map<String, dynamic> json) => _$QueueEntryFromJson(json);

@override final  String id;
@override final  String queueId;
@override final  String userId;
@override final  String serviceId;
@override final  int tokenNumber;
@override final  QueueEntryStatus status;
@override@JsonKey() final  int priority;
@override final  DateTime joinedAt;
@override final  DateTime? calledAt;
@override final  DateTime? serviceStartedAt;
@override final  DateTime? completedAt;
@override final  String? counterId;
@override final  int? estimatedWaitMinutes;
@override final  String? userName;
@override final  String? serviceName;
@override final  String? counterName;

/// Create a copy of QueueEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueEntryCopyWith<_QueueEntry> get copyWith => __$QueueEntryCopyWithImpl<_QueueEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.queueId, queueId) || other.queueId == queueId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.tokenNumber, tokenNumber) || other.tokenNumber == tokenNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.calledAt, calledAt) || other.calledAt == calledAt)&&(identical(other.serviceStartedAt, serviceStartedAt) || other.serviceStartedAt == serviceStartedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.counterId, counterId) || other.counterId == counterId)&&(identical(other.estimatedWaitMinutes, estimatedWaitMinutes) || other.estimatedWaitMinutes == estimatedWaitMinutes)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.counterName, counterName) || other.counterName == counterName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,queueId,userId,serviceId,tokenNumber,status,priority,joinedAt,calledAt,serviceStartedAt,completedAt,counterId,estimatedWaitMinutes,userName,serviceName,counterName);
}

@override
String toString() {
    return 'QueueEntry(id: $id, queueId: $queueId, userId: $userId, serviceId: $serviceId, tokenNumber: $tokenNumber, status: $status, priority: $priority, joinedAt: $joinedAt, calledAt: $calledAt, serviceStartedAt: $serviceStartedAt, completedAt: $completedAt, counterId: $counterId, estimatedWaitMinutes: $estimatedWaitMinutes, userName: $userName, serviceName: $serviceName, counterName: $counterName)';
}


}

/// @nodoc
abstract mixin class _$QueueEntryCopyWith<$Res> implements $QueueEntryCopyWith<$Res> {
  factory _$QueueEntryCopyWith(_QueueEntry value, $Res Function(_QueueEntry) _then) = __$QueueEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String queueId, String userId, String serviceId, int tokenNumber, QueueEntryStatus status, int priority, DateTime joinedAt, DateTime? calledAt, DateTime? serviceStartedAt, DateTime? completedAt, String? counterId, int? estimatedWaitMinutes, String? userName, String? serviceName, String? counterName
});




}
/// @nodoc
class __$QueueEntryCopyWithImpl<$Res>
    implements _$QueueEntryCopyWith<$Res> {
  __$QueueEntryCopyWithImpl(this._self, this._then);

  final _QueueEntry _self;
  final $Res Function(_QueueEntry) _then;

/// Create a copy of QueueEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? queueId = null,Object? userId = null,Object? serviceId = null,Object? tokenNumber = null,Object? status = null,Object? priority = null,Object? joinedAt = null,Object? calledAt = freezed,Object? serviceStartedAt = freezed,Object? completedAt = freezed,Object? counterId = freezed,Object? estimatedWaitMinutes = freezed,Object? userName = freezed,Object? serviceName = freezed,Object? counterName = freezed,}) {
  return _then(_QueueEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,queueId: null == queueId ? _self.queueId : queueId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,tokenNumber: null == tokenNumber ? _self.tokenNumber : tokenNumber // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QueueEntryStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,calledAt: freezed == calledAt ? _self.calledAt : calledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serviceStartedAt: freezed == serviceStartedAt ? _self.serviceStartedAt : serviceStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,counterId: freezed == counterId ? _self.counterId : counterId // ignore: cast_nullable_to_non_nullable
as String?,estimatedWaitMinutes: freezed == estimatedWaitMinutes ? _self.estimatedWaitMinutes : estimatedWaitMinutes // ignore: cast_nullable_to_non_nullable
as int?,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String?,counterName: freezed == counterName ? _self.counterName : counterName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
