import 'package:json_annotation/json_annotation.dart';

part 'storage_entity.g.dart';

@JsonSerializable(explicitToJson: true)
class StorageEntity {
  final String path;
  final String parentAlias;

  const StorageEntity({required this.parentAlias, required this.path});
  factory StorageEntity.fromJson(Map<String, dynamic> json) =>
      _$StorageEntityFromJson(json);
  Map<String, dynamic> toJson() => _$StorageEntityToJson(this);
}
