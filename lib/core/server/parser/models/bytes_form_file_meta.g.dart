// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bytes_form_file_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BytesFormFileMeta _$BytesFormFileMetaFromJson(Map<String, dynamic> json) =>
    BytesFormFileMeta(
      name: json['name'] as String?,
      contentType: json['contentType'] as String?,
      size: (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BytesFormFileMetaToJson(BytesFormFileMeta instance) =>
    <String, dynamic>{
      'name': instance.name,
      'contentType': instance.contentType,
      'size': instance.size,
    };
