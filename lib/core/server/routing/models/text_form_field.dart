import 'package:dart_flux/core/server/routing/interface/form_field_interface.dart';

class TextFormField extends FormFieldInterface {
  final String? key;
  final String value;
  TextFormField(this.key, this.value) : super(key, value);
}
