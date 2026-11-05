// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wallet _$WalletFromJson(Map<String, dynamic> json) => Wallet(
  balanceMinor: (json['balanceMinor'] as num).toInt(),
  unconfirmedMinor: (json['unconfirmedMinor'] as num).toInt(),
);

Map<String, dynamic> _$WalletToJson(Wallet instance) => <String, dynamic>{
  'balanceMinor': instance.balanceMinor,
  'unconfirmedMinor': instance.unconfirmedMinor,
};
