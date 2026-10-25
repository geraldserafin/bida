// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'add_contribution.g.dart';

@JsonSerializable()
class AddContribution {
  const AddContribution({
    required this.amountMinor,
    required this.contributedAt,
    required this.note,
    this.externalValue,
  });

  factory AddContribution.fromJson(Map<String, Object?> json) =>
      _$AddContributionFromJson(json);

  final int amountMinor;
  final String contributedAt;
  @JsonKey(includeIfNull: true)
  final String? note;

  /// The name has been replaced because it contains a keyword. Original name: `external`.
  /// The name has been replaced because it contains a keyword. Original name: `external`.
  /// The name has been replaced because it contains a keyword. Original name: `external`.
  @JsonKey(includeIfNull: false, name: 'external')
  final bool? externalValue;

  Map<String, Object?> toJson() => _$AddContributionToJson(this);
}
