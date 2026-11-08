// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'recurring_rule_frequency.dart';
import 'recurring_rule_target.dart';
import 'rule_kind.dart';

part 'recurring_rule.g.dart';

@JsonSerializable()
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.kind,
    required this.userId,
    required this.householdId,
    required this.envelopeId,
    required this.name,
    required this.amountMinor,
    required this.estimated,
    required this.frequency,
    required this.dayOfMonth,
    required this.everyWeeks,
    required this.anchorOn,
    required this.startsOn,
    required this.target,
    required this.incomeRuleId,
    required this.active,
  });

  factory RecurringRule.fromJson(Map<String, Object?> json) =>
      _$RecurringRuleFromJson(json);

  final String id;
  final RuleKind kind;
  final String userId;
  @JsonKey(includeIfNull: true)
  final String? householdId;
  @JsonKey(includeIfNull: true)
  final String? envelopeId;
  final String name;
  final int amountMinor;
  final bool estimated;
  final RecurringRuleFrequency frequency;
  @JsonKey(includeIfNull: true)
  final int? dayOfMonth;
  @JsonKey(includeIfNull: true)
  final int? everyWeeks;
  @JsonKey(includeIfNull: true)
  final String? anchorOn;
  final String startsOn;
  @JsonKey(includeIfNull: true)
  final RecurringRuleTarget? target;
  @JsonKey(includeIfNull: true)
  final String? incomeRuleId;
  final bool active;

  Map<String, Object?> toJson() => _$RecurringRuleToJson(this);
}
