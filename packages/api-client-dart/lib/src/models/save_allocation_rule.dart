// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'save_allocation_rule.g.dart';

@JsonSerializable()
class SaveAllocationRule {
  const SaveAllocationRule({
    required this.envelopeId,
    required this.amountMinor,
    required this.dayOfMonth,
    required this.note,
    required this.active,
  });

  factory SaveAllocationRule.fromJson(Map<String, Object?> json) =>
      _$SaveAllocationRuleFromJson(json);

  final String envelopeId;
  final int amountMinor;
  final int dayOfMonth;
  @JsonKey(includeIfNull: true)
  final String? note;
  final bool active;

  Map<String, Object?> toJson() => _$SaveAllocationRuleToJson(this);
}
