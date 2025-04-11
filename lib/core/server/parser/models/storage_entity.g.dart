// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StorageEntity _$StorageEntityFromJson(Map<String, dynamic> json) =>
    StorageEntity(
      path: json['path'] as String,
      type: $enumDecode(_$EntityTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$StorageEntityToJson(StorageEntity instance) =>
    <String, dynamic>{
      'path': instance.path,
      'type': _$EntityTypeEnumMap[instance.type]!,
    };

const _$EntityTypeEnumMap = {
  EntityType.file: 'file',
  EntityType.folder: 'folder',
  EntityType.unknown: 'unknown',
};
