import 'dart:io';

import 'package:dart_flux/core/server/parser/models/bytes_form_data.dart';
import 'package:dart_flux/core/server/parser/models/form_data.dart';

/// An interface for handling multipart form data parsing.
///
/// This interface defines methods for processing and handling multipart form
/// data, such as reading form data, processing files, and saving received files.
/// It includes methods for both form fields and raw bytes, giving flexibility in how form data is handled.
abstract class MultiPartInterface {
  /// The incoming HTTP request containing multipart form data.
  ///
  /// This request will be processed to extract form fields and files.
  late HttpRequest request;

  /// Reads and parses form data from the incoming request.
  ///
  /// [saveFolder]: The folder where files should be saved if present in the form data.
  /// [acceptFormFiles]: Whether to accept and process file uploads. If true, the method
  /// will look for files in the form data and handle them accordingly.
  ///
  /// Returns a [FormData] object containing the parsed form fields and files.
  Future<FormData> readForm({required String saveFolder, bool acceptFormFiles});

  /// Reads the form data as raw bytes from the incoming request.
  ///
  /// [acceptFormFiles]: Whether to accept and process file uploads. If true, it will
  /// handle files in the form data as well.
  ///
  /// Returns a [BytesFormData] object containing the form data as raw byte arrays.
  Future<BytesFormData> readFormBytes({bool acceptFormFiles});

  /// Receives a file from the multipart form data and saves it to a specified location.
  ///
  /// [path]: The path where the file should be saved.
  /// [throwErrorIfExist]: If true, throws an error if the file already exists at the given path.
  /// [overrideIfExist]: If true, overrides an existing file at the given path.
  ///
  /// Returns a [File] object pointing to the saved file.
  Future<File> receiveFile({
    required String path,
    bool throwErrorIfExist = true,
    bool overrideIfExist = false,
  });
}
