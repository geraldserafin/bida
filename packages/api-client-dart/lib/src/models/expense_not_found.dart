// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'expense_not_found_tag.dart';

part 'expense_not_found.g.dart';

@JsonSerializable()
class ExpenseNotFound {
  const ExpenseNotFound({required this.privateTag, required this.id});

  factory ExpenseNotFound.fromJson(Map<String, Object?> json) =>
      _$ExpenseNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final ExpenseNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$ExpenseNotFoundToJson(this);
}
