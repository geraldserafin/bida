// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'allocation.dart';
import 'allocation_rule.dart';
import 'envelope.dart';
import 'expense.dart';
import 'export_document_version.dart';
import 'income.dart';
import 'recurring_income.dart';
import 'recurring_rule.dart';

part 'export_document.g.dart';

@JsonSerializable()
class ExportDocument {
  const ExportDocument({
    required this.version,
    required this.exportedAt,
    required this.envelopes,
    required this.allocations,
    required this.incomes,
    required this.expenses,
    required this.recurringRules,
    required this.recurringIncomes,
    required this.allocationRules,
  });

  factory ExportDocument.fromJson(Map<String, Object?> json) =>
      _$ExportDocumentFromJson(json);

  final ExportDocumentVersion version;
  final String exportedAt;
  final List<Envelope> envelopes;
  final List<Allocation> allocations;
  final List<Income> incomes;
  final List<Expense> expenses;
  final List<RecurringRule> recurringRules;
  final List<RecurringIncome> recurringIncomes;
  final List<AllocationRule> allocationRules;

  Map<String, Object?> toJson() => _$ExportDocumentToJson(this);
}
