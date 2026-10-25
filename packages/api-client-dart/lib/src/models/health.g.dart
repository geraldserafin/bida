// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Health _$HealthFromJson(Map<String, dynamic> json) => Health(
  status: HealthStatus.fromJson(json['status'] as String),
  uptimeSeconds: (json['uptimeSeconds'] as num).toInt(),
);

Map<String, dynamic> _$HealthToJson(Health instance) => <String, dynamic>{
  'status': _$HealthStatusEnumMap[instance.status]!,
  'uptimeSeconds': instance.uptimeSeconds,
};

const _$HealthStatusEnumMap = {
  HealthStatus.ok: 'ok',
  HealthStatus.$unknown: r'$unknown',
};
