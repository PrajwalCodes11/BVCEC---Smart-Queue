// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_center.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceCenter {

 String get id; String get name; String get description; bool get isActive; DateTime get createdAt;
/// Create a copy of ServiceCenter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceCenterCopyWith<ServiceCenter> get copyWith => _$ServiceCenterCopyWithImpl<ServiceCenter>(this as ServiceCenter, _$identity);

  /// Serializes this ServiceCenter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ServiceCenter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceCenter&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ServiceCenter;
  return Object.hash(runtimeType,_this.id,_this.name,_this.description,_this.isActive,_this.createdAt);
}

@override
String toString() {
  final _this = this as ServiceCenter;
  return 'ServiceCenter(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, isActive: ${_this.isActive}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ServiceCenterCopyWith<$Res>  {
  factory $ServiceCenterCopyWith(ServiceCenter value, $Res Function(ServiceCenter) _then) = _$ServiceCenterCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, bool isActive, DateTime createdAt
});




}
/// @nodoc
class _$ServiceCenterCopyWithImpl<$Res>
    implements $ServiceCenterCopyWith<$Res> {
  _$ServiceCenterCopyWithImpl(this._self, this._then);

  final ServiceCenter _self;
  final $Res Function(ServiceCenter) _then;

/// Create a copy of ServiceCenter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(ServiceCenter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceCenter].
extension ServiceCenterPatterns on ServiceCenter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceCenter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceCenter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceCenter value)  $default,){
final _that = this;
switch (_that) {
case _ServiceCenter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceCenter value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceCenter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  bool isActive,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceCenter() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  bool isActive,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ServiceCenter():
return $default(_that.id,_that.name,_that.description,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  bool isActive,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ServiceCenter() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceCenter implements ServiceCenter {
  const _ServiceCenter({required this.id, required this.name, required this.description, required this.isActive, required this.createdAt});
  factory _ServiceCenter.fromJson(Map<String, dynamic> json) => _$ServiceCenterFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  bool isActive;
@override final  DateTime createdAt;

/// Create a copy of ServiceCenter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceCenterCopyWith<_ServiceCenter> get copyWith => __$ServiceCenterCopyWithImpl<_ServiceCenter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceCenterToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceCenter&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,description,isActive,createdAt);
}

@override
String toString() {
    return 'ServiceCenter(id: $id, name: $name, description: $description, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ServiceCenterCopyWith<$Res> implements $ServiceCenterCopyWith<$Res> {
  factory _$ServiceCenterCopyWith(_ServiceCenter value, $Res Function(_ServiceCenter) _then) = __$ServiceCenterCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, bool isActive, DateTime createdAt
});




}
/// @nodoc
class __$ServiceCenterCopyWithImpl<$Res>
    implements _$ServiceCenterCopyWith<$Res> {
  __$ServiceCenterCopyWithImpl(this._self, this._then);

  final _ServiceCenter _self;
  final $Res Function(_ServiceCenter) _then;

/// Create a copy of ServiceCenter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_ServiceCenter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
