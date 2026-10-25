// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'legacy_category.g.dart';

@JsonSerializable()
class LegacyCategory {
  const LegacyCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  factory LegacyCategory.fromJson(Map<String, Object?> json) =>
      _$LegacyCategoryFromJson(json);

  final int id;
  final String name;
  final String color;
  @JsonKey(includeIfNull: true)
  final String? icon;

  Map<String, Object?> toJson() => _$LegacyCategoryToJson(this);
}
