// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_would_go_negative.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletWouldGoNegative _$WalletWouldGoNegativeFromJson(
  Map<String, dynamic> json,
) => WalletWouldGoNegative(
  privateTag: WalletWouldGoNegativeTag.fromJson(json['_tag'] as String),
  walletMinor: (json['walletMinor'] as num).toInt(),
  neededMinor: (json['neededMinor'] as num).toInt(),
);

Map<String, dynamic> _$WalletWouldGoNegativeToJson(
  WalletWouldGoNegative instance,
) => <String, dynamic>{
  '_tag': _$WalletWouldGoNegativeTagEnumMap[instance.privateTag]!,
  'walletMinor': instance.walletMinor,
  'neededMinor': instance.neededMinor,
};

const _$WalletWouldGoNegativeTagEnumMap = {
  WalletWouldGoNegativeTag.walletWouldGoNegative: 'WalletWouldGoNegative',
  WalletWouldGoNegativeTag.$unknown: r'$unknown',
};
