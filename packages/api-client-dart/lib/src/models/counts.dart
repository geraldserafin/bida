// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'counts.g.dart';

@JsonSerializable()
class Counts {
  const Counts({
    required this.categories,
    required this.periods,
    required this.envelopes,
    required this.expenses,
    required this.recurringRules,
  });

  factory Counts.fromJson(Map<String, Object?> json) => _$CountsFromJson(json);

  final int categories;
  final int periods;
  final int envelopes;
  final int expenses;
  final int recurringRules;

  Map<String, Object?> toJson() => _$CountsToJson(this);
}
