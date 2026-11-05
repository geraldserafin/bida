// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'move_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoveResult _$MoveResultFromJson(Map<String, dynamic> json) => MoveResult(
  move: Move.fromJson(json['move'] as Map<String, dynamic>),
  walletMinor: (json['walletMinor'] as num).toInt(),
  usedUnconfirmed: json['usedUnconfirmed'] as bool,
  plansExceedBalance: json['plansExceedBalance'] as bool,
);

Map<String, dynamic> _$MoveResultToJson(MoveResult instance) =>
    <String, dynamic>{
      'move': instance.move,
      'walletMinor': instance.walletMinor,
      'usedUnconfirmed': instance.usedUnconfirmed,
      'plansExceedBalance': instance.plansExceedBalance,
    };
