// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'forecast.g.dart';

@JsonSerializable()
class Forecast {
  const Forecast({
    required this.variableMinor,
    required this.recurringMinor,
    required this.projectedSpentMinor,
    required this.projectedBalanceMinor,
  });

  factory Forecast.fromJson(Map<String, Object?> json) =>
      _$ForecastFromJson(json);

  final int variableMinor;
  final int recurringMinor;
  final int projectedSpentMinor;
  final int projectedBalanceMinor;

  Map<String, Object?> toJson() => _$ForecastToJson(this);
}
