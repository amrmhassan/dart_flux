import 'package:dart_flux/core/server/parser/interface/form_field_interface.dart';

/// A class representing a text form field in a form submission.
///
/// This class extends [FormFieldInterface] and is used to represent a text
/// field submitted as part of a form. The text form field consists of a
/// key-value pair, where the key is the field name and the value is the field's
/// content (the text entered by the user).
class TextFormField extends FormFieldInterface {
  /// The key (field name) of the text form field.
  ///
  /// This is typically the name of the field in the form submission.
  final String? key;

  /// The value (content) of the text form field.
  ///
  /// This is the text input provided by the user in the form field.
  final String value;

  /// Creates an instance of [TextFormField].
  ///
  /// - [key]: The field name for the form field.
  /// - [value]: The value (content) of the text field.
  TextFormField(this.key, this.value) : super(key, value);
}
