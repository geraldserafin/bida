// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cycle _$CycleFromJson(Map<String, dynamic> json) => Cycle(
  kind: CycleKind.fromJson(json['kind'] as String),
  day: (json['day'] as num?)?.toInt(),
  weeks: (json['weeks'] as num?)?.toInt(),
  anchorOn: json['anchorOn'] as String?,
);

Map<String, dynamic> _$CycleToJson(Cycle instance) => <String, dynamic>{
  'kind': _$CycleKindEnumMap[instance.kind]!,
  'day': instance.day,
  'weeks': instance.weeks,
  'anchorOn': instance.anchorOn,
};

const _$CycleKindEnumMap = {
  CycleKind.monthly: 'monthly',
  CycleKind.weeks: 'weeks',
  CycleKind.manual: 'manual',
  CycleKind.$unknown: r'$unknown',
};
