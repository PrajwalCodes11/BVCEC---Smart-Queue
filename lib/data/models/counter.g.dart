// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Counter _$CounterFromJson(Map<String, dynamic> json) => _Counter(
  id: json['id'] as String,
  serviceCenterId: json['serviceCenterId'] as String,
  name: json['name'] as String,
  status: $enumDecode(_$CounterStatusEnumMap, json['status']),
  assignedStaffId: json['assignedStaffId'] as String?,
  assignedStaffName: json['assignedStaffName'] as String?,
);

Map<String, dynamic> _$CounterToJson(_Counter instance) => <String, dynamic>{
  'id': instance.id,
  'serviceCenterId': instance.serviceCenterId,
  'name': instance.name,
  'status': _$CounterStatusEnumMap[instance.status]!,
  'assignedStaffId': instance.assignedStaffId,
  'assignedStaffName': instance.assignedStaffName,
};

const _$CounterStatusEnumMap = {
  CounterStatus.available: 'available',
  CounterStatus.serving: 'serving',
  CounterStatus.paused: 'paused',
  CounterStatus.offline: 'offline',
};
