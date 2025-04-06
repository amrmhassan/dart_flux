import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_flux/core/errors/error_string.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/parser/interface/request_reader_interface.dart';

class RequestReader implements RequestReaderInterface {
  // Constructor to initialize the RequestReader with an HTTP request.
  RequestReader(this.request);

  /// Reads and parses the body of the request as JSON.
  ///
  /// Returns the parsed JSON body if successful.
  /// Throws a [ServerError] if the body is not valid JSON.
  Future<dynamic> readJson() async {
    try {
      // Decodes the string body to JSON.
      var jsonBody = json.decode(await readString());
      return jsonBody;
    } catch (e, s) {
      // Catches any errors during JSON decoding and wraps them in a ServerError.
      throw ServerError.fromCatch(
        msg: errorString.invalidJsonBody,
        status: HttpStatus.badRequest,
        e: e,
        s: s,
        code: errorCode.invalidJsonBody,
      );
    }
  }

  /// Reads the body of the request as a string.
  ///
  /// Returns the string representation of the body if successful.
  /// Throws a [ServerError] if the body cannot be read as a string,
  /// or if the MIME type is unsupported.
  Future<String> readString() async {
    try {
      final contentType = request.headers.contentType;
      var mimeType = contentType?.primaryType;
      List<String> allowedMimes = [
        'application',
        'text',
      ]; // Allowed MIME types (text and application)

      // Check if the MIME type is supported.
      if (!allowedMimes.any((element) => element == mimeType)) {
        throw ServerError(
          errorString.invalidStringBody,
          status: HttpStatus.unsupportedMediaType,
        );
      }

      // If charset is defined in the content type, use the corresponding decoder.
      if (contentType != null && contentType.charset != null) {
        final decoder = Encoding.getByName(contentType.charset!);
        if (decoder != null) {
          // Decode the body using the specified charset.
          var decodedBody = decoder.decode(await readBytes());
          return decodedBody;
        }
      }

      // Default to UTF-8 if no charset is specified.
      var decodedBody = await utf8.decoder.bind(request).join();
      return decodedBody;
    } catch (e, s) {
      // Catch any errors during string reading and throw a ServerError.
      throw ServerError.fromCatch(
        msg: errorString.invalidStringBody,
        status: HttpStatus.badRequest,
        e: e,
        s: s,
        code: errorCode.invalidStringBody,
      );
    }
  }

  /// Reads the body of the request as a list of bytes.
  ///
  /// Returns the body as a list of bytes if successful.
  /// Throws a [ServerError] if the body cannot be read as bytes.
  Future<List<int>> readBytes() async {
    try {
      final completer =
          Completer<List<int>>(); // Completer to handle asynchronous operation.
      final bytes = <int>[]; // List to accumulate byte data.

      // Listen to the request body and accumulate the byte data.
      request.listen(
        (data) {
          bytes.addAll(data); // Add each chunk of data to the byte list.
        },
        onDone: () => completer.complete(bytes), // Complete when done reading.
        onError:
            (error) => completer.completeError(
              error,
            ), // Complete with error if any occurs.
        cancelOnError: true, // Cancel the stream if there is an error.
      );

      // Return the list of bytes when done.
      return completer.future;
    } catch (e, s) {
      // Catch any errors during byte reading and throw a ServerError.
      throw ServerError.fromCatch(
        msg: errorString.invalidBytesBody,
        status: HttpStatus.badRequest,
        e: e,
        s: s,
        code: errorCode.invalidBytesBody,
      );
    }
  }

  // The HTTP request being processed.
  @override
  HttpRequest request;
}
