// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'negative_share_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NegativeShareEntry _$NegativeShareEntryFromJson(Map<String, dynamic> json) =>
    NegativeShareEntry(
      householdId: json['householdId'] as String,
      householdName: json['householdName'] as String,
      periodId: json['periodId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      shareMinor: (json['shareMinor'] as num).toInt(),
    );

Map<String, dynamic> _$NegativeShareEntryToJson(NegativeShareEntry instance) =>
    <String, dynamic>{
      'householdId': instance.householdId,
      'householdName': instance.householdName,
      'periodId': instance.periodId,
      'userId': instance.userId,
      'name': instance.name,
      'shareMinor': instance.shareMinor,
    };
