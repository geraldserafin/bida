// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency.dart';

part 'original_amount.g.dart';

@JsonSerializable()
class OriginalAmount {
  const OriginalAmount({required this.amountMinor, required this.currency});

  factory OriginalAmount.fromJson(Map<String, Object?> json) =>
      _$OriginalAmountFromJson(json);

  final int amountMinor;
  final Currency currency;

  Map<String, Object?> toJson() => _$OriginalAmountToJson(this);
}
