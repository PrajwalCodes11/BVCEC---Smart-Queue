// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QueueEntry _$QueueEntryFromJson(Map<String, dynamic> json) => _QueueEntry(
  id: json['id'] as String,
  queueId: json['queueId'] as String,
  userId: json['userId'] as String,
  serviceId: json['serviceId'] as String,
  tokenNumber: (json['tokenNumber'] as num).toInt(),
  status: $enumDecode(_$QueueEntryStatusEnumMap, json['status']),
  priority: (json['priority'] as num?)?.toInt() ?? 0,
  joinedAt: DateTime.parse(json['joinedAt'] as String),
  calledAt: json['calledAt'] == null
      ? null
      : DateTime.parse(json['calledAt'] as String),
  serviceStartedAt: json['serviceStartedAt'] == null
      ? null
      : DateTime.parse(json['serviceStartedAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  counterId: json['counterId'] as String?,
  estimatedWaitMinutes: (json['estimatedWaitMinutes'] as num?)?.toInt(),
  userName: json['userName'] as String?,
  serviceName: json['serviceName'] as String?,
  counterName: json['counterName'] as String?,
);

Map<String, dynamic> _$QueueEntryToJson(_QueueEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'queueId': instance.queueId,
      'userId': instance.userId,
      'serviceId': instance.serviceId,
      'tokenNumber': instance.tokenNumber,
      'status': _$QueueEntryStatusEnumMap[instance.status]!,
      'priority': instance.priority,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'calledAt': instance.calledAt?.toIso8601String(),
      'serviceStartedAt': instance.serviceStartedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'counterId': instance.counterId,
      'estimatedWaitMinutes': instance.estimatedWaitMinutes,
      'userName': instance.userName,
      'serviceName': instance.serviceName,
      'counterName': instance.counterName,
    };

const _$QueueEntryStatusEnumMap = {
  QueueEntryStatus.waiting: 'waiting',
  QueueEntryStatus.called: 'called',
  QueueEntryStatus.serving: 'serving',
  QueueEntryStatus.completed: 'completed',
  QueueEntryStatus.cancelled: 'cancelled',
  QueueEntryStatus.noShow: 'noShow',
  QueueEntryStatus.transferred: 'transferred',
};
