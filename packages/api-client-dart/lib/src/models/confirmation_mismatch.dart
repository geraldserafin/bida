// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'confirmation_mismatch_tag.dart';

part 'confirmation_mismatch.g.dart';

@JsonSerializable()
class ConfirmationMismatch {
  const ConfirmationMismatch({required this.privateTag});

  factory ConfirmationMismatch.fromJson(Map<String, Object?> json) =>
      _$ConfirmationMismatchFromJson(json);

  @JsonKey(name: '_tag')
  final ConfirmationMismatchTag privateTag;

  Map<String, Object?> toJson() => _$ConfirmationMismatchToJson(this);
}
