import 'package:dart_flux/core/server/parser/models/bytes_form_field.dart';

abstract class BytesFileSaverInterface {
  late BytesFormField fileField;
  Future<String> saveFile();
}
