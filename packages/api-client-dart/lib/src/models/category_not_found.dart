// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category_not_found_tag.dart';

part 'category_not_found.g.dart';

@JsonSerializable()
class CategoryNotFound {
  const CategoryNotFound({required this.privateTag, required this.id});

  factory CategoryNotFound.fromJson(Map<String, Object?> json) =>
      _$CategoryNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final CategoryNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$CategoryNotFoundToJson(this);
}
