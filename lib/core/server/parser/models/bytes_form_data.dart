// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dart_flux/core/server/parser/interface/form_data_interface.dart';
import 'package:dart_flux/core/server/parser/interface/form_field_interface.dart';
import 'package:dart_flux/core/server/parser/models/bytes_form_field.dart';
import 'package:dart_flux/core/server/parser/models/text_form_field.dart';

class BytesFormData extends FormDataInterface {
  @override
  final List<TextFormField> fields;
  @override
  final List<BytesFormField> files;
  BytesFormData({required this.fields, required this.files})
    : super(fields: fields, files: files);

  @override
  FormFieldInterface? getField(String key) {
    return fields.cast().firstWhere(
      (element) => element.key == key,
      orElse: () => null,
    );
  }

  @override
  BytesFormField? getFile(String key) {
    BytesFormField? file = files.cast().firstWhere(
      (element) => element.key == key,
      orElse: () => null,
    );
    return file;
  }
}
