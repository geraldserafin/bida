// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'last_envelope_tag.dart';

part 'last_envelope.g.dart';

@JsonSerializable()
class LastEnvelope {
  const LastEnvelope({required this.privateTag});

  factory LastEnvelope.fromJson(Map<String, Object?> json) =>
      _$LastEnvelopeFromJson(json);

  @JsonKey(name: '_tag')
  final LastEnvelopeTag privateTag;

  Map<String, Object?> toJson() => _$LastEnvelopeToJson(this);
}
