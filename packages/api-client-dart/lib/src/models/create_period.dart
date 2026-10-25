// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency.dart';
import 'envelope_plan.dart';

part 'create_period.g.dart';

@JsonSerializable()
class CreatePeriod {
  const CreatePeriod({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.incomeMinor,
    required this.envelopes,
    this.currency,
  });

  factory CreatePeriod.fromJson(Map<String, Object?> json) =>
      _$CreatePeriodFromJson(json);

  final String name;
  final String startDate;
  final String endDate;
  final int incomeMinor;
  @JsonKey(includeIfNull: false)
  final Currency? currency;
  final List<EnvelopePlan> envelopes;

  Map<String, Object?> toJson() => _$CreatePeriodToJson(this);
}
