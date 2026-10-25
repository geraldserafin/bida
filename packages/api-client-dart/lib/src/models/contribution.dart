// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'contribution.g.dart';

@JsonSerializable()
class Contribution {
  const Contribution({
    required this.envelopeId,
    required this.userId,
    required this.amountMinor,
  });

  factory Contribution.fromJson(Map<String, Object?> json) =>
      _$ContributionFromJson(json);

  final String envelopeId;
  final String userId;
  final int amountMinor;

  Map<String, Object?> toJson() => _$ContributionToJson(this);
}
