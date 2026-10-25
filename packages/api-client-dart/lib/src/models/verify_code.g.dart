// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyCode _$VerifyCodeFromJson(Map<String, dynamic> json) => VerifyCode(
  email: json['email'] as Email,
  code: json['code'] as String,
  transport: Transport.fromJson(json['transport'] as String),
);

Map<String, dynamic> _$VerifyCodeToJson(VerifyCode instance) =>
    <String, dynamic>{
      'email': instance.email,
      'code': instance.code,
      'transport': _$TransportEnumMap[instance.transport]!,
    };

const _$TransportEnumMap = {
  Transport.token: 'token',
  Transport.cookie: 'cookie',
  Transport.$unknown: r'$unknown',
};
