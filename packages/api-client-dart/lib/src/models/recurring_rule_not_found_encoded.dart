// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'recurring_rule_not_found_encoded_tag.dart';

part 'recurring_rule_not_found_encoded.g.dart';

@JsonSerializable()
class RecurringRuleNotFoundEncoded {
  const RecurringRuleNotFoundEncoded({
    required this.privateTag,
    required this.id,
  });

  factory RecurringRuleNotFoundEncoded.fromJson(Map<String, Object?> json) =>
      _$RecurringRuleNotFoundEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final RecurringRuleNotFoundEncodedTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$RecurringRuleNotFoundEncodedToJson(this);
}
