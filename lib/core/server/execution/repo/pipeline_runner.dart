// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/server/routing/interface/http_entity.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';
import 'package:dart_flux/utils/path_utils.dart';

class PipelineRunner {
  final List<Middleware> _systemUpper;
  final List<Middleware> _systemLower;
  final List<Middleware> _upperMiddlewares;
  final List<Middleware> _lowerMiddlewares;
  FluxRequest _request;
  FluxResponse _response;
  final List<RoutingEntity> _entities;

  PipelineRunner({
    required List<Middleware> systemUpper,
    required List<Middleware> systemLower,
    required List<Middleware> upperMiddlewares,
    required List<Middleware> lowerMiddlewares,
    required FluxRequest request,
    required FluxResponse response,
    required List<RoutingEntity> entities,
  }) : _request = request,
       _response = response,
       _entities = entities,
       _lowerMiddlewares = lowerMiddlewares,
       _upperMiddlewares = upperMiddlewares,
       _systemLower = systemLower,
       _systemUpper = systemUpper;

  Future<FluxResponse> _error(Object e, StackTrace s) async {
    _response = await SendResponse.error(_response, e);
    logger.e(e);
    logger.e(s);
    return _response;
  }

  Map<String, String> _params(RoutingEntity entity) {
    String requestPath = _request.path;
    String? entityPath = entity.finalPath;
    var params = PathUtils.extractParams(requestPath, entityPath);
    return params;
  }

  Future<HttpEntity> _runMiddlewares(List<Middleware> middlewares) async {
    try {
      HttpEntity? output;
      for (var middleware in middlewares) {
        output = await middleware.processor(
          _request,
          _response,
          _params(middleware),
        );

        if (output is FluxRequest) {
          _request = output;
        } else if (output is FluxResponse) {
          _response = output;
        }
      }

      return output ?? _request;
    } catch (e, s) {
      return _error(e, s);
    }
  }

  Future<FluxResponse> _getResponse(List<RoutingEntity> entities) async {
    try {
      bool isNotFound = true;

      late HttpEntity output;
      for (var entity in entities) {
        output = await entity.processor(_request, _response, _params(entity));

        if (output is FluxRequest) {
          _request = output;
        } else if (output is FluxResponse) {
          _response = output;
          if (!output.closed) {
            _response = await output.close();
          }
          isNotFound = false;
        }
      }
      if (isNotFound) {
        return SendResponse.notFound(_response, 'request path not found');
      }
      return _response;
    } catch (e, s) {
      return _error(e, s);
    }
  }

  bool _responseClosed = false;
  void _newEntity(HttpEntity entity) {
    if (entity is FluxResponse) {
      _response = entity;
      _responseClosed = true;
    } else if (entity is FluxRequest) {
      _request = entity;
    }
  }

  Future<FluxResponse> run() async {
    try {
      HttpEntity systemUpper = await _runMiddlewares(_systemUpper);
      _newEntity(systemUpper);

      HttpEntity upper = await _runMiddlewares(_upperMiddlewares);
      _newEntity(upper);
      if (!_responseClosed) {
        _response = await _getResponse(_entities);
        _responseClosed = true;
      }
      HttpEntity lower = await _runMiddlewares(_lowerMiddlewares);
      _newEntity(lower);

      HttpEntity systemLower = await _runMiddlewares(_systemLower);
      _newEntity(systemLower);
    } catch (e, s) {
      _response = await _error(e, s);
    }
    return _response;
  }
}
