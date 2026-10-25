// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency.dart';

part 'period.g.dart';

@JsonSerializable()
class Period {
  const Period({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.incomeMinor,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Period.fromJson(Map<String, Object?> json) => _$PeriodFromJson(json);

  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final int incomeMinor;
  final Currency currency;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$PeriodToJson(this);
}
