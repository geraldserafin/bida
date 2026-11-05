// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_overview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HouseholdOverview _$HouseholdOverviewFromJson(Map<String, dynamic> json) =>
    HouseholdOverview(
      id: json['id'] as String,
      name: json['name'] as String,
      current: Period.fromJson(json['current'] as Map<String, dynamic>),
      balanceMinor: (json['balanceMinor'] as num).toInt(),
      freeMinor: (json['freeMinor'] as num).toInt(),
      spentMinor: (json['spentMinor'] as num).toInt(),
    );

Map<String, dynamic> _$HouseholdOverviewToJson(HouseholdOverview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'current': instance.current,
      'balanceMinor': instance.balanceMinor,
      'freeMinor': instance.freeMinor,
      'spentMinor': instance.spentMinor,
    };
