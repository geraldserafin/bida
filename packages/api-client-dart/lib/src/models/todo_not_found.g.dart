// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoNotFound _$TodoNotFoundFromJson(Map<String, dynamic> json) => TodoNotFound(
  privateTag: TodoNotFoundTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$TodoNotFoundToJson(TodoNotFound instance) =>
    <String, dynamic>{
      '_tag': _$TodoNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$TodoNotFoundTagEnumMap = {
  TodoNotFoundTag.todoNotFound: 'TodoNotFound',
  TodoNotFoundTag.$unknown: r'$unknown',
};
