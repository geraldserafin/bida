// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'space_not_found_encoded_tag.dart';

part 'space_not_found_encoded.g.dart';

@JsonSerializable()
class SpaceNotFoundEncoded {
  const SpaceNotFoundEncoded({required this.privateTag, required this.id});

  factory SpaceNotFoundEncoded.fromJson(Map<String, Object?> json) =>
      _$SpaceNotFoundEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final SpaceNotFoundEncodedTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$SpaceNotFoundEncodedToJson(this);
}
