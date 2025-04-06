import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/utils/path_utils.dart';

/// Abstract base class for a handler in the routing system. It extends RoutingEntity
/// and implements the RequestProcessor interface. Handlers define how requests are processed
/// and can be combined with middlewares.
abstract class HandlerBase extends RoutingEntity implements RequestProcessor {
  /// Constructor for the HandlerBase class.
  /// [pathTemplate] is the URL path template for this handler.
  /// [method] specifies the HTTP method (e.g., GET, POST).
  /// [processor] is the function that handles the request.
  /// [signature] is an optional unique identifier for this handler.
  HandlerBase(
    String pathTemplate,
    HttpMethod method,
    ProcessorHandler processor, {
    String? signature,
  }) : super(
         pathTemplate,
         method,
         processor,
         signature: signature,
       ) // Ensure pathTemplate is never null
       {
    finalPath = null; // Set initial value for finalPath
  }

  /// A list of middlewares that will run before the handler.
  List<Middleware> middlewares = [];

  /// A list of middlewares that will run after the handler.
  List<Middleware> lowerMiddleware = [];

  /// Calculates the final path for the handler by combining the base path template and the handler's path template.
  @override
  String? get finalPath {
    return PathUtils.finalPath(basePathTemplate, pathTemplate);
  }

  /// Returns a list of processors (middlewares and this handler) that should process the request.
  /// Filters the middlewares based on the current path and method, and checks if this handler should be executed.
  @override
  List<RoutingEntity> processors(String path, HttpMethod method) {
    // Get middlewares that match the path and method for this handler
    var middlewaresProcessors =
        middlewares
            .where((middleware) => middleware.checkMine(path, method))
            .map((middleware) => middleware)
            .toList();

    // Get lower middlewares that match the path and method for this handler
    var lowerMiddlewaresProcessors =
        lowerMiddleware
            .where((middleware) => middleware.checkMine(path, method))
            .map((middleware) => middleware)
            .toList();

    // Check if the handler itself should process this request
    bool mine = checkMine(path, method);
    if (mine) {
      // Return a list of middlewares, the handler, and lower middlewares
      return [...middlewaresProcessors, this, ...lowerMiddlewaresProcessors];
    }
    return [];
  }

  /// Base path template for the handler (can be overridden by specific handler implementations).
  @override
  String? basePathTemplate;

  /// Setter for finalPath, calculates the final path based on basePathTemplate and pathTemplate.
  @override
  set finalPath(String? _finalPath) {
    super.finalPath = PathUtils.finalPath(basePathTemplate, pathTemplate);
  }
}
