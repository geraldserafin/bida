// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Forecast _$ForecastFromJson(Map<String, dynamic> json) => Forecast(
  variableMinor: (json['variableMinor'] as num).toInt(),
  recurringMinor: (json['recurringMinor'] as num).toInt(),
  projectedSpentMinor: (json['projectedSpentMinor'] as num).toInt(),
  projectedBalanceMinor: (json['projectedBalanceMinor'] as num).toInt(),
);

Map<String, dynamic> _$ForecastToJson(Forecast instance) => <String, dynamic>{
  'variableMinor': instance.variableMinor,
  'recurringMinor': instance.recurringMinor,
  'projectedSpentMinor': instance.projectedSpentMinor,
  'projectedBalanceMinor': instance.projectedBalanceMinor,
};
