// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileEntity _$FileEntityFromJson(Map<String, dynamic> json) => FileEntity(
  parentAlias: json['parentAlias'] as String?,
  path: json['path'] as String,
);

Map<String, dynamic> _$FileEntityToJson(FileEntity instance) =>
    <String, dynamic>{
      'path': instance.path,
      'parentAlias': instance.parentAlias,
    };
