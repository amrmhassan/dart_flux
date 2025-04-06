// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:dart_flux/core/server/routing/interface/form_data_interface.dart';
import 'package:dart_flux/core/server/routing/interface/form_field_interface.dart';
import 'package:dart_flux/core/server/routing/models/file_form_field.dart';
import 'package:dart_flux/core/server/routing/models/text_form_field.dart';

class FormData extends FormDataInterface {
  final List<TextFormField> fields;
  final List<FileFormField> files;
  FormData({required this.fields, required this.files})
    : super(fields: fields, files: files);

  @override
  FormFieldInterface? getField(String key) {
    return fields.cast().firstWhere(
      (element) => element.key == key,
      orElse: () => null,
    );
  }

  @override
  File? getFile(String key) {
    String? filePath =
        files
            .cast()
            .firstWhere((element) => element.key == key, orElse: () => null)
            .value;
    if (filePath == null) {
      return null;
    }
    return File(filePath);
  }
}

class z {}
