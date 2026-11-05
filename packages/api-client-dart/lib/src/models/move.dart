// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'move_kind.dart';

part 'move.g.dart';

@JsonSerializable()
class Move {
  const Move({
    required this.id,
    required this.periodId,
    required this.kind,
    required this.userId,
    required this.userName,
    required this.amountMinor,
    required this.madeAt,
    required this.ruleId,
  });

  factory Move.fromJson(Map<String, Object?> json) => _$MoveFromJson(json);

  final String id;
  final String periodId;
  final MoveKind kind;
  @JsonKey(includeIfNull: true)
  final String? userId;
  @JsonKey(includeIfNull: true)
  final String? userName;
  final int amountMinor;
  final String madeAt;
  @JsonKey(includeIfNull: true)
  final String? ruleId;

  Map<String, Object?> toJson() => _$MoveToJson(this);
}
