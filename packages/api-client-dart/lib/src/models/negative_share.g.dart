// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'negative_share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NegativeShare _$NegativeShareFromJson(Map<String, dynamic> json) =>
    NegativeShare(
      privateTag: NegativeShareTag.fromJson(json['_tag'] as String),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => NegativeShareEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NegativeShareToJson(NegativeShare instance) =>
    <String, dynamic>{
      '_tag': _$NegativeShareTagEnumMap[instance.privateTag]!,
      'entries': instance.entries,
    };

const _$NegativeShareTagEnumMap = {
  NegativeShareTag.negativeShare: 'NegativeShare',
  NegativeShareTag.$unknown: r'$unknown',
};
