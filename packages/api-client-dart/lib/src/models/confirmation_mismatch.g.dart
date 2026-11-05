// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirmation_mismatch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfirmationMismatch _$ConfirmationMismatchFromJson(
  Map<String, dynamic> json,
) => ConfirmationMismatch(
  privateTag: ConfirmationMismatchTag.fromJson(json['_tag'] as String),
);

Map<String, dynamic> _$ConfirmationMismatchToJson(
  ConfirmationMismatch instance,
) => <String, dynamic>{
  '_tag': _$ConfirmationMismatchTagEnumMap[instance.privateTag]!,
};

const _$ConfirmationMismatchTagEnumMap = {
  ConfirmationMismatchTag.confirmationMismatch: 'ConfirmationMismatch',
  ConfirmationMismatchTag.$unknown: r'$unknown',
};
