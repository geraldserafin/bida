// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_allocation.g.dart';

@JsonSerializable()
class UpdateAllocation {
  const UpdateAllocation({
    required this.amountMinor,
    required this.madeOn,
    required this.note,
  });

  factory UpdateAllocation.fromJson(Map<String, Object?> json) =>
      _$UpdateAllocationFromJson(json);

  final int amountMinor;
  final String madeOn;
  @JsonKey(includeIfNull: true)
  final String? note;

  Map<String, Object?> toJson() => _$UpdateAllocationToJson(this);
}
