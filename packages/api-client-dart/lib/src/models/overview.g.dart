// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Overview _$OverviewFromJson(Map<String, dynamic> json) => Overview(
  wallet: Wallet.fromJson(json['wallet'] as Map<String, dynamic>),
  households: (json['households'] as List<dynamic>)
      .map((e) => HouseholdOverview.fromJson(e as Map<String, dynamic>))
      .toList(),
  todo: (json['todo'] as num).toInt(),
);

Map<String, dynamic> _$OverviewToJson(Overview instance) => <String, dynamic>{
  'wallet': instance.wallet,
  'households': instance.households,
  'todo': instance.todo,
};
