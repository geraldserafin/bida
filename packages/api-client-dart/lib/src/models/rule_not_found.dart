// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'rule_not_found_tag.dart';

part 'rule_not_found.g.dart';

@JsonSerializable()
class RuleNotFound {
  const RuleNotFound({required this.privateTag, required this.id});

  factory RuleNotFound.fromJson(Map<String, Object?> json) =>
      _$RuleNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final RuleNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$RuleNotFoundToJson(this);
}
