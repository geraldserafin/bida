// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'periods.dart';
import 'categories.dart';
import 'recurring_rules.dart';
import 'splits.dart';
import 'expenses.dart';

part 'data.g.dart';

@JsonSerializable()
class Data {
  const Data({
    required this.periods,
    required this.categories,
    required this.recurringRules,
    required this.splits,
    required this.expenses,
  });

  factory Data.fromJson(Map<String, Object?> json) => _$DataFromJson(json);

  final List<Periods> periods;
  final List<Categories> categories;
  @JsonKey(name: 'recurring_rules')
  final List<RecurringRules> recurringRules;
  final List<Splits> splits;
  final List<Expenses> expenses;

  Map<String, Object?> toJson() => _$DataToJson(this);
}
