// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'expense_not_found_encoded_tag.dart';

part 'expense_not_found_encoded.g.dart';

@JsonSerializable()
class ExpenseNotFoundEncoded {
  const ExpenseNotFoundEncoded({required this.privateTag, required this.id});

  factory ExpenseNotFoundEncoded.fromJson(Map<String, Object?> json) =>
      _$ExpenseNotFoundEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final ExpenseNotFoundEncodedTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$ExpenseNotFoundEncodedToJson(this);
}
