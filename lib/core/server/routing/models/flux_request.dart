// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:dart_flux/core/server/routing/interface/http_entity.dart';

class FluxRequest extends HttpEntity {
  final HttpRequest _request;
  FluxRequest(this._request);
  Map<String, dynamic> context = {};

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

  HttpResponse get response => _request.response;
}
