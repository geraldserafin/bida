// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'no_periods_encoded_tag.dart';

part 'no_periods_encoded.g.dart';

@JsonSerializable()
class NoPeriodsEncoded {
  const NoPeriodsEncoded({required this.privateTag});

  factory NoPeriodsEncoded.fromJson(Map<String, Object?> json) =>
      _$NoPeriodsEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final NoPeriodsEncodedTag privateTag;

  Map<String, Object?> toJson() => _$NoPeriodsEncodedToJson(this);
}
