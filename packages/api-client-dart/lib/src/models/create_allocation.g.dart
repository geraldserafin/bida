// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_allocation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAllocation _$CreateAllocationFromJson(Map<String, dynamic> json) =>
    CreateAllocation(
      envelopeId: json['envelopeId'] as String,
      amountMinor: (json['amountMinor'] as num).toInt(),
      madeOn: json['madeOn'] as String,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$CreateAllocationToJson(CreateAllocation instance) =>
    <String, dynamic>{
      'envelopeId': instance.envelopeId,
      'amountMinor': instance.amountMinor,
      'madeOn': instance.madeOn,
      'note': instance.note,
    };
