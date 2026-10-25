// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unauthorized.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Unauthorized _$UnauthorizedFromJson(Map<String, dynamic> json) =>
    Unauthorized(privateTag: UnauthorizedTag.fromJson(json['_tag'] as String));

Map<String, dynamic> _$UnauthorizedToJson(Unauthorized instance) =>
    <String, dynamic>{'_tag': _$UnauthorizedTagEnumMap[instance.privateTag]!};

const _$UnauthorizedTagEnumMap = {
  UnauthorizedTag.unauthorized: 'Unauthorized',
  UnauthorizedTag.$unknown: r'$unknown',
};
