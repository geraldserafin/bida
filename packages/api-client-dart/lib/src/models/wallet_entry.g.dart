// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletEntry _$WalletEntryFromJson(Map<String, dynamic> json) => WalletEntry(
  id: json['id'] as String,
  kind: WalletEntryKind.fromJson(json['kind'] as String),
  amountMinor: (json['amountMinor'] as num).toInt(),
  onDate: json['onDate'] as String,
  note: json['note'] as String?,
  estimated: json['estimated'] as bool,
  householdId: json['householdId'] as String?,
  householdName: json['householdName'] as String?,
  ruleId: json['ruleId'] as String?,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$WalletEntryToJson(WalletEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$WalletEntryKindEnumMap[instance.kind]!,
      'amountMinor': instance.amountMinor,
      'onDate': instance.onDate,
      'note': instance.note,
      'estimated': instance.estimated,
      'householdId': instance.householdId,
      'householdName': instance.householdName,
      'ruleId': instance.ruleId,
      'createdAt': instance.createdAt,
    };

const _$WalletEntryKindEnumMap = {
  WalletEntryKind.income: 'income',
  WalletEntryKind.transfer: 'transfer',
  WalletEntryKind.withdrawal: 'withdrawal',
  WalletEntryKind.valueReturn: 'return',
  WalletEntryKind.$unknown: r'$unknown',
};
