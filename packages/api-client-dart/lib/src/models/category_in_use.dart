// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category_in_use_tag.dart';

part 'category_in_use.g.dart';

@JsonSerializable()
class CategoryInUse {
  const CategoryInUse({required this.privateTag, required this.id});

  factory CategoryInUse.fromJson(Map<String, Object?> json) =>
      _$CategoryInUseFromJson(json);

  @JsonKey(name: '_tag')
  final CategoryInUseTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$CategoryInUseToJson(this);
}
