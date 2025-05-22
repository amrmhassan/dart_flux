import 'package:dart_flux/core/server/parser/interface/form_field_interface.dart';

/// A class representing a file form field where the file is stored as a path.
///
/// This class extends the [FormFieldInterface] and is used to store a file field
/// from a form submission, where the file's data is stored as a file path.
class FileFormField extends FormFieldInterface {
  /// The key associated with the form field.
  ///
  /// This key corresponds to the field's name in the form, used for identifying
  /// the field in the form data.
  @override
  final String? key;

  /// The file path where the uploaded file is stored.
  ///
  /// This is the location in the file system where the uploaded file is saved.
  final String path;

  /// Creates an instance of [FileFormField].
  ///
  /// - [key]: The key for the form field (the field's name).
  /// - [path]: The file path where the file is stored on the server.
  FileFormField(this.key, this.path) : super(key, path);
}
