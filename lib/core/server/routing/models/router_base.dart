// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:dart_flux/core/server/routing/interface/base_path.dart';
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/lower_middleware.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/repo/handler.dart';
import 'package:dart_flux/core/server/routing/repo/router.dart';

/// A base class that represents a router in the application.
/// This class handles processing requests by managing pipelines (upper, main, and lower)
/// of middlewares and handlers for a specific route.
abstract class RouterBase extends BasePath implements RequestProcessor {
  /// this is the same as the pathTemplate
  @override
  String? pathTemplate;

  /// this is the parent of the handler, mostly a router
  @override
  BasePath? parent;

  // Pipeline for middlewares that run before the main processing
  List<Middleware> upperPipeline = [];

  // Main pipeline that can include middlewares, handlers, or other routers
  List<RequestProcessor> mainPipeline = [];

  // Pipeline for middlewares that run after the main processing
  List<LowerMiddleware> lowerPipeline = [];

  /// Constructor that initializes the router with optional pipelines.
  RouterBase({
    List<Middleware>? upperPipeline,
    List<RequestProcessor>? mainPipeline,
    List<LowerMiddleware>? lowerPipeline,
  }) : upperPipeline = upperPipeline ?? [],
       mainPipeline = mainPipeline ?? [],
       lowerPipeline = lowerPipeline ?? [];

  @override
  List<RoutingEntity> processors(String path, HttpMethod method) {
    // Extract processors from the main pipeline
    var main = _extractFromPipeline(
      mainPipeline,
      path,
      method,
      handlerIsAMust:
          true, // Ensures at least one handler exists in the pipeline
    );
    if (main.isEmpty) return [];

    // Extract processors from the upper pipeline
    var upper = _extractFromPipeline(
      upperPipeline,
      path,
      method,
      handlerIsAMust: false,
    );

    // Extract processors from the lower pipeline
    var lower = _extractFromPipeline(
      lowerPipeline,
      path,
      method,
      handlerIsAMust: false,
    );

    // Return the combined processors in the correct order
    return [...upper, ...main, ...lower];
  }

  /// Extracts processors from a specific pipeline (upper, main, or lower).
  ///
  /// This function ensures that the pipeline contains the necessary processors (handlers, routers)
  /// in the correct order, and ensures that a handler is present if specified.
  List<RoutingEntity> _extractFromPipeline(
    List<RequestProcessor> pipeLine,
    String path,
    HttpMethod method, {

    /// If true, the pipeline must contain a handler at the end.
    required bool handlerIsAMust,
  }) {
    bool foundHandler = false;
    List<RoutingEntity> mainProcessors = [];

    // Iterate over the pipeline to extract valid processors
    for (var requestProcessor in pipeLine) {
      var entityProcessors = requestProcessor.processors(path, method);
      if (entityProcessors.isEmpty) continue;

      // Add valid processors to the main list
      mainProcessors.addAll(entityProcessors);

      // If it's a handler or router, mark that we've found a handler
      if (requestProcessor is Handler ||
          requestProcessor is Router && handlerIsAMust) {
        return mainProcessors;
      }
    }

    // If a handler is required but not found, return an empty list
    if (handlerIsAMust && !foundHandler) return [];

    return mainProcessors;
  }
}
