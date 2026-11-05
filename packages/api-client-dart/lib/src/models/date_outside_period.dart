// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'date_outside_period_tag.dart';

part 'date_outside_period.g.dart';

@JsonSerializable()
class DateOutsidePeriod {
  const DateOutsidePeriod({
    required this.privateTag,
    required this.periodId,
    required this.startsOn,
    required this.endsOn,
  });

  factory DateOutsidePeriod.fromJson(Map<String, Object?> json) =>
      _$DateOutsidePeriodFromJson(json);

  @JsonKey(name: '_tag')
  final DateOutsidePeriodTag privateTag;
  final String periodId;
  final String startsOn;
  final String endsOn;

  Map<String, Object?> toJson() => _$DateOutsidePeriodToJson(this);
}
