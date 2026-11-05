// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'wallet.g.dart';

@JsonSerializable()
class Wallet {
  const Wallet({required this.balanceMinor, required this.unconfirmedMinor});

  factory Wallet.fromJson(Map<String, Object?> json) => _$WalletFromJson(json);

  final int balanceMinor;
  final int unconfirmedMinor;

  Map<String, Object?> toJson() => _$WalletToJson(this);
}
