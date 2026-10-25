// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency.dart';
import 'space_kind.dart';

part 'space.g.dart';

@JsonSerializable()
class Space {
  const Space({
    required this.id,
    required this.name,
    required this.defaultCurrency,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Space.fromJson(Map<String, Object?> json) => _$SpaceFromJson(json);

  final String id;
  final String name;
  final Currency defaultCurrency;
  final SpaceKind kind;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$SpaceToJson(this);
}
