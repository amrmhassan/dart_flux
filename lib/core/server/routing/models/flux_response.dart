import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/routing/interface/http_entity.dart';

class FluxResponse extends HttpEntity {
  final HttpRequest _request;
  bool _closed = false;
  bool get closed => _closed;

  FluxResponse(this._request);
  HttpResponse get _response => _request.response;
  Future<FluxResponse> close() async {
    if (_closed) {
      throw ServerError('Response is already closed');
    }
    await _response.close();
    _closed = true;
    return this;
  }

  FluxResponse write(Object? object, {int code = 500}) {
    if (_closed) {
      throw ServerError('Response is already closed');
    }
    _response.statusCode = code;
    _response.write(object);
    return this;
  }

  FluxResponse add(List<int> data, {int code = 500}) {
    if (_closed) {
      throw ServerError('Response is already closed');
    }
    _response.headers.contentLength = data.length;
    _response.statusCode = code;
    _response.add(data);
    return this;
  }

  int get code => _response.statusCode;
  HttpResponse get response => _request.response;
  HttpHeaders get headers => response.headers;
  set statusCode(int code) => response.statusCode;
}
