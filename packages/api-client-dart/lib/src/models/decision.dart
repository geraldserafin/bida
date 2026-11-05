// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'decision.g.dart';

@JsonSerializable()
class Decision {
  const Decision({
    required this.raisePlan,
    required this.transferMinor,
    required this.allowNegativeWallet,
  });

  factory Decision.fromJson(Map<String, Object?> json) =>
      _$DecisionFromJson(json);

  final bool raisePlan;
  final int transferMinor;
  final bool allowNegativeWallet;

  Map<String, Object?> toJson() => _$DecisionToJson(this);
}
