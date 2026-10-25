// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'create_allocation.g.dart';

@JsonSerializable()
class CreateAllocation {
  const CreateAllocation({
    required this.envelopeId,
    required this.amountMinor,
    required this.madeOn,
    required this.note,
  });

  factory CreateAllocation.fromJson(Map<String, Object?> json) =>
      _$CreateAllocationFromJson(json);

  final String envelopeId;
  final int amountMinor;
  final String madeOn;
  @JsonKey(includeIfNull: true)
  final String? note;

  Map<String, Object?> toJson() => _$CreateAllocationToJson(this);
}
