// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'not_enough_money_tag.dart';

part 'not_enough_money.g.dart';

@JsonSerializable()
class NotEnoughMoney {
  const NotEnoughMoney({
    required this.privateTag,
    required this.envelopeId,
    required this.availableMinor,
  });

  factory NotEnoughMoney.fromJson(Map<String, Object?> json) =>
      _$NotEnoughMoneyFromJson(json);

  @JsonKey(name: '_tag')
  final NotEnoughMoneyTag privateTag;
  final String envelopeId;
  final int availableMinor;

  Map<String, Object?> toJson() => _$NotEnoughMoneyToJson(this);
}
