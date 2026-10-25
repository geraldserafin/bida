// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'legacy_category.dart';
import 'legacy_expense.dart';
import 'legacy_period.dart';
import 'legacy_recurring_rule.dart';
import 'legacy_split.dart';

part 'legacy_data.g.dart';

@JsonSerializable()
class LegacyData {
  const LegacyData({
    required this.periods,
    required this.categories,
    required this.recurringRules,
    required this.splits,
    required this.expenses,
  });

  factory LegacyData.fromJson(Map<String, Object?> json) =>
      _$LegacyDataFromJson(json);

  final List<LegacyPeriod> periods;
  final List<LegacyCategory> categories;
  @JsonKey(name: 'recurring_rules')
  final List<LegacyRecurringRule> recurringRules;
  final List<LegacySplit> splits;
  final List<LegacyExpense> expenses;

  Map<String, Object?> toJson() => _$LegacyDataToJson(this);
}
