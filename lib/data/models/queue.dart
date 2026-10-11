import 'package:freezed_annotation/freezed_annotation.dart';

part 'queue.freezed.dart';
part 'queue.g.dart';

@freezed
abstract class Queue with _$Queue {
  const factory Queue({
    required String id,
    required String serviceCenterId,
    required String serviceId,
    required DateTime date,
    required bool isOpen,
    required DateTime createdAt,
  }) = _Queue;

  factory Queue.fromJson(Map<String, dynamic> json) =>
      _$QueueFromJson(json);
}
