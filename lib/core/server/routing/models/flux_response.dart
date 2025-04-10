import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/routing/interface/http_entity.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';

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
}
