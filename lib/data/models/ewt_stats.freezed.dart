// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ewt_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EwtStats {

 String get id; String get serviceId; double get averageDurationMinutes; int get sampleCount; DateTime get lastUpdated;
/// Create a copy of EwtStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EwtStatsCopyWith<EwtStats> get copyWith => _$EwtStatsCopyWithImpl<EwtStats>(this as EwtStats, _$identity);

  /// Serializes this EwtStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EwtStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EwtStats&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.serviceId, _this.serviceId) || other.serviceId == _this.serviceId)&&(identical(other.averageDurationMinutes, _this.averageDurationMinutes) || other.averageDurationMinutes == _this.averageDurationMinutes)&&(identical(other.sampleCount, _this.sampleCount) || other.sampleCount == _this.sampleCount)&&(identical(other.lastUpdated, _this.lastUpdated) || other.lastUpdated == _this.lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EwtStats;
  return Object.hash(runtimeType,_this.id,_this.serviceId,_this.averageDurationMinutes,_this.sampleCount,_this.lastUpdated);
}

@override
String toString() {
  final _this = this as EwtStats;
  return 'EwtStats(id: ${_this.id}, serviceId: ${_this.serviceId}, averageDurationMinutes: ${_this.averageDurationMinutes}, sampleCount: ${_this.sampleCount}, lastUpdated: ${_this.lastUpdated})';
}


}

/// @nodoc
abstract mixin class $EwtStatsCopyWith<$Res>  {
  factory $EwtStatsCopyWith(EwtStats value, $Res Function(EwtStats) _then) = _$EwtStatsCopyWithImpl;
@useResult
$Res call({
 String id, String serviceId, double averageDurationMinutes, int sampleCount, DateTime lastUpdated
});




}
/// @nodoc
class _$EwtStatsCopyWithImpl<$Res>
    implements $EwtStatsCopyWith<$Res> {
  _$EwtStatsCopyWithImpl(this._self, this._then);

  final EwtStats _self;
  final $Res Function(EwtStats) _then;

/// Create a copy of EwtStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? serviceId = null,Object? averageDurationMinutes = null,Object? sampleCount = null,Object? lastUpdated = null,}) {
  return _then(EwtStats(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,averageDurationMinutes: null == averageDurationMinutes ? _self.averageDurationMinutes : averageDurationMinutes // ignore: cast_nullable_to_non_nullable
as double,sampleCount: null == sampleCount ? _self.sampleCount : sampleCount // ignore: cast_nullable_to_non_nullable
as int,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [EwtStats].
extension EwtStatsPatterns on EwtStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EwtStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EwtStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EwtStats value)  $default,){
final _that = this;
switch (_that) {
case _EwtStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EwtStats value)?  $default,){
final _that = this;
switch (_that) {
case _EwtStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String serviceId,  double averageDurationMinutes,  int sampleCount,  DateTime lastUpdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EwtStats() when $default != null:
return $default(_that.id,_that.serviceId,_that.averageDurationMinutes,_that.sampleCount,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String serviceId,  double averageDurationMinutes,  int sampleCount,  DateTime lastUpdated)  $default,) {final _that = this;
switch (_that) {
case _EwtStats():
return $default(_that.id,_that.serviceId,_that.averageDurationMinutes,_that.sampleCount,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String serviceId,  double averageDurationMinutes,  int sampleCount,  DateTime lastUpdated)?  $default,) {final _that = this;
switch (_that) {
case _EwtStats() when $default != null:
return $default(_that.id,_that.serviceId,_that.averageDurationMinutes,_that.sampleCount,_that.lastUpdated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EwtStats implements EwtStats {
  const _EwtStats({required this.id, required this.serviceId, required this.averageDurationMinutes, required this.sampleCount, required this.lastUpdated});
  factory _EwtStats.fromJson(Map<String, dynamic> json) => _$EwtStatsFromJson(json);

@override final  String id;
@override final  String serviceId;
@override final  double averageDurationMinutes;
@override final  int sampleCount;
@override final  DateTime lastUpdated;

/// Create a copy of EwtStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EwtStatsCopyWith<_EwtStats> get copyWith => __$EwtStatsCopyWithImpl<_EwtStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EwtStatsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EwtStats&&(identical(other.id, id) || other.id == id)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.averageDurationMinutes, averageDurationMinutes) || other.averageDurationMinutes == averageDurationMinutes)&&(identical(other.sampleCount, sampleCount) || other.sampleCount == sampleCount)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,serviceId,averageDurationMinutes,sampleCount,lastUpdated);
}

@override
String toString() {
    return 'EwtStats(id: $id, serviceId: $serviceId, averageDurationMinutes: $averageDurationMinutes, sampleCount: $sampleCount, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class _$EwtStatsCopyWith<$Res> implements $EwtStatsCopyWith<$Res> {
  factory _$EwtStatsCopyWith(_EwtStats value, $Res Function(_EwtStats) _then) = __$EwtStatsCopyWithImpl;
@override @useResult
$Res call({
 String id, String serviceId, double averageDurationMinutes, int sampleCount, DateTime lastUpdated
});




}
/// @nodoc
class __$EwtStatsCopyWithImpl<$Res>
    implements _$EwtStatsCopyWith<$Res> {
  __$EwtStatsCopyWithImpl(this._self, this._then);

  final _EwtStats _self;
  final $Res Function(_EwtStats) _then;

/// Create a copy of EwtStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? serviceId = null,Object? averageDurationMinutes = null,Object? sampleCount = null,Object? lastUpdated = null,}) {
  return _then(_EwtStats(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,averageDurationMinutes: null == averageDurationMinutes ? _self.averageDurationMinutes : averageDurationMinutes // ignore: cast_nullable_to_non_nullable
as double,sampleCount: null == sampleCount ? _self.sampleCount : sampleCount // ignore: cast_nullable_to_non_nullable
as int,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
