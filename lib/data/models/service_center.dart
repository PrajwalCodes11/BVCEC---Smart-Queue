import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_center.freezed.dart';
part 'service_center.g.dart';

@freezed
abstract class ServiceCenter with _$ServiceCenter {
  const factory ServiceCenter({
    required String id,
    required String name,
    required String description,
    required bool isActive,
    required DateTime createdAt,
  }) = _ServiceCenter;

  factory ServiceCenter.fromJson(Map<String, dynamic> json) =>
      _$ServiceCenterFromJson(json);
}
