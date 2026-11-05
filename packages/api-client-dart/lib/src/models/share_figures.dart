// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'share_figures.g.dart';

@JsonSerializable()
class ShareFigures {
  const ShareFigures({
    required this.userId,
    required this.name,
    required this.member,
    required this.transfersMinor,
    required this.withdrawalsMinor,
    required this.forfeitedMinor,
    required this.spentMinor,
    required this.fromNobodyMinor,
    required this.shareMinor,
  });

  factory ShareFigures.fromJson(Map<String, Object?> json) =>
      _$ShareFiguresFromJson(json);

  @JsonKey(includeIfNull: true)
  final String? userId;
  final String name;
  final bool member;
  final int transfersMinor;
  final int withdrawalsMinor;
  final int forfeitedMinor;
  final int spentMinor;
  final int fromNobodyMinor;
  final int shareMinor;

  Map<String, Object?> toJson() => _$ShareFiguresToJson(this);
}
