/// An interface class representing a form field.
///
/// This class is used to store the data of a form field, which includes the
/// field's key (identifier) and its associated value (the input value).
/// It serves as the base structure for defining form fields in the application.
class FormFieldInterface {
  /// The key or identifier of the form field.
  ///
  /// This is a unique identifier that helps to access or reference the field
  /// when processing the form data. It can be a string representing the field name.
  final String? key;

  /// The value entered in the form field.
  ///
  /// This holds the actual data that was submitted in the form. The value can
  /// be of any type, depending on the form field (e.g., String, number, boolean).
  final dynamic value;

  /// Constructor for initializing a form field with a key and value.
  ///
  /// [key]: The unique identifier for the form field.
  /// [value]: The data entered into the form field by the user.
  FormFieldInterface(this.key, this.value);
}
