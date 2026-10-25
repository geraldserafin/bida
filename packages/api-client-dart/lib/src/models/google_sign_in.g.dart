// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_sign_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoogleSignIn _$GoogleSignInFromJson(Map<String, dynamic> json) => GoogleSignIn(
  idToken: json['idToken'] as String,
  transport: Transport.fromJson(json['transport'] as String),
);

Map<String, dynamic> _$GoogleSignInToJson(GoogleSignIn instance) =>
    <String, dynamic>{
      'idToken': instance.idToken,
      'transport': _$TransportEnumMap[instance.transport]!,
    };

const _$TransportEnumMap = {
  Transport.token: 'token',
  Transport.cookie: 'cookie',
  Transport.$unknown: r'$unknown',
};
