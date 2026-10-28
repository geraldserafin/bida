// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'income_not_found_tag.dart';

part 'income_not_found.g.dart';

@JsonSerializable()
class IncomeNotFound {
  const IncomeNotFound({required this.privateTag, required this.id});

  factory IncomeNotFound.fromJson(Map<String, Object?> json) =>
      _$IncomeNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final IncomeNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$IncomeNotFoundToJson(this);
}
