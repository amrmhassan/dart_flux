import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/parser/models/folder_server.dart';
import 'package:dart_flux/core/server/parser/repo/flux_serve_folder.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/utils/response_utils.dart';
import 'dart:convert' as convert;

final ResponseUtils _responseUtils = ResponseUtils();

/// A class to handle writing responses in various formats to the client.
class SendResponse {
  /// A private method that writes the response data to the client with a specific HTTP status code.
  static Future<FluxResponse> _write(
    FluxResponse response,
    Object v,
    int status,
  ) async {
    // Write the data to the response and set the status code.
    response = response.write(v, code: status);

    // Close the response and return it.
    response = await response.close();
    return response;
  }

  /// A method to send an error response.
  /// If the error is a [ServerError], it converts the error to JSON and sends it.
  static Future<FluxResponse> error(
    FluxResponse response,
    Object err, {
    int? status,
  }) {
    if (err is ServerError) {
      // If the error is a ServerError, return it as a JSON response.
      return json(response, err.toJson(), status: status ?? err.status);
    } else {
      // If it's not a ServerError, create a new ServerError and call this method again.
      ServerError e = ServerError(
        err.toString(),
        status: status ?? HttpStatus.internalServerError,
      );
      return error(response, e);
    }
  }

  /// A method to send a data response with a specified status code.
  static Future<FluxResponse> data(
    FluxResponse response,
    Object data, {
    int? status,
  }) {
    // Write the data to the response with the specified status code.
    return _write(response, data, status ?? HttpStatus.ok);
  }

  /// A method to send a "Not Found" error response with a default or custom message.
  static Future<FluxResponse> notFound(FluxResponse response, [Object? data]) {
    return error(
      response,
      data ?? 'Requested data not found',
      status: HttpStatus.notFound,
    );
  }

  /// A method to send an "Unauthorized" error response with a default or custom message.
  static Future<FluxResponse> unauthorized(
    FluxResponse response, [
    Object? data,
  ]) {
    return error(
      response,
      data ?? 'Not authorized',
      status: HttpStatus.unauthorized,
    );
  }

  /// A method to send a "Bad Request" error response with a default or custom message.
  static Future<FluxResponse> badRequest(
    FluxResponse response, [
    Object? data,
  ]) {
    return error(
      response,
      data ?? 'Sent body is not valid',
      status: HttpStatus.badRequest,
    );
  }

  /// A method to send a JSON response.
  static Future<FluxResponse> json(
    FluxResponse response,
    Object data, {
    int? status,
  }) {
    // Set the content type to JSON.
    response.headers.contentType = ContentType.json;

    // Convert the data to JSON and send it in the response.
    return _write(response, convert.json.encode(data), status ?? HttpStatus.ok);
  }

  static Future<FluxResponse> helloWold(FluxResponse response) {
    // Convert the data to JSON and send it in the response.
    return _write(response, 'Hello World', HttpStatus.ok);
  }

  /// A method to send an HTML response.
  static Future<FluxResponse> html(
    FluxResponse response,
    Object data, {
    int? status,
  }) {
    // Set the content type to HTML.
    response.headers.contentType = ContentType.html;

    // Write the data as HTML in the response.
    return _write(response, data, status ?? HttpStatus.ok);
  }

  /// A method to send binary data (e.g., files) in the response.
  static Future<FluxResponse> binary(
    FluxResponse response,
    List<int> bytes, {
    int? status,
  }) async {
    // Set the content type to binary.
    response.headers.contentType = ContentType.binary;
    response.headers.add(HttpHeaders.contentLengthHeader, bytes.length);

    // Add the binary data to the response.
    response.add(bytes, code: HttpStatus.ok);

    // Flush the response buffer to ensure all data is written.
    await response.flush();

    // Close the response.
    return response.close();
  }

  /// A method to send a file in the response by chunking it.
  static Future<FluxResponse> file(FluxResponse response, File file) async {
    // Send the file using the ResponseUtils utility for chunked file transfer.
    await _responseUtils.sendChunkedFile(response.request, file);
    return response.close();
  }

  /// A method to stream a file in the response asynchronously.
  static Future<FluxResponse> stream(FluxResponse response, File file) async {
    // Stream the file to the client.
    await _responseUtils.streamV2(response.request.request, file);
    return response;
  }

  static Future<FluxResponse> serveFolder({
    required FluxResponse response,
    required FolderServer server,
    required String requestedPath,
    bool blockIfFolder = true,
    bool serveFolderContent = false,
  }) async {
    return FluxServeFolder(
      requestedPath: requestedPath,
      response: response,
      server: server,
      blockIfFolder: blockIfFolder,
      serveFolderContent: serveFolderContent,
    ).serve();
  }
}
