// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'correction.g.dart';

@JsonSerializable()
class Correction {
  const Correction({
    required this.allowNegative,
    required this.withdrawFromPeriodId,
  });

  factory Correction.fromJson(Map<String, Object?> json) =>
      _$CorrectionFromJson(json);

  final bool allowNegative;
  @JsonKey(includeIfNull: true)
  final String? withdrawFromPeriodId;

  Map<String, Object?> toJson() => _$CorrectionToJson(this);
}
