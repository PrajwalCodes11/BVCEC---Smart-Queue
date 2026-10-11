import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/queue_state_machine.dart';

part 'queue_entry.freezed.dart';
part 'queue_entry.g.dart';

@freezed
abstract class QueueEntry with _$QueueEntry {
  const factory QueueEntry({
    required String id,
    required String queueId,
    required String userId,
    required String serviceId,
    required int tokenNumber,
    required QueueEntryStatus status,
    @Default(0) int priority,
    required DateTime joinedAt,
    DateTime? calledAt,
    DateTime? serviceStartedAt,
    DateTime? completedAt,
    String? counterId,
    int? estimatedWaitMinutes,
    // Joined fields for display (not always populated)
    String? userName,
    String? serviceName,
    String? counterName,
  }) = _QueueEntry;

  factory QueueEntry.fromJson(Map<String, dynamic> json) =>
      _$QueueEntryFromJson(json);
}
