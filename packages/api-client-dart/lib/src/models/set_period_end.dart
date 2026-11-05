// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'set_period_end.g.dart';

@JsonSerializable()
class SetPeriodEnd {
  const SetPeriodEnd({required this.endsOn});

  factory SetPeriodEnd.fromJson(Map<String, Object?> json) =>
      _$SetPeriodEndFromJson(json);

  final String endsOn;

  Map<String, Object?> toJson() => _$SetPeriodEndToJson(this);
}
