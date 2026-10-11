// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QueueEvent {

 String get id; String get queueEntryId; QueueEventType get eventType; String get actorId; DateTime get occurredAt; String? get notes;
/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueEventCopyWith<QueueEvent> get copyWith => _$QueueEventCopyWithImpl<QueueEvent>(this as QueueEvent, _$identity);

  /// Serializes this QueueEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as QueueEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueEvent&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.queueEntryId, _this.queueEntryId) || other.queueEntryId == _this.queueEntryId)&&(identical(other.eventType, _this.eventType) || other.eventType == _this.eventType)&&(identical(other.actorId, _this.actorId) || other.actorId == _this.actorId)&&(identical(other.occurredAt, _this.occurredAt) || other.occurredAt == _this.occurredAt)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as QueueEvent;
  return Object.hash(runtimeType,_this.id,_this.queueEntryId,_this.eventType,_this.actorId,_this.occurredAt,_this.notes);
}

@override
String toString() {
  final _this = this as QueueEvent;
  return 'QueueEvent(id: ${_this.id}, queueEntryId: ${_this.queueEntryId}, eventType: ${_this.eventType}, actorId: ${_this.actorId}, occurredAt: ${_this.occurredAt}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $QueueEventCopyWith<$Res>  {
  factory $QueueEventCopyWith(QueueEvent value, $Res Function(QueueEvent) _then) = _$QueueEventCopyWithImpl;
@useResult
$Res call({
 String id, String queueEntryId, QueueEventType eventType, String actorId, DateTime occurredAt, String? notes
});




}
/// @nodoc
class _$QueueEventCopyWithImpl<$Res>
    implements $QueueEventCopyWith<$Res> {
  _$QueueEventCopyWithImpl(this._self, this._then);

  final QueueEvent _self;
  final $Res Function(QueueEvent) _then;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? queueEntryId = null,Object? eventType = null,Object? actorId = null,Object? occurredAt = null,Object? notes = freezed,}) {
  return _then(QueueEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,queueEntryId: null == queueEntryId ? _self.queueEntryId : queueEntryId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as QueueEventType,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueEvent].
extension QueueEventPatterns on QueueEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueEvent value)  $default,){
final _that = this;
switch (_that) {
case _QueueEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueEvent value)?  $default,){
final _that = this;
switch (_that) {
case _QueueEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String queueEntryId,  QueueEventType eventType,  String actorId,  DateTime occurredAt,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueEvent() when $default != null:
return $default(_that.id,_that.queueEntryId,_that.eventType,_that.actorId,_that.occurredAt,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String queueEntryId,  QueueEventType eventType,  String actorId,  DateTime occurredAt,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _QueueEvent():
return $default(_that.id,_that.queueEntryId,_that.eventType,_that.actorId,_that.occurredAt,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String queueEntryId,  QueueEventType eventType,  String actorId,  DateTime occurredAt,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _QueueEvent() when $default != null:
return $default(_that.id,_that.queueEntryId,_that.eventType,_that.actorId,_that.occurredAt,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueEvent implements QueueEvent {
  const _QueueEvent({required this.id, required this.queueEntryId, required this.eventType, required this.actorId, required this.occurredAt, this.notes});
  factory _QueueEvent.fromJson(Map<String, dynamic> json) => _$QueueEventFromJson(json);

@override final  String id;
@override final  String queueEntryId;
@override final  QueueEventType eventType;
@override final  String actorId;
@override final  DateTime occurredAt;
@override final  String? notes;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueEventCopyWith<_QueueEvent> get copyWith => __$QueueEventCopyWithImpl<_QueueEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.queueEntryId, queueEntryId) || other.queueEntryId == queueEntryId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,queueEntryId,eventType,actorId,occurredAt,notes);
}

@override
String toString() {
    return 'QueueEvent(id: $id, queueEntryId: $queueEntryId, eventType: $eventType, actorId: $actorId, occurredAt: $occurredAt, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$QueueEventCopyWith<$Res> implements $QueueEventCopyWith<$Res> {
  factory _$QueueEventCopyWith(_QueueEvent value, $Res Function(_QueueEvent) _then) = __$QueueEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String queueEntryId, QueueEventType eventType, String actorId, DateTime occurredAt, String? notes
});




}
/// @nodoc
class __$QueueEventCopyWithImpl<$Res>
    implements _$QueueEventCopyWith<$Res> {
  __$QueueEventCopyWithImpl(this._self, this._then);

  final _QueueEvent _self;
  final $Res Function(_QueueEvent) _then;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? queueEntryId = null,Object? eventType = null,Object? actorId = null,Object? occurredAt = null,Object? notes = freezed,}) {
  return _then(_QueueEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,queueEntryId: null == queueEntryId ? _self.queueEntryId : queueEntryId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as QueueEventType,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
