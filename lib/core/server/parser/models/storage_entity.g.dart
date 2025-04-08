// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StorageEntity _$StorageEntityFromJson(Map<String, dynamic> json) =>
    StorageEntity(
      parentAlias: json['parentAlias'] as String,
      path: json['path'] as String,
    );

Map<String, dynamic> _$StorageEntityToJson(StorageEntity instance) =>
    <String, dynamic>{
      'path': instance.path,
      'parentAlias': instance.parentAlias,
    };
