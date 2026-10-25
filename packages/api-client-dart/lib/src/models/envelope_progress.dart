// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'envelope_progress.g.dart';

@JsonSerializable()
class EnvelopeProgress {
  const EnvelopeProgress({
    required this.envelopeId,
    required this.categoryId,
    required this.plannedMinor,
    required this.spentMinor,
    required this.remainingMinor,
  });

  factory EnvelopeProgress.fromJson(Map<String, Object?> json) =>
      _$EnvelopeProgressFromJson(json);

  final String envelopeId;
  final String categoryId;
  final int plannedMinor;
  final int spentMinor;
  final int remainingMinor;

  Map<String, Object?> toJson() => _$EnvelopeProgressToJson(this);
}
