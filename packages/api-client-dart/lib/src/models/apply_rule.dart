// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'apply_rule.g.dart';

@JsonSerializable()
class ApplyRule {
  const ApplyRule({required this.amountMinor});

  factory ApplyRule.fromJson(Map<String, Object?> json) =>
      _$ApplyRuleFromJson(json);

  @JsonKey(includeIfNull: true)
  final int? amountMinor;

  Map<String, Object?> toJson() => _$ApplyRuleToJson(this);
}
