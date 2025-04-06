import 'package:dart_flux/core/server/parser/interface/form_field_interface.dart';
import 'package:dart_flux/core/server/parser/models/text_form_field.dart';

/// An abstract class representing a form data structure.
/// This class contains both form fields and file data submitted in a form.
abstract class FormDataInterface {
  // A list of form fields (TextFormField objects).
  // These fields represent the various input elements in the form.
  late List<TextFormField> fields;

  // A list of files uploaded through the form.
  // This holds the file data, which could be used for further processing.
  late List<dynamic> files;

  /// Constructor that initializes the fields and files.
  ///
  /// [fields]: A list of form fields submitted with the form.
  /// [files]: A list of files uploaded via the form.
  FormDataInterface({required this.fields, required this.files});

  /// Retrieves a specific form field by its key.
  ///
  /// This method returns a [FormFieldInterface] object corresponding to
  /// the field with the specified [key], or `null` if no matching field is found.
  ///
  /// [key]: The identifier of the form field.
  FormFieldInterface? getField(String key);

  /// Retrieves a specific file by its key.
  ///
  /// This method returns the file associated with the given [key]. If no file
  /// exists with the specified key, it will return `null`.
  ///
  /// [key]: The identifier of the uploaded file.
  dynamic getFile(String key);
}
