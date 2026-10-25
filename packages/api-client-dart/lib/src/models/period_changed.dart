// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'period_changed_tag.dart';

part 'period_changed.g.dart';

@JsonSerializable()
class PeriodChanged {
  const PeriodChanged({required this.privateTag, required this.id});

  factory PeriodChanged.fromJson(Map<String, Object?> json) =>
      _$PeriodChangedFromJson(json);

  @JsonKey(name: '_tag')
  final PeriodChangedTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$PeriodChangedToJson(this);
}
