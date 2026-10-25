// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'recurring_rule_not_found_tag.dart';

part 'recurring_rule_not_found.g.dart';

@JsonSerializable()
class RecurringRuleNotFound {
  const RecurringRuleNotFound({required this.privateTag, required this.id});

  factory RecurringRuleNotFound.fromJson(Map<String, Object?> json) =>
      _$RecurringRuleNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final RecurringRuleNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$RecurringRuleNotFoundToJson(this);
}
