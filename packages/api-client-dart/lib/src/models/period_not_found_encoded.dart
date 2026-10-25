// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'period_not_found_encoded_tag.dart';

part 'period_not_found_encoded.g.dart';

@JsonSerializable()
class PeriodNotFoundEncoded {
  const PeriodNotFoundEncoded({required this.privateTag, required this.id});

  factory PeriodNotFoundEncoded.fromJson(Map<String, Object?> json) =>
      _$PeriodNotFoundEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final PeriodNotFoundEncodedTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$PeriodNotFoundEncodedToJson(this);
}
