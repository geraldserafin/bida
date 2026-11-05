// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'period_not_current_tag.dart';

part 'period_not_current.g.dart';

@JsonSerializable()
class PeriodNotCurrent {
  const PeriodNotCurrent({required this.privateTag, required this.periodId});

  factory PeriodNotCurrent.fromJson(Map<String, Object?> json) =>
      _$PeriodNotCurrentFromJson(json);

  @JsonKey(name: '_tag')
  final PeriodNotCurrentTag privateTag;
  final String periodId;

  Map<String, Object?> toJson() => _$PeriodNotCurrentToJson(this);
}
