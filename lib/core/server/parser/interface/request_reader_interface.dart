import 'dart:async';
import 'dart:io';

/// An interface for reading different types of data from an HTTP request.
///
/// This interface defines methods for reading the contents of an HTTP request
/// in various formats, such as JSON, plain text, and raw bytes. It provides
/// a standard way to handle incoming request data in different formats.
abstract class RequestReaderInterface {
  /// The incoming HTTP request.
  ///
  /// This request will be read to extract its content in various formats.
  late HttpRequest request;

  /// Reads the body of the HTTP request as a JSON object.
  ///
  /// This method assumes that the request body is in JSON format and will
  /// deserialize it into a dynamic object. It is typically used for requests
  /// with content type `application/json`.
  ///
  /// Returns the parsed JSON object as a dynamic type.
  Future<dynamic> readJson();

  /// Reads the body of the HTTP request as a plain string.
  ///
  /// This method reads the entire body of the request and returns it as a
  /// string. It is typically used for requests with content type `text/plain`
  /// or for cases where the data is not in JSON format.
  ///
  /// Returns the content of the request as a string.
  Future<String> readString();

  /// Reads the body of the HTTP request as raw bytes.
  ///
  /// This method reads the entire body of the request and returns it as a
  /// list of bytes. It is typically used for requests that contain binary
  /// data, such as file uploads or non-textual content.
  ///
  /// Returns the raw bytes of the request body.
  Future<List<int>> readBytes();
}
