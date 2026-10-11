// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Service _$ServiceFromJson(Map<String, dynamic> json) => _Service(
  id: json['id'] as String,
  serviceCenterId: json['serviceCenterId'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num).toInt(),
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$ServiceToJson(_Service instance) => <String, dynamic>{
  'id': instance.id,
  'serviceCenterId': instance.serviceCenterId,
  'name': instance.name,
  'description': instance.description,
  'estimatedDurationMinutes': instance.estimatedDurationMinutes,
  'isActive': instance.isActive,
};
