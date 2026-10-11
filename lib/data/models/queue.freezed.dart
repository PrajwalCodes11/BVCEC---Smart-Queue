// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Queue {

 String get id; String get serviceCenterId; String get serviceId; DateTime get date; bool get isOpen; DateTime get createdAt;
/// Create a copy of Queue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueCopyWith<Queue> get copyWith => _$QueueCopyWithImpl<Queue>(this as Queue, _$identity);

  /// Serializes this Queue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Queue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Queue&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.serviceCenterId, _this.serviceCenterId) || other.serviceCenterId == _this.serviceCenterId)&&(identical(other.serviceId, _this.serviceId) || other.serviceId == _this.serviceId)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.isOpen, _this.isOpen) || other.isOpen == _this.isOpen)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Queue;
  return Object.hash(runtimeType,_this.id,_this.serviceCenterId,_this.serviceId,_this.date,_this.isOpen,_this.createdAt);
}

@override
String toString() {
  final _this = this as Queue;
  return 'Queue(id: ${_this.id}, serviceCenterId: ${_this.serviceCenterId}, serviceId: ${_this.serviceId}, date: ${_this.date}, isOpen: ${_this.isOpen}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $QueueCopyWith<$Res>  {
  factory $QueueCopyWith(Queue value, $Res Function(Queue) _then) = _$QueueCopyWithImpl;
@useResult
$Res call({
 String id, String serviceCenterId, String serviceId, DateTime date, bool isOpen, DateTime createdAt
});




}
/// @nodoc
class _$QueueCopyWithImpl<$Res>
    implements $QueueCopyWith<$Res> {
  _$QueueCopyWithImpl(this._self, this._then);

  final Queue _self;
  final $Res Function(Queue) _then;

/// Create a copy of Queue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? serviceCenterId = null,Object? serviceId = null,Object? date = null,Object? isOpen = null,Object? createdAt = null,}) {
  return _then(Queue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serviceCenterId: null == serviceCenterId ? _self.serviceCenterId : serviceCenterId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Queue].
extension QueuePatterns on Queue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Queue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Queue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Queue value)  $default,){
final _that = this;
switch (_that) {
case _Queue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Queue value)?  $default,){
final _that = this;
switch (_that) {
case _Queue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String serviceCenterId,  String serviceId,  DateTime date,  bool isOpen,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Queue() when $default != null:
return $default(_that.id,_that.serviceCenterId,_that.serviceId,_that.date,_that.isOpen,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String serviceCenterId,  String serviceId,  DateTime date,  bool isOpen,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Queue():
return $default(_that.id,_that.serviceCenterId,_that.serviceId,_that.date,_that.isOpen,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String serviceCenterId,  String serviceId,  DateTime date,  bool isOpen,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Queue() when $default != null:
return $default(_that.id,_that.serviceCenterId,_that.serviceId,_that.date,_that.isOpen,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Queue implements Queue {
  const _Queue({required this.id, required this.serviceCenterId, required this.serviceId, required this.date, required this.isOpen, required this.createdAt});
  factory _Queue.fromJson(Map<String, dynamic> json) => _$QueueFromJson(json);

@override final  String id;
@override final  String serviceCenterId;
@override final  String serviceId;
@override final  DateTime date;
@override final  bool isOpen;
@override final  DateTime createdAt;

/// Create a copy of Queue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueCopyWith<_Queue> get copyWith => __$QueueCopyWithImpl<_Queue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Queue&&(identical(other.id, id) || other.id == id)&&(identical(other.serviceCenterId, serviceCenterId) || other.serviceCenterId == serviceCenterId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.date, date) || other.date == date)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,serviceCenterId,serviceId,date,isOpen,createdAt);
}

@override
String toString() {
    return 'Queue(id: $id, serviceCenterId: $serviceCenterId, serviceId: $serviceId, date: $date, isOpen: $isOpen, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$QueueCopyWith<$Res> implements $QueueCopyWith<$Res> {
  factory _$QueueCopyWith(_Queue value, $Res Function(_Queue) _then) = __$QueueCopyWithImpl;
@override @useResult
$Res call({
 String id, String serviceCenterId, String serviceId, DateTime date, bool isOpen, DateTime createdAt
});




}
/// @nodoc
class __$QueueCopyWithImpl<$Res>
    implements _$QueueCopyWith<$Res> {
  __$QueueCopyWithImpl(this._self, this._then);

  final _Queue _self;
  final $Res Function(_Queue) _then;

/// Create a copy of Queue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? serviceCenterId = null,Object? serviceId = null,Object? date = null,Object? isOpen = null,Object? createdAt = null,}) {
  return _then(_Queue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serviceCenterId: null == serviceCenterId ? _self.serviceCenterId : serviceCenterId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
