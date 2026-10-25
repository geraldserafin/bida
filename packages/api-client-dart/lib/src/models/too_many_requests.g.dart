// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'too_many_requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TooManyRequests _$TooManyRequestsFromJson(Map<String, dynamic> json) =>
    TooManyRequests(
      privateTag: TooManyRequestsTag.fromJson(json['_tag'] as String),
    );

Map<String, dynamic> _$TooManyRequestsToJson(TooManyRequests instance) =>
    <String, dynamic>{
      '_tag': _$TooManyRequestsTagEnumMap[instance.privateTag]!,
    };

const _$TooManyRequestsTagEnumMap = {
  TooManyRequestsTag.tooManyRequests: 'TooManyRequests',
  TooManyRequestsTag.$unknown: r'$unknown',
};
