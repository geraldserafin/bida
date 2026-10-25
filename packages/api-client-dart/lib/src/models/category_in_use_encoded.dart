// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category_in_use_encoded_tag.dart';

part 'category_in_use_encoded.g.dart';

@JsonSerializable()
class CategoryInUseEncoded {
  const CategoryInUseEncoded({required this.privateTag, required this.id});

  factory CategoryInUseEncoded.fromJson(Map<String, Object?> json) =>
      _$CategoryInUseEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final CategoryInUseEncodedTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$CategoryInUseEncodedToJson(this);
}
