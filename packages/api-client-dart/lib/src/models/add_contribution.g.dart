// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_contribution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddContribution _$AddContributionFromJson(Map<String, dynamic> json) =>
    AddContribution(
      amountMinor: (json['amountMinor'] as num).toInt(),
      contributedAt: json['contributedAt'] as String,
      note: json['note'] as String?,
      externalValue: json['external'] as bool?,
    );

Map<String, dynamic> _$AddContributionToJson(AddContribution instance) =>
    <String, dynamic>{
      'amountMinor': instance.amountMinor,
      'contributedAt': instance.contributedAt,
      'note': instance.note,
      'external': ?instance.externalValue,
    };
