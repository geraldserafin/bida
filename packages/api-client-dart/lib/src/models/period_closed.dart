// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'period_closed_tag.dart';

part 'period_closed.g.dart';

@JsonSerializable()
class PeriodClosed {
  const PeriodClosed({required this.privateTag, required this.periodId});

  factory PeriodClosed.fromJson(Map<String, Object?> json) =>
      _$PeriodClosedFromJson(json);

  @JsonKey(name: '_tag')
  final PeriodClosedTag privateTag;
  final String periodId;

  Map<String, Object?> toJson() => _$PeriodClosedToJson(this);
}
