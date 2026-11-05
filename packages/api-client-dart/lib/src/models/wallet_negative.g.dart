// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_negative.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletNegative _$WalletNegativeFromJson(Map<String, dynamic> json) =>
    WalletNegative(
      privateTag: WalletNegativeTag.fromJson(json['_tag'] as String),
      walletMinor: (json['walletMinor'] as num).toInt(),
    );

Map<String, dynamic> _$WalletNegativeToJson(WalletNegative instance) =>
    <String, dynamic>{
      '_tag': _$WalletNegativeTagEnumMap[instance.privateTag]!,
      'walletMinor': instance.walletMinor,
    };

const _$WalletNegativeTagEnumMap = {
  WalletNegativeTag.walletNegative: 'WalletNegative',
  WalletNegativeTag.$unknown: r'$unknown',
};
