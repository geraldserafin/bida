// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invalid_period_range_encoded_tag.dart';

part 'invalid_period_range_encoded.g.dart';

@JsonSerializable()
class InvalidPeriodRangeEncoded {
  const InvalidPeriodRangeEncoded({
    required this.privateTag,
    required this.startDate,
    required this.endDate,
  });

  factory InvalidPeriodRangeEncoded.fromJson(Map<String, Object?> json) =>
      _$InvalidPeriodRangeEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final InvalidPeriodRangeEncodedTag privateTag;
  final String startDate;
  final String endDate;

  Map<String, Object?> toJson() => _$InvalidPeriodRangeEncodedToJson(this);
}
