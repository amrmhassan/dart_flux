import 'package:dart_flux/extensions/string_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

part 'storage_entity.g.dart';

@JsonSerializable(explicitToJson: true)
class StorageEntity {
  String path;
  final String? parentAlias;

  StorageEntity({required this.parentAlias, required this.path}) {
    path = path.cleanPath;
  }
  factory StorageEntity.fromJson(Map<String, dynamic> json) =>
      _$StorageEntityFromJson(json);
  Map<String, dynamic> toJson() => _$StorageEntityToJson(this);
}
