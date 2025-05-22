// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:dart_flux/core/server/routing/models/model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bytes_form_file_meta.g.dart';

@JsonSerializable(explicitToJson: true)
class BytesFormFileMeta {
  final String? name;
  final String? contentType;
  final int? size;
  BytesFormFileMeta({
    required this.name,
    required this.contentType,
    required this.size,
  });

  factory BytesFormFileMeta.fromJson(Json json) =>
      _$BytesFormFileMetaFromJson(json);

  Json toJson() => _$BytesFormFileMetaToJson(this);
}
