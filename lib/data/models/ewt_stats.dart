import 'package:freezed_annotation/freezed_annotation.dart';

part 'ewt_stats.freezed.dart';
part 'ewt_stats.g.dart';

@freezed
abstract class EwtStats with _$EwtStats {
  const factory EwtStats({
    required String id,
    required String serviceId,
    required double averageDurationMinutes,
    required int sampleCount,
    required DateTime lastUpdated,
  }) = _EwtStats;

  factory EwtStats.fromJson(Map<String, dynamic> json) =>
      _$EwtStatsFromJson(json);
}
