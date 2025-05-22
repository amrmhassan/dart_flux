import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/parser/models/folder_server.dart';
import 'package:dart_flux/core/server/routing/interface/http_entity.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';

/// The FluxResponse class wraps around the HttpResponse object and provides methods
/// for managing the HTTP response during request processing, including writing content
/// and closing the response.
class FluxResponse extends HttpEntity {
  final HttpRequest _request;
  bool _closed = false;

  // Indicates whether the response has been closed
  bool get closed => _closed;

  // Constructor that accepts an HttpRequest and initializes the FluxResponse
  FluxResponse(this._request);

  // Provides access to the underlying HttpResponse of the request
  HttpResponse get _response => _request.response;

  /// Closes the response, signaling that no more data will be written.
  ///
  /// If the response is already closed, an error is thrown.
  Future<FluxResponse> close() async {
    if (_closed) {
      throw ServerError('Response is already closed');
    }
    await _response.close();
    _closed = true;
    return this;
  }

  /// Writes the provided object to the response body with the specified status code.
  ///
  /// Throws an error if the response has already been closed.
  FluxResponse write(Object? object, {int code = 500}) {
    if (_closed) {
      throw ServerError('Response is already closed');
    }
    _response.statusCode = code;
    _response.write(object);
    return this;
  }

  FluxResponse success(Object? object) {
    return write(object, code: 200);
  }

  /// success response

  /// Adds the provided list of bytes to the response body with the specified status code.
  ///
  /// Throws an error if the response has already been closed.
  FluxResponse add(List<int> data, {int code = 500}) {
    if (_closed) {
      throw ServerError('Response is already closed');
    }
    _response.headers.contentLength = data.length;
    _response.statusCode = code;
    _response.add(data);
    return this;
  }

  // Returns the current status code of the response
  int get code => _response.statusCode;

  Future<FluxResponse> flush() async {
    await _response.flush();
    return this;
  }

  // Provides access to the underlying HttpResponse
  HttpResponse get response => _request.response;
  FluxRequest get request => FluxRequest(_request);

  // Provides access to the headers of the response
  HttpHeaders get headers => response.headers;

  // Allows setting the status code for the response
  set statusCode(int code) => response.statusCode;

  //? response methods
  Future<FluxResponse> error(Object err, {int? status}) =>
      SendResponse.error(this, err, status: status);

  Future<FluxResponse> data(Object data, {int? status}) =>
      SendResponse.data(this, data, status: status);

  Future<FluxResponse> notFound([Object? data]) =>
      SendResponse.notFound(this, data);

  Future<FluxResponse> unauthorized([Object? data]) =>
      SendResponse.unauthorized(this, data);

  Future<FluxResponse> badRequest([Object? data]) =>
      SendResponse.badRequest(this, data);

  Future<FluxResponse> json(
    FluxResponse response,
    Object data, {
    int? status,
  }) => SendResponse.json(this, data, status: status);

  Future<FluxResponse> helloWold() => SendResponse.helloWold(this);

  Future<FluxResponse> html(
    FluxResponse response,
    Object data, {
    int? status,
  }) => SendResponse.html(this, data, status: status);

  Future<FluxResponse> binary(List<int> bytes, {int? status}) =>
      SendResponse.binary(this, bytes, status: status);

  Future<FluxResponse> file(File file) => SendResponse.file(this, file);

  Future<FluxResponse> stream(File file) => SendResponse.stream(this, file);

  Future<FluxResponse> serveFolder({
    required FolderServer server,
    required String requestedPath,
    bool blockIfFolder = true,
    bool serveFolderContent = false,
  }) => SendResponse.serveFolder(
    response: this,
    server: server,
    requestedPath: requestedPath,

    serveFolderContent: serveFolderContent,
    blockIfFolder: blockIfFolder,
  );
}
