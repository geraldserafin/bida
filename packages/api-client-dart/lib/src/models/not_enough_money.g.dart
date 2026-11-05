// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'not_enough_money.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotEnoughMoney _$NotEnoughMoneyFromJson(Map<String, dynamic> json) =>
    NotEnoughMoney(
      privateTag: NotEnoughMoneyTag.fromJson(json['_tag'] as String),
      availableMinor: (json['availableMinor'] as num).toInt(),
    );

Map<String, dynamic> _$NotEnoughMoneyToJson(NotEnoughMoney instance) =>
    <String, dynamic>{
      '_tag': _$NotEnoughMoneyTagEnumMap[instance.privateTag]!,
      'availableMinor': instance.availableMinor,
    };

const _$NotEnoughMoneyTagEnumMap = {
  NotEnoughMoneyTag.notEnoughMoney: 'NotEnoughMoney',
  NotEnoughMoneyTag.$unknown: r'$unknown',
};
