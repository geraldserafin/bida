// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency.dart';

part 'save_space.g.dart';

@JsonSerializable()
class SaveSpace {
  const SaveSpace({required this.name, required this.defaultCurrency});

  factory SaveSpace.fromJson(Map<String, Object?> json) =>
      _$SaveSpaceFromJson(json);

  final String name;
  final Currency defaultCurrency;

  Map<String, Object?> toJson() => _$SaveSpaceToJson(this);
}
