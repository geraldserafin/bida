// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_period.g.dart';

@JsonSerializable()
class UpdatePeriod {
  const UpdatePeriod({
    required this.version,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory UpdatePeriod.fromJson(Map<String, Object?> json) =>
      _$UpdatePeriodFromJson(json);

  final int version;
  final String name;
  final String startDate;
  final String endDate;

  Map<String, Object?> toJson() => _$UpdatePeriodToJson(this);
}
