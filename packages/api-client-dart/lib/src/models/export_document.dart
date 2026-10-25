// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category.dart';
import 'envelope.dart';
import 'expense.dart';
import 'export_document_version.dart';
import 'period.dart';
import 'recurring_rule.dart';

part 'export_document.g.dart';

@JsonSerializable()
class ExportDocument {
  const ExportDocument({
    required this.version,
    required this.exportedAt,
    required this.categories,
    required this.periods,
    required this.envelopes,
    required this.expenses,
    required this.recurringRules,
  });

  factory ExportDocument.fromJson(Map<String, Object?> json) =>
      _$ExportDocumentFromJson(json);

  final ExportDocumentVersion version;
  final String exportedAt;
  final List<Category> categories;
  final List<Period> periods;
  final List<Envelope> envelopes;
  final List<Expense> expenses;
  final List<RecurringRule> recurringRules;

  Map<String, Object?> toJson() => _$ExportDocumentToJson(this);
}
