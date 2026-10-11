// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QueueEvent _$QueueEventFromJson(Map<String, dynamic> json) => _QueueEvent(
  id: json['id'] as String,
  queueEntryId: json['queueEntryId'] as String,
  eventType: $enumDecode(_$QueueEventTypeEnumMap, json['eventType']),
  actorId: json['actorId'] as String,
  occurredAt: DateTime.parse(json['occurredAt'] as String),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$QueueEventToJson(_QueueEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'queueEntryId': instance.queueEntryId,
      'eventType': _$QueueEventTypeEnumMap[instance.eventType]!,
      'actorId': instance.actorId,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'notes': instance.notes,
    };

const _$QueueEventTypeEnumMap = {
  QueueEventType.joined: 'joined',
  QueueEventType.called: 'called',
  QueueEventType.serving: 'serving',
  QueueEventType.completed: 'completed',
  QueueEventType.cancelled: 'cancelled',
  QueueEventType.noShow: 'noShow',
  QueueEventType.transferred: 'transferred',
};
