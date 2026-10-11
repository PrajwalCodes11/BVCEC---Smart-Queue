import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/queue_state_machine.dart';

part 'counter.freezed.dart';
part 'counter.g.dart';

@freezed
abstract class Counter with _$Counter {
  const factory Counter({
    required String id,
    required String serviceCenterId,
    required String name,
    required CounterStatus status,
    String? assignedStaffId,
    String? assignedStaffName,
  }) = _Counter;

  factory Counter.fromJson(Map<String, dynamic> json) =>
      _$CounterFromJson(json);
}
