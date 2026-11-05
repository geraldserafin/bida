// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'correction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Correction _$CorrectionFromJson(Map<String, dynamic> json) => Correction(
  allowNegative: json['allowNegative'] as bool,
  withdrawFromPeriodId: json['withdrawFromPeriodId'] as String?,
);

Map<String, dynamic> _$CorrectionToJson(Correction instance) =>
    <String, dynamic>{
      'allowNegative': instance.allowNegative,
      'withdrawFromPeriodId': instance.withdrawFromPeriodId,
    };
