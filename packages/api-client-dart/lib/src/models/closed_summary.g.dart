// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'closed_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClosedSummary _$ClosedSummaryFromJson(Map<String, dynamic> json) =>
    ClosedSummary(
      periodId: json['periodId'] as String,
      householdId: json['householdId'] as String,
      householdName: json['householdName'] as String,
      startsOn: json['startsOn'] as String,
      endsOn: json['endsOn'] as String,
      transfersMinor: (json['transfersMinor'] as num).toInt(),
      withdrawalsMinor: (json['withdrawalsMinor'] as num).toInt(),
      carryInMinor: (json['carryInMinor'] as num).toInt(),
      spentMinor: (json['spentMinor'] as num).toInt(),
      carryOutMinor: (json['carryOutMinor'] as num).toInt(),
    );

Map<String, dynamic> _$ClosedSummaryToJson(ClosedSummary instance) =>
    <String, dynamic>{
      'periodId': instance.periodId,
      'householdId': instance.householdId,
      'householdName': instance.householdName,
      'startsOn': instance.startsOn,
      'endsOn': instance.endsOn,
      'transfersMinor': instance.transfersMinor,
      'withdrawalsMinor': instance.withdrawalsMinor,
      'carryInMinor': instance.carryInMinor,
      'spentMinor': instance.spentMinor,
      'carryOutMinor': instance.carryOutMinor,
    };
