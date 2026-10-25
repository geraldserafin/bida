// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, Object?> json) =>
      _$CategoryFromJson(json);

  final String id;
  final String name;
  final String color;
  final String? icon;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$CategoryToJson(this);
}
