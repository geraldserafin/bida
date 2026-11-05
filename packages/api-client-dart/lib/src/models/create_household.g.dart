// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_household.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateHousehold _$CreateHouseholdFromJson(Map<String, dynamic> json) =>
    CreateHousehold(
      name: json['name'] as String,
      cycle: json['cycle'] == null
          ? null
          : Cycle.fromJson(json['cycle'] as Map<String, dynamic>),
      firstEndsOn: json['firstEndsOn'] as String?,
      timeZone: json['timeZone'] as String?,
      envelopes: (json['envelopes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CreateHouseholdToJson(CreateHousehold instance) =>
    <String, dynamic>{
      'name': instance.name,
      'cycle': ?instance.cycle,
      'firstEndsOn': ?instance.firstEndsOn,
      'timeZone': ?instance.timeZone,
      'envelopes': ?instance.envelopes,
    };
