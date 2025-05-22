// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:dart_flux/core/server/parser/interface/form_data_interface.dart';
import 'package:dart_flux/core/server/parser/interface/form_field_interface.dart';
import 'package:dart_flux/core/server/parser/models/file_form_field.dart';
import 'package:dart_flux/core/server/parser/models/text_form_field.dart';

/// A class representing form data that includes both text fields and file fields.
///
/// This class extends the [FormDataInterface] and is used to represent the
/// form data submitted via a multipart/form-data request. It contains both
/// text fields and file fields.
class FormData extends FormDataInterface {
  /// A list of text form fields submitted in the form.
  ///
  /// This list contains the textual form fields where each field consists of
  /// a key-value pair representing the field name and its value.
  @override
  final List<TextFormField> fields;

  /// A list of file form fields submitted in the form.
  ///
  /// This list contains file form fields, each representing a file uploaded
  /// as part of the form submission. Each file field consists of a key (field
  /// name) and the file path where the file is stored.
  @override
  final List<FileFormField> files;

  /// Creates an instance of [FormData].
  ///
  /// - [fields]: A list of text form fields.
  /// - [files]: A list of file form fields.
  FormData({required this.fields, required this.files})
    : super(fields: fields, files: files);

  /// Retrieves a text form field by its key.
  ///
  /// - [key]: The key (field name) for the form field.
  ///
  /// Returns the corresponding [FormFieldInterface] if found, otherwise `null`.
  @override
  List<FormFieldInterface> getField(String key) {
    return fields.where((element) => element.key == key).toList();
  }

  /// Retrieves the file corresponding to a file form field by its key.
  ///
  /// - [key]: The key (field name) for the form field.
  ///
  /// Returns a [File] object pointing to the file on disk, or `null` if the
  /// file cannot be found.
  @override
  List<File> getFile(String key) {
    var filesPaths =
        files
            .where((element) => element.key == key)
            .map((e) => File(e.value))
            .toList();

    return filesPaths;
  }
}
