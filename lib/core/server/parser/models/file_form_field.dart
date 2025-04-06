import 'package:dart_flux/core/server/parser/interface/form_field_interface.dart';

class FileFormField extends FormFieldInterface {
  final String? key;
  final String path;
  FileFormField(this.key, this.path) : super(key, path);
}
