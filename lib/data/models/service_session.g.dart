// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceSession _$ServiceSessionFromJson(Map<String, dynamic> json) =>
    _ServiceSession(
      id: json['id'] as String,
      queueEntryId: json['queueEntryId'] as String,
      counterId: json['counterId'] as String,
      staffId: json['staffId'] as String,
      serviceId: json['serviceId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      actualDurationMinutes: (json['actualDurationMinutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ServiceSessionToJson(_ServiceSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'queueEntryId': instance.queueEntryId,
      'counterId': instance.counterId,
      'staffId': instance.staffId,
      'serviceId': instance.serviceId,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'actualDurationMinutes': instance.actualDurationMinutes,
    };
