import 'dart:io';

import 'package:dart_flux/core/server/routing/interface/http_entity.dart';

class FluxResponse extends HttpEntity {
  final HttpRequest _request;

  FluxResponse(this._request);
  HttpResponse get _response => _request.response;
  Future<FluxResponse> close() async {
    await _response.close();
    return this;
  }

  FluxResponse write(Object? object, {int? code}) {
    if (code != null) {
      _response.statusCode = code;
    }
    _response.write(object);
    return this;
  }

  FluxResponse add(List<int> data) {
    _response.headers.contentLength = data.length;
    _response.add(data);
    return this;
  }
}
