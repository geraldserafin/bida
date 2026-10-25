// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Income _$IncomeFromJson(Map<String, dynamic> json) => Income(
  id: json['id'] as String,
  userId: json['userId'] as String,
  amountMinor: (json['amountMinor'] as num).toInt(),
  receivedOn: json['receivedOn'] as String,
  note: json['note'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$IncomeToJson(Income instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'amountMinor': instance.amountMinor,
  'receivedOn': instance.receivedOn,
  'note': instance.note,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
