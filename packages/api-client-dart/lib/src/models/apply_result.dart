// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'apply_result.g.dart';

@JsonSerializable()
class ApplyResult {
  const ApplyResult({required this.added});

  factory ApplyResult.fromJson(Map<String, Object?> json) =>
      _$ApplyResultFromJson(json);

  final int added;

  Map<String, Object?> toJson() => _$ApplyResultToJson(this);
}
