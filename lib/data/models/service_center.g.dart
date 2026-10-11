// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_center.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceCenter _$ServiceCenterFromJson(Map<String, dynamic> json) =>
    _ServiceCenter(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ServiceCenterToJson(_ServiceCenter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };
