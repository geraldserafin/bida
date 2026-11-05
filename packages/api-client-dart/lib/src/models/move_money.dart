// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'move_money.g.dart';

@JsonSerializable()
class MoveMoney {
  const MoveMoney({required this.amountMinor});

  factory MoveMoney.fromJson(Map<String, Object?> json) =>
      _$MoveMoneyFromJson(json);

  final int amountMinor;

  Map<String, Object?> toJson() => _$MoveMoneyToJson(this);
}
