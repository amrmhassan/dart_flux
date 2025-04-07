// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/server/execution/interface/flux_logger_interface.dart';
import 'package:dart_flux/core/server/routing/interface/http_entity.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/server/routing/models/lower_middleware.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';
import 'package:dart_flux/utils/path_utils.dart';

/// This class is responsible for running the full middleware and routing pipeline
/// in a Dart Flux server.
///
/// It executes middleware layers (system & custom), processes routing entities,
/// and handles errors or unmatched paths with fallbacks.
class PipelineRunner {
  // System-level middlewares that run before and after everything else.
  final List<Middleware> _systemUpper;
  final List<LowerMiddleware> _systemLower;

  // Custom middlewares added at the server level.
  final List<Middleware> _upperMiddlewares;
  final List<LowerMiddleware> _lowerMiddlewares;

  // Current HTTP request and response objects.
  FluxRequest _request;
  FluxResponse _response;

  // List of routing entities to attempt matching and processing.
  final List<RoutingEntity> _entities;

  // Optional logger used for logging raw error/output messages.
  FluxLoggerInterface? fluxLogger;

  // Optional fallback handler for unmatched routes.
  ProcessorHandler? onNotFound;

  PipelineRunner({
    required List<Middleware> systemUpper,
    required List<LowerMiddleware> systemLower,
    required List<Middleware> upperMiddlewares,
    required List<LowerMiddleware> lowerMiddlewares,
    required FluxRequest request,
    required FluxResponse response,
    required List<RoutingEntity> entities,
    required this.fluxLogger,
    required this.onNotFound,
  }) : _request = request,
       _response = response,
       _entities = entities,
       _lowerMiddlewares = lowerMiddlewares,
       _upperMiddlewares = upperMiddlewares,
       _systemLower = systemLower,
       _systemUpper = systemUpper;

  /// Handles any errors thrown in middleware or routing,
  /// sends a proper error response, and logs the error/stack trace.
  Future<FluxResponse> _error(Object e, StackTrace s) async {
    try {
      if (!_response.closed) {
        _response = await SendResponse.error(_response, e);
      }
      fluxLogger?.rawLog(e);
      fluxLogger?.rawLog(s);
    } catch (e) {
      try {
        _response =
            await _response
                .write(e.toString(), code: HttpStatus.internalServerError)
                .close();
      } catch (e) {
        fluxLogger?.rawLog(e);
      }
    }
    return _response;
  }

  /// Extracts path parameters from the request URL based on the middleware/entity's path.
  Map<String, String> _params(RoutingEntity entity) {
    String requestPath = _request.path;
    String? entityPath = entity.finalPath;
    return PathUtils.extractParams(requestPath, entityPath);
  }

  /// Sequentially executes the given list of middlewares,
  /// passing updated request/response objects down the chain.
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

  Future<void> _runLowerMiddlewares(List<LowerMiddleware> middlewares) async {
    try {
      for (var middleware in middlewares) {
        await middleware.processor(_request, _response, _params(middleware));
      }
    } catch (e) {
      return fluxLogger?.rawLog(e);
    }
  }

  /// Processes routing entities to handle the request.
  /// If no entity matches, falls back to [onNotFound] or returns 404.
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
            fluxLogger?.rawLog('closing open response');
            _response = await output.close();
            fluxLogger?.rawLog('closed open response');
          }
          isNotFound = false;
        }
      }

      if (isNotFound) {
        if (onNotFound != null) {
          return onNotFound!(_request, _response, {});
        }
        return SendResponse.notFound(_response, 'request path not found');
      }

      return _response;
    } catch (e, s) {
      return _error(e, s);
    }
  }

  /// Tracks if the response was closed before lower/system middlewares.
  bool _responseClosed = false;

  /// Updates internal request/response based on middleware or route output.
  void _newEntity(HttpEntity entity) {
    if (entity is FluxResponse) {
      _response = entity;
      _responseClosed = true;
    } else if (entity is FluxRequest) {
      _request = entity;
    }
  }

  /// Entry point to run the full middleware → route → middleware pipeline.
  ///
  /// The order of execution:
  /// 1. System Upper Middlewares
  /// 2. Custom Upper Middlewares
  /// 3. Routing Entities (match request to handler)
  /// 4. Custom Lower Middlewares
  /// 5. System Lower Middlewares
  Future<FluxResponse> run() async {
    try {
      _response.headers.add('X-Framework-Name', frameworkName);
      _response.headers.add('X-Framework-Version', frameworkVersion);
      HttpEntity systemUpper = await _runMiddlewares(_systemUpper);
      _newEntity(systemUpper);

      HttpEntity upper = await _runMiddlewares(_upperMiddlewares);
      _newEntity(upper);

      if (!_responseClosed) {
        _response = await _getResponse(_entities);
        _responseClosed = true;
      }

      await _runLowerMiddlewares(_lowerMiddlewares);

      await _runLowerMiddlewares(_systemLower);
    } catch (e, s) {
      _response = await _error(e, s);
    }

    return _response;
  }
}
