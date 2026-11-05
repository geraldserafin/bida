// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'period_not_found_tag.dart';

part 'period_not_found.g.dart';

@JsonSerializable()
class PeriodNotFound {
  const PeriodNotFound({required this.privateTag, required this.id});

  factory PeriodNotFound.fromJson(Map<String, Object?> json) =>
      _$PeriodNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final PeriodNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$PeriodNotFoundToJson(this);
}
