// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'leave.g.dart';

@JsonSerializable()
class Leave {
  const Leave({required this.withdraw});

  factory Leave.fromJson(Map<String, Object?> json) => _$LeaveFromJson(json);

  final bool withdraw;

  Map<String, Object?> toJson() => _$LeaveToJson(this);
}
