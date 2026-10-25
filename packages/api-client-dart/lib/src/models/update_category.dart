// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_category.g.dart';

@JsonSerializable()
class UpdateCategory {
  const UpdateCategory({
    required this.name,
    required this.color,
    required this.icon,
  });

  factory UpdateCategory.fromJson(Map<String, Object?> json) =>
      _$UpdateCategoryFromJson(json);

  final String name;
  final String color;
  final String? icon;

  Map<String, Object?> toJson() => _$UpdateCategoryToJson(this);
}
