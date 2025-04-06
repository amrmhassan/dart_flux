import 'package:dart_flux/core/server/routing/interface/form_field_interface.dart';

class BytesFormField extends FormFieldInterface {
  final String? key;
  final List<int> bytes;
  BytesFormField(this.key, this.bytes) : super(key, bytes);
}
