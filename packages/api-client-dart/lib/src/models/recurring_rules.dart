// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'recurring_rules.g.dart';

@JsonSerializable()
class RecurringRules {
  const RecurringRules({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.frequency,
    required this.note,
    required this.active,
  });

  factory RecurringRules.fromJson(Map<String, Object?> json) =>
      _$RecurringRulesFromJson(json);

  final int id;
  @JsonKey(name: 'category_id')
  final int categoryId;
  final dynamic amount;
  final String frequency;
  final String? note;
  final int active;

  Map<String, Object?> toJson() => _$RecurringRulesToJson(this);
}
