// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'not_shareable_tag.dart';

part 'not_shareable.g.dart';

@JsonSerializable()
class NotShareable {
  const NotShareable({required this.privateTag});

  factory NotShareable.fromJson(Map<String, Object?> json) =>
      _$NotShareableFromJson(json);

  @JsonKey(name: '_tag')
  final NotShareableTag privateTag;

  Map<String, Object?> toJson() => _$NotShareableToJson(this);
}
