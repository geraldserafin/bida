// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'next_period_open_tag.dart';

part 'next_period_open.g.dart';

@JsonSerializable()
class NextPeriodOpen {
  const NextPeriodOpen({required this.privateTag, required this.periodId});

  factory NextPeriodOpen.fromJson(Map<String, Object?> json) =>
      _$NextPeriodOpenFromJson(json);

  @JsonKey(name: '_tag')
  final NextPeriodOpenTag privateTag;
  final String periodId;

  Map<String, Object?> toJson() => _$NextPeriodOpenToJson(this);
}
