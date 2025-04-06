import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/core/server/routing/models/router_base.dart';
import 'package:dart_flux/core/server/routing/repo/handler.dart';

/// A class that extends [RouterBase] and provides methods for registering
/// routers, handlers, and middlewares with various HTTP methods and paths.
class Router extends RouterBase {
  /// Constructor for initializing a [Router] instance with optional pipeline lists.
  Router({
    List<Middleware>? upperPipeline,
    List<RequestProcessor>? mainPipeline,
    List<Middleware>? lowerPipeline,
  }) : super(
         upperPipeline: upperPipeline,
         mainPipeline: mainPipeline,
         lowerPipeline: lowerPipeline,
       );

  /// A factory method to create a router instance with a base path.
  factory Router.path(String path) {
    return Router()..basePath = path;
  }

  //? adding request processors

  /// Adds a sub-router to the current router.
  ///
  /// This method allows you to add another [Router] instance to the current router's
  /// pipeline, effectively creating a nested routing structure.
  Router router(Router router) {
    router.basePath = basePath;
    mainPipeline.add(router);
    return this;
  }

  /// Adds a handler to the current router's pipeline.
  ///
  /// This method adds a [Handler] to the main pipeline of the router, where it will
  /// handle incoming requests matching the specified path and method.
  Router handler(Handler handler) {
    handler.basePathTemplate = basePath;
    mainPipeline.add(handler);
    return this;
  }

  /// Adds a raw middleware to the current router's pipeline.
  ///
  /// This method adds a [Middleware] directly to the main pipeline of the router.
  Router rawMiddleware(Middleware middleware) {
    middleware.basePathTemplate = basePath;
    mainPipeline.add(middleware);
    return this;
  }

  /// Adds a middleware to the current router's pipeline using a processor function.
  ///
  /// This method creates a [Middleware] using the provided [Processor] and adds it
  /// to the main pipeline.
  Router middleware(Processor processor) {
    Middleware m = Middleware(null, null, processor);
    return rawMiddleware(m);
  }

  //? upper middlewares will always be executed before any other middleware or handler on this router

  /// Adds an upper middleware to the router.
  ///
  /// This middleware will be executed before any other middleware or handler in the
  /// router's pipeline, making it ideal for tasks such as authentication or logging.
  Router upperMiddleware(Middleware middleware) {
    middleware.basePathTemplate = basePath;
    upperPipeline.add(middleware);
    return this;
  }

  /// Adds a middleware to the upper pipeline of the router using a processor function.
  Router upper(Processor processor) {
    var m = Middleware(null, null, processor);
    return upperMiddleware(m);
  }

  //? lower middlewares will always be executed after any other middleware or handler on this router

  /// Adds a lower middleware to the router.
  ///
  /// This middleware will be executed after all other middlewares and handlers in the
  /// router's pipeline, which is useful for tasks such as final logging or cleanup.
  Router lowerMiddleware(Middleware middleware) {
    middleware.basePathTemplate = basePath;
    lowerPipeline.add(middleware);
    return this;
  }

  /// Adds a middleware to the lower pipeline of the router using a processor function.
  Router lower(Processor processor) {
    return lowerMiddleware(Middleware(null, null, processor));
  }

  //? fast inserting handlers

  /// A helper method for adding HTTP methods with processors to the router.
  Router _addFastMethod(
    String path,
    HttpMethod method,
    ProcessorHandler processor,
  ) {
    Handler h = Handler(path, method, processor);
    h.basePathTemplate = basePath;
    return handler(h);
  }

  /// Adds a GET request handler to the router.
  Router get(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.get, processor);
  }

  /// Adds a POST request handler to the router.
  Router post(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.post, processor);
  }

  /// Adds a PUT request handler to the router.
  Router put(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.put, processor);
  }

  /// Adds a DELETE request handler to the router.
  Router delete(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.delete, processor);
  }

  /// Adds a HEAD request handler to the router.
  Router head(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.head, processor);
  }

  /// Adds a CONNECT request handler to the router.
  Router connect(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.connect, processor);
  }

  /// Adds an OPTIONS request handler to the router.
  Router options(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.options, processor);
  }

  /// Adds a TRACE request handler to the router.
  Router trace(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.trace, processor);
  }

  /// Adds a PATCH request handler to the router.
  Router patch(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.patch, processor);
  }
}
