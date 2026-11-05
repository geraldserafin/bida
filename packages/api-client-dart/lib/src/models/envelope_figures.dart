// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'envelope_figures.g.dart';

@JsonSerializable()
class EnvelopeFigures {
  const EnvelopeFigures({
    required this.envelopeId,
    required this.name,
    required this.color,
    required this.icon,
    required this.archived,
    required this.planMinor,
    required this.manualMinor,
    required this.recurringMinor,
    required this.spentMinor,
    required this.leftMinor,
    required this.sharePercent,
    required this.previousSpentMinor,
  });

  factory EnvelopeFigures.fromJson(Map<String, Object?> json) =>
      _$EnvelopeFiguresFromJson(json);

  final String envelopeId;
  final String name;
  final String color;
  @JsonKey(includeIfNull: true)
  final String? icon;
  final bool archived;
  final int planMinor;
  final int manualMinor;
  final int recurringMinor;
  final int spentMinor;
  final int leftMinor;
  final dynamic sharePercent;
  @JsonKey(includeIfNull: true)
  final int? previousSpentMinor;

  Map<String, Object?> toJson() => _$EnvelopeFiguresToJson(this);
}
