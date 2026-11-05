// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'move.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Move _$MoveFromJson(Map<String, dynamic> json) => Move(
  id: json['id'] as String,
  periodId: json['periodId'] as String,
  kind: MoveKind.fromJson(json['kind'] as String),
  userId: json['userId'] as String?,
  userName: json['userName'] as String?,
  amountMinor: (json['amountMinor'] as num).toInt(),
  madeAt: json['madeAt'] as String,
  ruleId: json['ruleId'] as String?,
);

Map<String, dynamic> _$MoveToJson(Move instance) => <String, dynamic>{
  'id': instance.id,
  'periodId': instance.periodId,
  'kind': _$MoveKindEnumMap[instance.kind]!,
  'userId': instance.userId,
  'userName': instance.userName,
  'amountMinor': instance.amountMinor,
  'madeAt': instance.madeAt,
  'ruleId': instance.ruleId,
};

const _$MoveKindEnumMap = {
  MoveKind.transfer: 'transfer',
  MoveKind.withdrawal: 'withdrawal',
  MoveKind.carry: 'carry',
  MoveKind.forfeit: 'forfeit',
  MoveKind.$unknown: r'$unknown',
};
