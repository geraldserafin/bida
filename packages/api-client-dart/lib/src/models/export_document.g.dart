// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportDocument _$ExportDocumentFromJson(Map<String, dynamic> json) =>
    ExportDocument(
      version: ExportDocumentVersion.fromJson(json['version'] as num),
      exportedAt: json['exportedAt'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
      periods: (json['periods'] as List<dynamic>)
          .map((e) => Period.fromJson(e as Map<String, dynamic>))
          .toList(),
      envelopes: (json['envelopes'] as List<dynamic>)
          .map((e) => Envelope.fromJson(e as Map<String, dynamic>))
          .toList(),
      expenses: (json['expenses'] as List<dynamic>)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
      recurringRules: (json['recurringRules'] as List<dynamic>)
          .map((e) => RecurringRule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExportDocumentToJson(ExportDocument instance) =>
    <String, dynamic>{
      'version': _$ExportDocumentVersionEnumMap[instance.version]!,
      'exportedAt': instance.exportedAt,
      'categories': instance.categories,
      'periods': instance.periods,
      'envelopes': instance.envelopes,
      'expenses': instance.expenses,
      'recurringRules': instance.recurringRules,
    };

const _$ExportDocumentVersionEnumMap = {
  ExportDocumentVersion.value1: 1,
  ExportDocumentVersion.$unknown: r'$unknown',
};
