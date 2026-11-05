// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_profile.g.dart';

@JsonSerializable()
class UpdateProfile {
  const UpdateProfile({required this.name});

  factory UpdateProfile.fromJson(Map<String, Object?> json) =>
      _$UpdateProfileFromJson(json);

  @JsonKey(includeIfNull: true)
  final String? name;

  Map<String, Object?> toJson() => _$UpdateProfileToJson(this);
}
