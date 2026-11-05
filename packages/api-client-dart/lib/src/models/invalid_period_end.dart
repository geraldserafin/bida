// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invalid_period_end_reason.dart';
import 'invalid_period_end_tag.dart';

part 'invalid_period_end.g.dart';

@JsonSerializable()
class InvalidPeriodEnd {
  const InvalidPeriodEnd({required this.privateTag, required this.reason});

  factory InvalidPeriodEnd.fromJson(Map<String, Object?> json) =>
      _$InvalidPeriodEndFromJson(json);

  @JsonKey(name: '_tag')
  final InvalidPeriodEndTag privateTag;
  final InvalidPeriodEndReason reason;

  Map<String, Object?> toJson() => _$InvalidPeriodEndToJson(this);
}
