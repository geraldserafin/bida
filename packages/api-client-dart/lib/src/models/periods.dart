// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'periods.g.dart';

@JsonSerializable()
class Periods {
  const Periods({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.income,
  });

  factory Periods.fromJson(Map<String, Object?> json) =>
      _$PeriodsFromJson(json);

  final int id;
  final String name;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  final dynamic income;

  Map<String, Object?> toJson() => _$PeriodsToJson(this);
}
