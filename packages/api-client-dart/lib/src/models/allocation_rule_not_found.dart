// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'allocation_rule_not_found_tag.dart';

part 'allocation_rule_not_found.g.dart';

@JsonSerializable()
class AllocationRuleNotFound {
  const AllocationRuleNotFound({required this.privateTag, required this.id});

  factory AllocationRuleNotFound.fromJson(Map<String, Object?> json) =>
      _$AllocationRuleNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final AllocationRuleNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$AllocationRuleNotFoundToJson(this);
}
