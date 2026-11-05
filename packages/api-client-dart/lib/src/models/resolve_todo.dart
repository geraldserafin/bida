// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'correction.dart';
import 'decision.dart';

part 'resolve_todo.g.dart';

@JsonSerializable()
class ResolveTodo {
  const ResolveTodo({
    required this.amountMinor,
    this.decision,
    this.correction,
  });

  factory ResolveTodo.fromJson(Map<String, Object?> json) =>
      _$ResolveTodoFromJson(json);

  final int amountMinor;
  @JsonKey(includeIfNull: false)
  final Decision? decision;
  @JsonKey(includeIfNull: false)
  final Correction? correction;

  Map<String, Object?> toJson() => _$ResolveTodoToJson(this);
}
