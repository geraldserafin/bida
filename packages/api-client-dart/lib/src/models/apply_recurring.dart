// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'apply_recurring.g.dart';

@JsonSerializable()
class ApplyRecurring {
  const ApplyRecurring({required this.from, required this.to});

  factory ApplyRecurring.fromJson(Map<String, Object?> json) =>
      _$ApplyRecurringFromJson(json);

  final String from;
  final String to;

  Map<String, Object?> toJson() => _$ApplyRecurringToJson(this);
}
