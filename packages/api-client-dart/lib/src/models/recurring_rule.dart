// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency.dart';
import 'recurring_rule_frequency.dart';

part 'recurring_rule.g.dart';

@JsonSerializable()
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.categoryId,
    required this.amountMinor,
    required this.currency,
    required this.frequency,
    required this.note,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringRule.fromJson(Map<String, Object?> json) =>
      _$RecurringRuleFromJson(json);

  final String id;
  final String categoryId;
  final int amountMinor;
  final Currency currency;
  final RecurringRuleFrequency frequency;
  final String? note;
  final bool active;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$RecurringRuleToJson(this);
}
