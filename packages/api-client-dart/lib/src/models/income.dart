// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'income.g.dart';

@JsonSerializable()
class Income {
  const Income({
    required this.id,
    required this.userId,
    required this.amountMinor,
    required this.receivedOn,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Income.fromJson(Map<String, Object?> json) => _$IncomeFromJson(json);

  final String id;
  final String userId;
  final int amountMinor;
  final String receivedOn;
  @JsonKey(includeIfNull: true)
  final String? note;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$IncomeToJson(this);
}
