// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'contribution_not_found_tag.dart';

part 'contribution_not_found.g.dart';

@JsonSerializable()
class ContributionNotFound {
  const ContributionNotFound({required this.privateTag, required this.id});

  factory ContributionNotFound.fromJson(Map<String, Object?> json) =>
      _$ContributionNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final ContributionNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$ContributionNotFoundToJson(this);
}
