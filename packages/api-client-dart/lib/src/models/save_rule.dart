// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'rule_kind.dart';
import 'save_rule_frequency.dart';
import 'save_rule_target.dart';

part 'save_rule.g.dart';

@JsonSerializable()
class SaveRule {
  const SaveRule({
    required this.kind,
    required this.householdId,
    required this.envelopeId,
    required this.name,
    required this.amountMinor,
    required this.estimated,
    required this.frequency,
    required this.dayOfMonth,
    required this.everyWeeks,
    required this.anchorOn,
    required this.target,
    required this.active,
    this.startsOn,
  });

  factory SaveRule.fromJson(Map<String, Object?> json) =>
      _$SaveRuleFromJson(json);

  final RuleKind kind;
  @JsonKey(includeIfNull: true)
  final String? householdId;
  @JsonKey(includeIfNull: true)
  final String? envelopeId;
  final String name;
  final int amountMinor;
  final bool estimated;
  final SaveRuleFrequency frequency;
  @JsonKey(includeIfNull: true)
  final int? dayOfMonth;
  @JsonKey(includeIfNull: true)
  final int? everyWeeks;
  @JsonKey(includeIfNull: true)
  final String? anchorOn;
  @JsonKey(includeIfNull: false)
  final String? startsOn;
  @JsonKey(includeIfNull: true)
  final SaveRuleTarget? target;
  final bool active;

  Map<String, Object?> toJson() => _$SaveRuleToJson(this);
}
