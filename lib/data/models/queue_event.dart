import 'package:freezed_annotation/freezed_annotation.dart';

part 'queue_event.freezed.dart';
part 'queue_event.g.dart';

enum QueueEventType {
  joined,
  called,
  serving,
  completed,
  cancelled,
  noShow,
  transferred;

  String toDbString() {
    switch (this) {
      case QueueEventType.noShow:
        return 'no_show';
      default:
        return name;
    }
  }
}

@freezed
abstract class QueueEvent with _$QueueEvent {
  const factory QueueEvent({
    required String id,
    required String queueEntryId,
    required QueueEventType eventType,
    required String actorId,
    required DateTime occurredAt,
    String? notes,
  }) = _QueueEvent;

  factory QueueEvent.fromJson(Map<String, dynamic> json) =>
      _$QueueEventFromJson(json);
}
