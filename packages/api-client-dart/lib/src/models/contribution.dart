// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'contribution.g.dart';

@JsonSerializable()
class Contribution {
  const Contribution({
    required this.id,
    required this.periodId,
    required this.userId,
    required this.amountMinor,
    required this.contributedAt,
    required this.note,
    required this.createdAt,
  });

  factory Contribution.fromJson(Map<String, Object?> json) =>
      _$ContributionFromJson(json);

  final String id;
  final String periodId;
  @JsonKey(includeIfNull: true)
  final String? userId;
  final int amountMinor;
  final String contributedAt;
  @JsonKey(includeIfNull: true)
  final String? note;
  final String createdAt;

  Map<String, Object?> toJson() => _$ContributionToJson(this);
}
