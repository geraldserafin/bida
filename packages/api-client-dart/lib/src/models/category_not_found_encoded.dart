// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category_not_found_encoded_tag.dart';

part 'category_not_found_encoded.g.dart';

@JsonSerializable()
class CategoryNotFoundEncoded {
  const CategoryNotFoundEncoded({required this.privateTag, required this.id});

  factory CategoryNotFoundEncoded.fromJson(Map<String, Object?> json) =>
      _$CategoryNotFoundEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final CategoryNotFoundEncodedTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$CategoryNotFoundEncodedToJson(this);
}
