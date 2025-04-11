import 'package:dart_flux/core/server/parser/models/storage_entity.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(explicitToJson: true)
class FileEntity extends StorageEntity {
  FileEntity({required String path}) : super(type: EntityType.file, path: path);
}
