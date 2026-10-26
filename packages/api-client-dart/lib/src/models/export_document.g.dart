// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportDocument _$ExportDocumentFromJson(Map<String, dynamic> json) =>
    ExportDocument(
      version: ExportDocumentVersion.fromJson(json['version'] as num),
      exportedAt: json['exportedAt'] as String,
      envelopes: (json['envelopes'] as List<dynamic>)
          .map((e) => Envelope.fromJson(e as Map<String, dynamic>))
          .toList(),
      allocations: (json['allocations'] as List<dynamic>)
          .map((e) => Allocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      incomes: (json['incomes'] as List<dynamic>)
          .map((e) => Income.fromJson(e as Map<String, dynamic>))
          .toList(),
      expenses: (json['expenses'] as List<dynamic>)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
      recurringRules: (json['recurringRules'] as List<dynamic>)
          .map((e) => RecurringRule.fromJson(e as Map<String, dynamic>))
          .toList(),
      recurringIncomes: (json['recurringIncomes'] as List<dynamic>)
          .map((e) => RecurringIncome.fromJson(e as Map<String, dynamic>))
          .toList(),
      allocationRules: (json['allocationRules'] as List<dynamic>)
          .map((e) => AllocationRule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExportDocumentToJson(ExportDocument instance) =>
    <String, dynamic>{
      'version': _$ExportDocumentVersionEnumMap[instance.version]!,
      'exportedAt': instance.exportedAt,
      'envelopes': instance.envelopes,
      'allocations': instance.allocations,
      'incomes': instance.incomes,
      'expenses': instance.expenses,
      'recurringRules': instance.recurringRules,
      'recurringIncomes': instance.recurringIncomes,
      'allocationRules': instance.allocationRules,
    };

const _$ExportDocumentVersionEnumMap = {
  ExportDocumentVersion.value2: 2,
  ExportDocumentVersion.$unknown: r'$unknown',
};
