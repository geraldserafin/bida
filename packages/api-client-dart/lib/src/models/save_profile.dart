// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'save_profile.g.dart';

@JsonSerializable()
class SaveProfile {
  const SaveProfile({required this.name});

  factory SaveProfile.fromJson(Map<String, Object?> json) =>
      _$SaveProfileFromJson(json);

  final String name;

  Map<String, Object?> toJson() => _$SaveProfileToJson(this);
}
