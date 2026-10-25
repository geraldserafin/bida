// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'no_periods_tag.dart';

part 'no_periods.g.dart';

@JsonSerializable()
class NoPeriods {
  const NoPeriods({required this.privateTag});

  factory NoPeriods.fromJson(Map<String, Object?> json) =>
      _$NoPeriodsFromJson(json);

  @JsonKey(name: '_tag')
  final NoPeriodsTag privateTag;

  Map<String, Object?> toJson() => _$NoPeriodsToJson(this);
}
