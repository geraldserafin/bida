// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'todo_kind.dart';

part 'todo_item.g.dart';

@JsonSerializable()
class TodoItem {
  const TodoItem({
    required this.id,
    required this.kind,
    required this.householdId,
    required this.householdName,
    required this.periodId,
    required this.ruleId,
    required this.refId,
    required this.envelopeId,
    required this.occurrenceOn,
    required this.amountMinor,
    required this.title,
    required this.createdAt,
  });

  factory TodoItem.fromJson(Map<String, Object?> json) =>
      _$TodoItemFromJson(json);

  final String id;
  final TodoKind kind;
  @JsonKey(includeIfNull: true)
  final String? householdId;
  @JsonKey(includeIfNull: true)
  final String? householdName;
  @JsonKey(includeIfNull: true)
  final String? periodId;
  @JsonKey(includeIfNull: true)
  final String? ruleId;
  @JsonKey(includeIfNull: true)
  final String? refId;
  @JsonKey(includeIfNull: true)
  final String? envelopeId;
  @JsonKey(includeIfNull: true)
  final String? occurrenceOn;
  final int amountMinor;
  @JsonKey(includeIfNull: true)
  final String? title;
  final String createdAt;

  Map<String, Object?> toJson() => _$TodoItemToJson(this);
}
