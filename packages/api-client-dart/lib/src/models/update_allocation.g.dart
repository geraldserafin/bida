// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_allocation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateAllocation _$UpdateAllocationFromJson(Map<String, dynamic> json) =>
    UpdateAllocation(
      amountMinor: (json['amountMinor'] as num).toInt(),
      madeOn: json['madeOn'] as String,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$UpdateAllocationToJson(UpdateAllocation instance) =>
    <String, dynamic>{
      'amountMinor': instance.amountMinor,
      'madeOn': instance.madeOn,
      'note': instance.note,
    };
