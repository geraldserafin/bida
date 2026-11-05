// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cannot_undo_tag.dart';

part 'cannot_undo.g.dart';

@JsonSerializable()
class CannotUndo {
  const CannotUndo({required this.privateTag, required this.reason});

  factory CannotUndo.fromJson(Map<String, Object?> json) =>
      _$CannotUndoFromJson(json);

  @JsonKey(name: '_tag')
  final CannotUndoTag privateTag;
  final String reason;

  Map<String, Object?> toJson() => _$CannotUndoToJson(this);
}
