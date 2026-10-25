// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'envelope_figures.g.dart';

@JsonSerializable()
class EnvelopeFigures {
  const EnvelopeFigures({
    required this.envelopeId,
    required this.parentId,
    required this.openingMinor,
    required this.allocatedMinor,
    required this.spentMinor,
    required this.balanceMinor,
    required this.freeMinor,
  });

  factory EnvelopeFigures.fromJson(Map<String, Object?> json) =>
      _$EnvelopeFiguresFromJson(json);

  final String envelopeId;
  @JsonKey(includeIfNull: true)
  final String? parentId;
  final int openingMinor;
  final int allocatedMinor;
  final int spentMinor;
  final int balanceMinor;
  final int freeMinor;

  Map<String, Object?> toJson() => _$EnvelopeFiguresToJson(this);
}
