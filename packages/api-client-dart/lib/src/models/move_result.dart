// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'move.dart';

part 'move_result.g.dart';

@JsonSerializable()
class MoveResult {
  const MoveResult({
    required this.move,
    required this.walletMinor,
    required this.usedUnconfirmed,
    required this.plansExceedBalance,
  });

  factory MoveResult.fromJson(Map<String, Object?> json) =>
      _$MoveResultFromJson(json);

  final Move move;
  final int walletMinor;
  final bool usedUnconfirmed;
  final bool plansExceedBalance;

  Map<String, Object?> toJson() => _$MoveResultToJson(this);
}
