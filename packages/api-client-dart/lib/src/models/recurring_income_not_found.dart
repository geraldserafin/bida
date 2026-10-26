// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'recurring_income_not_found_tag.dart';

part 'recurring_income_not_found.g.dart';

@JsonSerializable()
class RecurringIncomeNotFound {
  const RecurringIncomeNotFound({required this.privateTag, required this.id});

  factory RecurringIncomeNotFound.fromJson(Map<String, Object?> json) =>
      _$RecurringIncomeNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final RecurringIncomeNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$RecurringIncomeNotFoundToJson(this);
}
