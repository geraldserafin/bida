// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contribution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contribution _$ContributionFromJson(Map<String, dynamic> json) => Contribution(
  id: json['id'] as String,
  periodId: json['periodId'] as String,
  userId: json['userId'] as String?,
  amountMinor: (json['amountMinor'] as num).toInt(),
  contributedAt: json['contributedAt'] as String,
  note: json['note'] as String?,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$ContributionToJson(Contribution instance) =>
    <String, dynamic>{
      'id': instance.id,
      'periodId': instance.periodId,
      'userId': instance.userId,
      'amountMinor': instance.amountMinor,
      'contributedAt': instance.contributedAt,
      'note': instance.note,
      'createdAt': instance.createdAt,
    };
