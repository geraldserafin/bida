// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'allocation.g.dart';

@JsonSerializable()
class Allocation {
  const Allocation({
    required this.id,
    required this.envelopeId,
    required this.userId,
    required this.amountMinor,
    required this.madeOn,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Allocation.fromJson(Map<String, Object?> json) =>
      _$AllocationFromJson(json);

  final String id;
  final String envelopeId;
  final String userId;
  final int amountMinor;
  final String madeOn;
  @JsonKey(includeIfNull: true)
  final String? note;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$AllocationToJson(this);
}
