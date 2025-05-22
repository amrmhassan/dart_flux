// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:dart_flux/core/server/parser/interface/form_data_interface.dart';
import 'package:dart_flux/core/server/parser/interface/form_field_interface.dart';
import 'package:dart_flux/core/server/parser/models/bytes_form_field.dart';
import 'package:dart_flux/core/server/parser/models/text_form_field.dart';

/// A class representing form data that includes both text fields and file fields.
///
/// This class extends the [FormDataInterface] and provides the functionality to
/// handle form data, including retrieving form fields and file fields. The data
/// is stored as a combination of text fields ([TextFormField]) and file fields
/// ([BytesFormField]), where the latter contains raw byte data.
class BytesFormData extends FormDataInterface {
  @override
  final List<TextFormField> fields;

  @override
  final List<BytesFormField> files;

  /// Creates an instance of [BytesFormData].
  ///
  /// Takes a list of [TextFormField] for the text fields and a list of
  /// [BytesFormField] for the file fields. These fields represent the data
  /// sent in a multipart form request.
  ///
  /// - [fields]: The list of text form fields in the form data.
  /// - [files]: The list of file form fields in the form data, containing byte data.
  BytesFormData({required this.fields, required this.files})
    : super(fields: fields, files: files);

  /// Retrieves a [TextFormField] by its key.
  ///
  /// Searches the list of [TextFormField] for a field with the specified [key].
  /// If the key is found, returns the corresponding [TextFormField], otherwise
  /// returns `null`.
  ///
  /// - [key]: The key associated with the form field.
  @override
  List<FormFieldInterface> getField(String key) {
    return fields.where((element) => element.key == key).toList();
  }

  /// Retrieves a [BytesFormField] by its key.
  ///
  /// Searches the list of [BytesFormField] for a field with the specified [key].
  /// If the key is found, returns the corresponding [BytesFormField], otherwise
  /// returns `null`.
  ///
  /// - [key]: The key associated with the file field.
  @override
  List<BytesFormField> getFile(String key) {
    List<BytesFormField> file =
        files.where((element) => element.key == key).toList();
    return file;
  }
}
