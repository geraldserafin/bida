// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'envelope_figures.dart';

part 'overview.g.dart';

@JsonSerializable()
class Overview {
  const Overview({
    required this.from,
    required this.to,
    required this.incomeMinor,
    required this.allocatedMinor,
    required this.spentMinor,
    required this.poolMinor,
    required this.envelopes,
  });

  factory Overview.fromJson(Map<String, Object?> json) =>
      _$OverviewFromJson(json);

  final String from;
  final String to;
  final int incomeMinor;
  final int allocatedMinor;
  final int spentMinor;
  final int poolMinor;
  final List<EnvelopeFigures> envelopes;

  Map<String, Object?> toJson() => _$OverviewToJson(this);
}
