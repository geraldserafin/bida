// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'negative_share_entry.dart';
import 'negative_share_tag.dart';

part 'negative_share.g.dart';

@JsonSerializable()
class NegativeShare {
  const NegativeShare({required this.privateTag, required this.entries});

  factory NegativeShare.fromJson(Map<String, Object?> json) =>
      _$NegativeShareFromJson(json);

  @JsonKey(name: '_tag')
  final NegativeShareTag privateTag;
  final List<NegativeShareEntry> entries;

  Map<String, Object?> toJson() => _$NegativeShareToJson(this);
}
