// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cannot_undo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CannotUndo _$CannotUndoFromJson(Map<String, dynamic> json) => CannotUndo(
  privateTag: CannotUndoTag.fromJson(json['_tag'] as String),
  reason: json['reason'] as String,
);

Map<String, dynamic> _$CannotUndoToJson(CannotUndo instance) =>
    <String, dynamic>{
      '_tag': _$CannotUndoTagEnumMap[instance.privateTag]!,
      'reason': instance.reason,
    };

const _$CannotUndoTagEnumMap = {
  CannotUndoTag.cannotUndo: 'CannotUndo',
  CannotUndoTag.$unknown: r'$unknown',
};
