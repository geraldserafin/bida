// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'legacy_period.g.dart';

@JsonSerializable()
class LegacyPeriod {
  const LegacyPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.income,
  });

  factory LegacyPeriod.fromJson(Map<String, Object?> json) =>
      _$LegacyPeriodFromJson(json);

  final int id;
  final String name;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  final num income;

  Map<String, Object?> toJson() => _$LegacyPeriodToJson(this);
}
