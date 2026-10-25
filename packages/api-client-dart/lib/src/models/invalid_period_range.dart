// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invalid_period_range_tag.dart';

part 'invalid_period_range.g.dart';

@JsonSerializable()
class InvalidPeriodRange {
  const InvalidPeriodRange({
    required this.privateTag,
    required this.startDate,
    required this.endDate,
  });

  factory InvalidPeriodRange.fromJson(Map<String, Object?> json) =>
      _$InvalidPeriodRangeFromJson(json);

  @JsonKey(name: '_tag')
  final InvalidPeriodRangeTag privateTag;
  final String startDate;
  final String endDate;

  Map<String, Object?> toJson() => _$InvalidPeriodRangeToJson(this);
}
