import 'package:freezed_annotation/freezed_annotation.dart';

part 'service.freezed.dart';
part 'service.g.dart';

@freezed
abstract class Service with _$Service {
  const factory Service({
    required String id,
    required String serviceCenterId,
    required String name,
    required String description,
    required int estimatedDurationMinutes,
    required bool isActive,
  }) = _Service;

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);
}
