import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/core/server/routing/repo/handler.dart';

/// A middleware class that extends [RoutingEntity] and implements [RequestProcessor].
/// Middleware is used to process HTTP requests and responses before or after they pass through a handler.
class Middleware extends RoutingEntity implements RequestProcessor {
  /// Constructs a [Middleware] entity.
  ///
  /// [pathTemplate] defines the path on which this middleware will be triggered.
  /// [method] defines the HTTP method for the middleware. If null, the middleware will be triggered for all methods.
  /// [processor] is the function that processes the request and/or response.
  /// [signature] is an optional identifier for the middleware, used for tracking.
  Middleware(
    String? pathTemplate,
    HttpMethod? method,
    Processor processor, {
    String? signature,
  }) : super(pathTemplate, method, processor, signature: signature);

  /// Processes the request for this middleware if the path and method match.
  ///
  /// Returns a list of [RoutingEntity] that includes this middleware if it matches the path and method.
  /// If the middleware does not match, returns an empty list.
  @override
  List<RoutingEntity> processors(String path, HttpMethod method) {
    bool mine = checkMine(path, method);
    if (mine) {
      return [this]; // Include this middleware if it matches
    }
    return [];
  }

  @override
  List<Handler> wrongMethodProcessors(String path, HttpMethod method) {
    throw UnimplementedError();
  }

  @override
  List<Handler> wrongPathProcessors(String path, HttpMethod method) {
    throw UnimplementedError();
  }
}
