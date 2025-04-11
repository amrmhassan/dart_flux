import 'package:dart_flux/core/server/parser/models/storage_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'folder_entity.g.dart';

@JsonSerializable(explicitToJson: true)
class FolderEntity extends StorageEntity {
  final List<StorageEntity> children;
  FolderEntity({required String path, required this.children})
    : super(path: path, type: EntityType.folder);
  @override
  factory FolderEntity.fromJson(Map<String, dynamic> json) =>
      _$FolderEntityFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$FolderEntityToJson(this);
}
