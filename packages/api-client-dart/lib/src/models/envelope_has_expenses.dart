// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'envelope_has_expenses_tag.dart';

part 'envelope_has_expenses.g.dart';

@JsonSerializable()
class EnvelopeHasExpenses {
  const EnvelopeHasExpenses({required this.privateTag, required this.id});

  factory EnvelopeHasExpenses.fromJson(Map<String, Object?> json) =>
      _$EnvelopeHasExpensesFromJson(json);

  @JsonKey(name: '_tag')
  final EnvelopeHasExpensesTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$EnvelopeHasExpensesToJson(this);
}
