import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_session.freezed.dart';
part 'service_session.g.dart';

@freezed
abstract class ServiceSession with _$ServiceSession {
  const factory ServiceSession({
    required String id,
    required String queueEntryId,
    required String counterId,
    required String staffId,
    required String serviceId,
    required DateTime startedAt,
    DateTime? completedAt,
    int? actualDurationMinutes,
  }) = _ServiceSession;

  factory ServiceSession.fromJson(Map<String, dynamic> json) =>
      _$ServiceSessionFromJson(json);
}
