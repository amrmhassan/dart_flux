import 'package:dart_flux/extensions/string_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

part 'storage_entity.g.dart';

@JsonSerializable(explicitToJson: true)
class StorageEntity {
  String path;
  final EntityType type;

  StorageEntity({required this.path, required this.type}) {
    path = path.cleanPath;
  }
  factory StorageEntity.fromJson(Map<String, dynamic> json) =>
      _$StorageEntityFromJson(json);
  Map<String, dynamic> toJson() => _$StorageEntityToJson(this);
}

enum EntityType {
  @JsonValue('files')
  file,
  @JsonValue('folder')
  folder,
  @JsonValue('unknown')
  unknown,
}
