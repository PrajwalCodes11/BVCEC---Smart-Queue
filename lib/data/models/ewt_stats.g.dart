// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ewt_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EwtStats _$EwtStatsFromJson(Map<String, dynamic> json) => _EwtStats(
  id: json['id'] as String,
  serviceId: json['serviceId'] as String,
  averageDurationMinutes: (json['averageDurationMinutes'] as num).toDouble(),
  sampleCount: (json['sampleCount'] as num).toInt(),
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$EwtStatsToJson(_EwtStats instance) => <String, dynamic>{
  'id': instance.id,
  'serviceId': instance.serviceId,
  'averageDurationMinutes': instance.averageDurationMinutes,
  'sampleCount': instance.sampleCount,
  'lastUpdated': instance.lastUpdated.toIso8601String(),
};
