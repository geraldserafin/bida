// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_access_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoogleAccessToken _$GoogleAccessTokenFromJson(Map<String, dynamic> json) =>
    GoogleAccessToken(
      accessToken: json['accessToken'] as String,
      transport: Transport.fromJson(json['transport'] as String),
    );

Map<String, dynamic> _$GoogleAccessTokenToJson(GoogleAccessToken instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'transport': _$TransportEnumMap[instance.transport]!,
    };

const _$TransportEnumMap = {
  Transport.token: 'token',
  Transport.cookie: 'cookie',
  Transport.$unknown: r'$unknown',
};
