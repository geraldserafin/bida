// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'role.dart';

part 'set_role.g.dart';

@JsonSerializable()
class SetRole {
  const SetRole({required this.role});

  factory SetRole.fromJson(Map<String, Object?> json) =>
      _$SetRoleFromJson(json);

  final Role role;

  Map<String, Object?> toJson() => _$SetRoleToJson(this);
}
