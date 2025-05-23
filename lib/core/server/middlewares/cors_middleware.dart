import 'dart:async';
import 'dart:io';

import 'package:dart_flux/core/server/routing/interface/http_entity.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';

class CorsMiddleware {
  static Middleware get middleware => Middleware(null, null, _corsByPassing);
  static FutureOr<HttpEntity> _corsByPassing(
    FluxRequest request,
    FluxResponse response,
    Map<String, dynamic> pathArgs,
  ) async {
    final response = request.response;
    response.headers.add(
      'Access-Control-Allow-Origin',
      '*',
    ); // Allow requests from any origin
    response.headers.add(
      'Access-Control-Allow-Methods',
      'GET, POST, PUT, DELETE, PATCH, OPTIONS',
    );
    response.headers.add(
      'Access-Control-Allow-Headers',
      '*',
    ); // Allow all headers
    response.headers.add('Access-Control-Allow-Credentials', 'true');
    response.headers.add('Access-Control-Max-Age', '86400');
    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      response.close();
      return response;
    }
    return request;
  }
}
