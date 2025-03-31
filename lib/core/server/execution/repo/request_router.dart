// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/execution/models/flux_request_info.dart';
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/utils/path_utils.dart';

class RequestRouter {
  final HttpRequest _request;
  final RequestProcessor _requestProcessor;
  final List<Middleware> _upperMiddlewares;
  final List<Middleware> _lowerMiddlewares;
  RequestRouter(
    this._request,
    this._requestProcessor, {
    required List<Middleware> lowerMiddlewares,
    required List<Middleware> upperMiddlewares,
  }) : _upperMiddlewares = upperMiddlewares,
       _lowerMiddlewares = lowerMiddlewares;

  RequestRouter._(
    this._request,
    this._requestProcessor,
    this._lowerMiddlewares,
    this._upperMiddlewares,
  ) {
    _run();
  }
  factory RequestRouter.handle(
    HttpRequest request,
    RequestProcessor processor,
    List<Middleware> upperMiddlewares,
    List<Middleware> lowerMiddlewares,
  ) {
    return RequestRouter._(
      request,
      processor,
      upperMiddlewares,
      lowerMiddlewares,
    );
  }

  Future<FluxResponse> _getResponse(
    List<RoutingEntity> entities,
    FluxRequest initRequest,
  ) async {
    if (entities.isEmpty) {
      // here i should return the not found handler
      var res = FluxRequest(_request).response;
      await res.write('no path found', code: HttpStatus.notFound).close();
      return res;
    }
    FluxRequest request = initRequest;
    FluxResponse response = request.response;
    for (var entity in entities) {
      Map<String, String> uriDynamicParams = PathUtils.extractParams(
        initRequest.path,
        entity.pathTemplate,
      );
      var output = await entity.processor(request, response, uriDynamicParams);
      if (output is FluxRequest) {
        request = output;
      } else if (output is FluxResponse) {
        if (!output.closed) {
          await output.close();
        }
        return output;
      }
    }
    throw ServerError('not reached a handler');
  }

  void _run() async {
    String path = _request.uri.path;
    String httpMethod = _request.method;
    HttpMethod method = methodFromString(httpMethod);
    FluxRequest request = FluxRequest(_request);
    FluxRequestInfo info = FluxRequestInfo();
    info.hitAt = now;
    var entities = _requestProcessor.processors(path, method, null);
    entities = [..._upperMiddlewares, ...entities, ..._lowerMiddlewares];
    await _getResponse(entities, request);
    info.leftAt = now;
  }
}
