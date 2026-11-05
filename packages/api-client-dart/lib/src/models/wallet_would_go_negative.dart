// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'wallet_would_go_negative_tag.dart';

part 'wallet_would_go_negative.g.dart';

@JsonSerializable()
class WalletWouldGoNegative {
  const WalletWouldGoNegative({
    required this.privateTag,
    required this.walletMinor,
    required this.neededMinor,
  });

  factory WalletWouldGoNegative.fromJson(Map<String, Object?> json) =>
      _$WalletWouldGoNegativeFromJson(json);

  @JsonKey(name: '_tag')
  final WalletWouldGoNegativeTag privateTag;
  final int walletMinor;
  final int neededMinor;

  Map<String, Object?> toJson() => _$WalletWouldGoNegativeToJson(this);
}
