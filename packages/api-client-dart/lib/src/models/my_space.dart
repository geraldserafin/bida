// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'role.dart';
import 'space.dart';

part 'my_space.g.dart';

@JsonSerializable()
class MySpace {
  const MySpace({
    required this.space,
    required this.role,
    required this.memberCount,
  });

  factory MySpace.fromJson(Map<String, Object?> json) =>
      _$MySpaceFromJson(json);

  final Space space;
  final Role role;
  final int memberCount;

  Map<String, Object?> toJson() => _$MySpaceToJson(this);
}
