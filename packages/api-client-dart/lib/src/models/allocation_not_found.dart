// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'allocation_not_found_tag.dart';

part 'allocation_not_found.g.dart';

@JsonSerializable()
class AllocationNotFound {
  const AllocationNotFound({required this.privateTag, required this.id});

  factory AllocationNotFound.fromJson(Map<String, Object?> json) =>
      _$AllocationNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final AllocationNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$AllocationNotFoundToJson(this);
}
