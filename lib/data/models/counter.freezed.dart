// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'counter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Counter {

 String get id; String get serviceCenterId; String get name; CounterStatus get status; String? get assignedStaffId; String? get assignedStaffName;
/// Create a copy of Counter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CounterCopyWith<Counter> get copyWith => _$CounterCopyWithImpl<Counter>(this as Counter, _$identity);

  /// Serializes this Counter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Counter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Counter&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.serviceCenterId, _this.serviceCenterId) || other.serviceCenterId == _this.serviceCenterId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.assignedStaffId, _this.assignedStaffId) || other.assignedStaffId == _this.assignedStaffId)&&(identical(other.assignedStaffName, _this.assignedStaffName) || other.assignedStaffName == _this.assignedStaffName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Counter;
  return Object.hash(runtimeType,_this.id,_this.serviceCenterId,_this.name,_this.status,_this.assignedStaffId,_this.assignedStaffName);
}

@override
String toString() {
  final _this = this as Counter;
  return 'Counter(id: ${_this.id}, serviceCenterId: ${_this.serviceCenterId}, name: ${_this.name}, status: ${_this.status}, assignedStaffId: ${_this.assignedStaffId}, assignedStaffName: ${_this.assignedStaffName})';
}


}

/// @nodoc
abstract mixin class $CounterCopyWith<$Res>  {
  factory $CounterCopyWith(Counter value, $Res Function(Counter) _then) = _$CounterCopyWithImpl;
@useResult
$Res call({
 String id, String serviceCenterId, String name, CounterStatus status, String? assignedStaffId, String? assignedStaffName
});




}
/// @nodoc
class _$CounterCopyWithImpl<$Res>
    implements $CounterCopyWith<$Res> {
  _$CounterCopyWithImpl(this._self, this._then);

  final Counter _self;
  final $Res Function(Counter) _then;

/// Create a copy of Counter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? serviceCenterId = null,Object? name = null,Object? status = null,Object? assignedStaffId = freezed,Object? assignedStaffName = freezed,}) {
  return _then(Counter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serviceCenterId: null == serviceCenterId ? _self.serviceCenterId : serviceCenterId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CounterStatus,assignedStaffId: freezed == assignedStaffId ? _self.assignedStaffId : assignedStaffId // ignore: cast_nullable_to_non_nullable
as String?,assignedStaffName: freezed == assignedStaffName ? _self.assignedStaffName : assignedStaffName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Counter].
extension CounterPatterns on Counter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Counter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Counter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Counter value)  $default,){
final _that = this;
switch (_that) {
case _Counter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Counter value)?  $default,){
final _that = this;
switch (_that) {
case _Counter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String serviceCenterId,  String name,  CounterStatus status,  String? assignedStaffId,  String? assignedStaffName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Counter() when $default != null:
return $default(_that.id,_that.serviceCenterId,_that.name,_that.status,_that.assignedStaffId,_that.assignedStaffName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String serviceCenterId,  String name,  CounterStatus status,  String? assignedStaffId,  String? assignedStaffName)  $default,) {final _that = this;
switch (_that) {
case _Counter():
return $default(_that.id,_that.serviceCenterId,_that.name,_that.status,_that.assignedStaffId,_that.assignedStaffName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String serviceCenterId,  String name,  CounterStatus status,  String? assignedStaffId,  String? assignedStaffName)?  $default,) {final _that = this;
switch (_that) {
case _Counter() when $default != null:
return $default(_that.id,_that.serviceCenterId,_that.name,_that.status,_that.assignedStaffId,_that.assignedStaffName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Counter implements Counter {
  const _Counter({required this.id, required this.serviceCenterId, required this.name, required this.status, this.assignedStaffId, this.assignedStaffName});
  factory _Counter.fromJson(Map<String, dynamic> json) => _$CounterFromJson(json);

@override final  String id;
@override final  String serviceCenterId;
@override final  String name;
@override final  CounterStatus status;
@override final  String? assignedStaffId;
@override final  String? assignedStaffName;

/// Create a copy of Counter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CounterCopyWith<_Counter> get copyWith => __$CounterCopyWithImpl<_Counter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CounterToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Counter&&(identical(other.id, id) || other.id == id)&&(identical(other.serviceCenterId, serviceCenterId) || other.serviceCenterId == serviceCenterId)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignedStaffId, assignedStaffId) || other.assignedStaffId == assignedStaffId)&&(identical(other.assignedStaffName, assignedStaffName) || other.assignedStaffName == assignedStaffName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,serviceCenterId,name,status,assignedStaffId,assignedStaffName);
}

@override
String toString() {
    return 'Counter(id: $id, serviceCenterId: $serviceCenterId, name: $name, status: $status, assignedStaffId: $assignedStaffId, assignedStaffName: $assignedStaffName)';
}


}

/// @nodoc
abstract mixin class _$CounterCopyWith<$Res> implements $CounterCopyWith<$Res> {
  factory _$CounterCopyWith(_Counter value, $Res Function(_Counter) _then) = __$CounterCopyWithImpl;
@override @useResult
$Res call({
 String id, String serviceCenterId, String name, CounterStatus status, String? assignedStaffId, String? assignedStaffName
});




}
/// @nodoc
class __$CounterCopyWithImpl<$Res>
    implements _$CounterCopyWith<$Res> {
  __$CounterCopyWithImpl(this._self, this._then);

  final _Counter _self;
  final $Res Function(_Counter) _then;

/// Create a copy of Counter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? serviceCenterId = null,Object? name = null,Object? status = null,Object? assignedStaffId = freezed,Object? assignedStaffName = freezed,}) {
  return _then(_Counter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serviceCenterId: null == serviceCenterId ? _self.serviceCenterId : serviceCenterId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CounterStatus,assignedStaffId: freezed == assignedStaffId ? _self.assignedStaffId : assignedStaffId // ignore: cast_nullable_to_non_nullable
as String?,assignedStaffName: freezed == assignedStaffName ? _self.assignedStaffName : assignedStaffName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
