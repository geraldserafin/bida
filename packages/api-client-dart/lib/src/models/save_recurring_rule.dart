// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'save_recurring_rule_frequency.dart';

part 'save_recurring_rule.g.dart';

@JsonSerializable()
class SaveRecurringRule {
  const SaveRecurringRule({
    required this.envelopeId,
    required this.amountMinor,
    required this.frequency,
    required this.note,
    required this.active,
  });

  factory SaveRecurringRule.fromJson(Map<String, Object?> json) =>
      _$SaveRecurringRuleFromJson(json);

  final String envelopeId;
  final int amountMinor;
  final SaveRecurringRuleFrequency frequency;
  @JsonKey(includeIfNull: true)
  final String? note;
  final bool active;

  Map<String, Object?> toJson() => _$SaveRecurringRuleToJson(this);
}
