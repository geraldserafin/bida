// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'period_status.dart';

part 'period.g.dart';

@JsonSerializable()
class Period {
  const Period({
    required this.id,
    required this.householdId,
    required this.startsOn,
    required this.endsOn,
    required this.status,
  });

  factory Period.fromJson(Map<String, Object?> json) => _$PeriodFromJson(json);

  final String id;
  final String householdId;
  final String startsOn;
  final String endsOn;
  final PeriodStatus status;

  Map<String, Object?> toJson() => _$PeriodToJson(this);
}
