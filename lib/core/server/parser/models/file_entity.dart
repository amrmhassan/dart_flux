import 'package:dart_flux/core/server/parser/models/storage_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'file_entity.g.dart';

@JsonSerializable(explicitToJson: true)
class FileEntity extends StorageEntity {
  FileEntity({required String path}) : super(type: EntityType.file, path: path);
  @override
  factory FileEntity.fromJson(Map<String, dynamic> json) =>
      _$FileEntityFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$FileEntityToJson(this);
}
