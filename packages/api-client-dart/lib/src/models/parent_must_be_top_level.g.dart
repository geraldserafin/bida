// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parent_must_be_top_level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParentMustBeTopLevel _$ParentMustBeTopLevelFromJson(
  Map<String, dynamic> json,
) => ParentMustBeTopLevel(
  privateTag: ParentMustBeTopLevelTag.fromJson(json['_tag'] as String),
  parentId: json['parentId'] as String,
);

Map<String, dynamic> _$ParentMustBeTopLevelToJson(
  ParentMustBeTopLevel instance,
) => <String, dynamic>{
  '_tag': _$ParentMustBeTopLevelTagEnumMap[instance.privateTag]!,
  'parentId': instance.parentId,
};

const _$ParentMustBeTopLevelTagEnumMap = {
  ParentMustBeTopLevelTag.parentMustBeTopLevel: 'ParentMustBeTopLevel',
  ParentMustBeTopLevelTag.$unknown: r'$unknown',
};
