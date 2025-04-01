// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:dart_flux/core/server/routing/interface/http_entity.dart';
import 'package:dart_flux/core/server/routing/models/context.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';

class FluxRequest extends HttpEntity {
  final HttpRequest _request;
  FluxRequest(this._request);
  Context context = Context();

  HttpHeaders get headers => _request.headers;
  Uri get uri => _request.uri;
  Uri get requestedUri => _request.requestedUri;
  String get path => _request.uri.path;
  Map<String, String> get queryParameters => _request.uri.queryParameters;

  @override
  int get hashCode => _request.hashCode;

  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }

  FluxResponse get response => FluxResponse(_request);
  HttpMethod get method => methodFromString(_request.method);
}
