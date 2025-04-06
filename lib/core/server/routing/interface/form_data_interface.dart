import 'package:dart_flux/core/server/routing/interface/form_field_interface.dart';
import 'package:dart_flux/core/server/routing/models/text_form_field.dart';

abstract class FormDataInterface {
  late List<TextFormField> fields;
  late List<dynamic> files;

  FormDataInterface({required this.fields, required this.files});
  FormFieldInterface? getField(String key);

  dynamic getFile(String key);
}
