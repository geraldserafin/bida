// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_figures.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShareFigures _$ShareFiguresFromJson(Map<String, dynamic> json) => ShareFigures(
  userId: json['userId'] as String?,
  name: json['name'] as String,
  member: json['member'] as bool,
  transfersMinor: (json['transfersMinor'] as num).toInt(),
  withdrawalsMinor: (json['withdrawalsMinor'] as num).toInt(),
  forfeitedMinor: (json['forfeitedMinor'] as num).toInt(),
  spentMinor: (json['spentMinor'] as num).toInt(),
  fromNobodyMinor: (json['fromNobodyMinor'] as num).toInt(),
  shareMinor: (json['shareMinor'] as num).toInt(),
);

Map<String, dynamic> _$ShareFiguresToJson(ShareFigures instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'member': instance.member,
      'transfersMinor': instance.transfersMinor,
      'withdrawalsMinor': instance.withdrawalsMinor,
      'forfeitedMinor': instance.forfeitedMinor,
      'spentMinor': instance.spentMinor,
      'fromNobodyMinor': instance.fromNobodyMinor,
      'shareMinor': instance.shareMinor,
    };
