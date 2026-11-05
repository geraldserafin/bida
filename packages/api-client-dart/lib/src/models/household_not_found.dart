// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'household_not_found_tag.dart';

part 'household_not_found.g.dart';

@JsonSerializable()
class HouseholdNotFound {
  const HouseholdNotFound({required this.privateTag, required this.id});

  factory HouseholdNotFound.fromJson(Map<String, Object?> json) =>
      _$HouseholdNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final HouseholdNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$HouseholdNotFoundToJson(this);
}
