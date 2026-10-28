// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contribution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contribution _$ContributionFromJson(Map<String, dynamic> json) => Contribution(
  envelopeId: json['envelopeId'] as String,
  userId: json['userId'] as String,
  amountMinor: (json['amountMinor'] as num).toInt(),
);

Map<String, dynamic> _$ContributionToJson(Contribution instance) =>
    <String, dynamic>{
      'envelopeId': instance.envelopeId,
      'userId': instance.userId,
      'amountMinor': instance.amountMinor,
    };
