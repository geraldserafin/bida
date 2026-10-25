// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'legacy_recurring_rule.g.dart';

@JsonSerializable()
class LegacyRecurringRule {
  const LegacyRecurringRule({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.frequency,
    required this.note,
    required this.active,
  });

  factory LegacyRecurringRule.fromJson(Map<String, Object?> json) =>
      _$LegacyRecurringRuleFromJson(json);

  final int id;
  @JsonKey(name: 'category_id')
  final int categoryId;
  final num amount;
  final String frequency;
  final String? note;
  final int active;

  Map<String, Object?> toJson() => _$LegacyRecurringRuleToJson(this);
}
