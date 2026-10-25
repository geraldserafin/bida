// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contribution_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContributionNotFound _$ContributionNotFoundFromJson(
  Map<String, dynamic> json,
) => ContributionNotFound(
  privateTag: ContributionNotFoundTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$ContributionNotFoundToJson(
  ContributionNotFound instance,
) => <String, dynamic>{
  '_tag': _$ContributionNotFoundTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$ContributionNotFoundTagEnumMap = {
  ContributionNotFoundTag.contributionNotFound: 'ContributionNotFound',
  ContributionNotFoundTag.$unknown: r'$unknown',
};
