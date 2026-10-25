// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyToken _$VerifyTokenFromJson(Map<String, dynamic> json) => VerifyToken(
  token: json['token'] as String,
  transport: Transport.fromJson(json['transport'] as String),
);

Map<String, dynamic> _$VerifyTokenToJson(VerifyToken instance) =>
    <String, dynamic>{
      'token': instance.token,
      'transport': _$TransportEnumMap[instance.transport]!,
    };

const _$TransportEnumMap = {
  Transport.token: 'token',
  Transport.cookie: 'cookie',
  Transport.$unknown: r'$unknown',
};
