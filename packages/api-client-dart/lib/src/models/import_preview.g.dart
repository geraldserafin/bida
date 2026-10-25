// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_preview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportPreview _$ImportPreviewFromJson(Map<String, dynamic> json) =>
    ImportPreview(
      incoming: Counts.fromJson(json['incoming'] as Map<String, dynamic>),
      current: Counts.fromJson(json['current'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ImportPreviewToJson(ImportPreview instance) =>
    <String, dynamic>{
      'incoming': instance.incoming,
      'current': instance.current,
    };
