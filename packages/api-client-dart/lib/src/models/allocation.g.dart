// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allocation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Allocation _$AllocationFromJson(Map<String, dynamic> json) => Allocation(
  id: json['id'] as String,
  envelopeId: json['envelopeId'] as String,
  userId: json['userId'] as String,
  amountMinor: (json['amountMinor'] as num).toInt(),
  madeOn: json['madeOn'] as String,
  note: json['note'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$AllocationToJson(Allocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'envelopeId': instance.envelopeId,
      'userId': instance.userId,
      'amountMinor': instance.amountMinor,
      'madeOn': instance.madeOn,
      'note': instance.note,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
