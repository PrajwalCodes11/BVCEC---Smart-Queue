// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Queue _$QueueFromJson(Map<String, dynamic> json) => _Queue(
  id: json['id'] as String,
  serviceCenterId: json['serviceCenterId'] as String,
  serviceId: json['serviceId'] as String,
  date: DateTime.parse(json['date'] as String),
  isOpen: json['isOpen'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$QueueToJson(_Queue instance) => <String, dynamic>{
  'id': instance.id,
  'serviceCenterId': instance.serviceCenterId,
  'serviceId': instance.serviceId,
  'date': instance.date.toIso8601String(),
  'isOpen': instance.isOpen,
  'createdAt': instance.createdAt.toIso8601String(),
};
