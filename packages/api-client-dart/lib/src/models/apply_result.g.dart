// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apply_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplyResult _$ApplyResultFromJson(Map<String, dynamic> json) => ApplyResult(
  applied: (json['applied'] as num).toInt(),
  todo: (json['todo'] as num).toInt(),
);

Map<String, dynamic> _$ApplyResultToJson(ApplyResult instance) =>
    <String, dynamic>{'applied': instance.applied, 'todo': instance.todo};
