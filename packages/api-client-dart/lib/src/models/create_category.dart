// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'create_category.g.dart';

@JsonSerializable()
class CreateCategory {
  const CreateCategory({
    required this.name,
    required this.color,
    required this.icon,
  });

  factory CreateCategory.fromJson(Map<String, Object?> json) =>
      _$CreateCategoryFromJson(json);

  final String name;
  final String color;
  @JsonKey(includeIfNull: true)
  final String? icon;

  Map<String, Object?> toJson() => _$CreateCategoryToJson(this);
}
