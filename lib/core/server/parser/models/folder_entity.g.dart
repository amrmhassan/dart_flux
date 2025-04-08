// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FolderEntity _$FolderEntityFromJson(Map<String, dynamic> json) => FolderEntity(
  parentAlias: json['parentAlias'] as String,
  path: json['path'] as String,
  children:
      (json['children'] as List<dynamic>)
          .map((e) => StorageEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$FolderEntityToJson(FolderEntity instance) =>
    <String, dynamic>{
      'path': instance.path,
      'parentAlias': instance.parentAlias,
      'children': instance.children.map((e) => e.toJson()).toList(),
    };
