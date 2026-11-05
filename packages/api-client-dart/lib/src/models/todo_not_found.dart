// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'todo_not_found_tag.dart';

part 'todo_not_found.g.dart';

@JsonSerializable()
class TodoNotFound {
  const TodoNotFound({required this.privateTag, required this.id});

  factory TodoNotFound.fromJson(Map<String, Object?> json) =>
      _$TodoNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final TodoNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$TodoNotFoundToJson(this);
}
