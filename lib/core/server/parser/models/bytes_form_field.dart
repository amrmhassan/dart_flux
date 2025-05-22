import 'package:dart_flux/core/server/parser/interface/form_field_interface.dart';

/// A class representing a file form field containing raw byte data.
///
/// This class extends the [FormFieldInterface] and is used to store a file field
/// from a form submission, where the file's data is stored as a list of bytes.
class BytesFormField extends FormFieldInterface {
  /// The key associated with the form field.
  ///
  /// This key corresponds to the field's name in the form, used for identifying
  /// the field in the form data.
  final String? key;

  /// The raw byte data of the file.
  ///
  /// This list contains the byte data of the file that was submitted as part
  /// of a multipart form request.
  final List<int> bytes;
  final Map<String, dynamic>? meta;

  /// Creates an instance of [BytesFormField].
  ///
  /// - [key]: The key for the form field.
  /// - [bytes]: The byte data of the file field.
  BytesFormField(this.key, this.bytes, {this.meta})
    : super(key, bytes, meta: meta);
}
