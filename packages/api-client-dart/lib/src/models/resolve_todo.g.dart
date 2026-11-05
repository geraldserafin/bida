// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resolve_todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResolveTodo _$ResolveTodoFromJson(Map<String, dynamic> json) => ResolveTodo(
  amountMinor: (json['amountMinor'] as num).toInt(),
  decision: json['decision'] == null
      ? null
      : Decision.fromJson(json['decision'] as Map<String, dynamic>),
  correction: json['correction'] == null
      ? null
      : Correction.fromJson(json['correction'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ResolveTodoToJson(ResolveTodo instance) =>
    <String, dynamic>{
      'amountMinor': instance.amountMinor,
      'decision': ?instance.decision,
      'correction': ?instance.correction,
    };
