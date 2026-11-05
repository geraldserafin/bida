// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'wallet_negative_tag.dart';

part 'wallet_negative.g.dart';

@JsonSerializable()
class WalletNegative {
  const WalletNegative({required this.privateTag, required this.walletMinor});

  factory WalletNegative.fromJson(Map<String, Object?> json) =>
      _$WalletNegativeFromJson(json);

  @JsonKey(name: '_tag')
  final WalletNegativeTag privateTag;
  final int walletMinor;

  Map<String, Object?> toJson() => _$WalletNegativeToJson(this);
}
