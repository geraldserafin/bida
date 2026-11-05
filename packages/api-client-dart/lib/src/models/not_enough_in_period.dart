// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'not_enough_in_period_tag.dart';

part 'not_enough_in_period.g.dart';

@JsonSerializable()
class NotEnoughInPeriod {
  const NotEnoughInPeriod({
    required this.privateTag,
    required this.periodId,
    required this.balanceMinor,
    required this.transferMinor,
  });

  factory NotEnoughInPeriod.fromJson(Map<String, Object?> json) =>
      _$NotEnoughInPeriodFromJson(json);

  @JsonKey(name: '_tag')
  final NotEnoughInPeriodTag privateTag;
  final String periodId;
  final int balanceMinor;
  final int transferMinor;

  Map<String, Object?> toJson() => _$NotEnoughInPeriodToJson(this);
}
