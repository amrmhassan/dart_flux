import 'package:dart_flux/core/server/routing/interface/form_field_interface.dart';

class TextFormField extends FormFieldInterface {
  final String? key;
  final String value;
  TextFormField(this.key, this.value) : super(key, value);
}

class FileFormField extends FormFieldInterface {
  final String? key;
  final String path;
  FileFormField(this.key, this.path) : super(key, path);
}

class BytesFormField extends FormFieldInterface {
  final String? key;
  final List<int> bytes;
  BytesFormField(this.key, this.bytes) : super(key, bytes);
}
