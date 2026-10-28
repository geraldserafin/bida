// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'counts.g.dart';

@JsonSerializable()
class Counts {
  const Counts({
    required this.envelopes,
    required this.allocations,
    required this.incomes,
    required this.expenses,
    required this.recurringRules,
    required this.recurringIncomes,
    required this.allocationRules,
  });

  factory Counts.fromJson(Map<String, Object?> json) => _$CountsFromJson(json);

  final int envelopes;
  final int allocations;
  final int incomes;
  final int expenses;
  final int recurringRules;
  final int recurringIncomes;
  final int allocationRules;

  Map<String, Object?> toJson() => _$CountsToJson(this);
}
