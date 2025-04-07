import 'package:dart_flux/core/server/routing/interface/model_repository_interface.dart';
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/core/server/routing/models/router_base.dart';
import 'package:dart_flux/core/server/routing/repo/crud_router.dart';
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
    return Router()..setPath(path);
  }
  factory Router.crud(String entity, {ModelRepositoryInterface? repo}) {
    return CrudRouter.init(entity, repo: repo);
  }

  //? adding request processors

  void _addRouter(Router router) {
    router.parent = this;
    mainPipeline.add(router);
  }

  void _addHandler(Handler handler) {
    handler.parent = this;
    mainPipeline.add(handler);
  }

  void _addMiddleware(Middleware middleware) {
    middleware.parent = this;
    mainPipeline.add(middleware);
  }

  void _addUpperMiddleware(Middleware middleware) {
    middleware.parent = this;
    upperPipeline.add(middleware);
  }

  void _addLowerMiddleware(Middleware middleware) {
    middleware.parent = this;
    lowerPipeline.add(middleware);
  }

  /// Adds a sub-router to the current router.
  ///
  /// This method allows you to add another [Router] instance to the current router's
  /// pipeline, effectively creating a nested routing structure.
  Router router(Router router) {
    _addRouter(router);

    return this;
  }

  /// Adds a handler to the current router's pipeline.
  ///
  /// This method adds a [Handler] to the main pipeline of the router, where it will
  /// handle incoming requests matching the specified path and method.
  Router handler(Handler handler) {
    _addHandler(handler);
    return this;
  }

  /// Adds a raw middleware to the current router's pipeline.
  ///
  /// This method adds a [Middleware] directly to the main pipeline of the router.
  Router rawMiddleware(Middleware middleware) {
    _addMiddleware(middleware);
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
    _addUpperMiddleware(middleware);
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
    _addLowerMiddleware(middleware);
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
    ProcessorHandler processor, {
    String? signature,
  }) {
    Handler h = Handler(path, method, processor, signature: signature);
    return handler(h);
  }

  /// Adds a GET request handler to the router.
  Router get(String path, ProcessorHandler processor, {String? signature}) {
    return _addFastMethod(
      path,
      HttpMethod.get,
      processor,
      signature: signature,
    );
  }

  /// Adds a POST request handler to the router.
  Router post(String path, ProcessorHandler processor, {String? signature}) {
    return _addFastMethod(
      path,
      HttpMethod.post,
      processor,
      signature: signature,
    );
  }

  /// Adds a PUT request handler to the router.
  Router put(String path, ProcessorHandler processor, {String? signature}) {
    return _addFastMethod(
      path,
      HttpMethod.put,
      processor,
      signature: signature,
    );
  }

  /// Adds a DELETE request handler to the router.
  Router delete(String path, ProcessorHandler processor, {String? signature}) {
    return _addFastMethod(
      path,
      HttpMethod.delete,
      processor,
      signature: signature,
    );
  }

  /// Adds a HEAD request handler to the router.
  Router head(String path, ProcessorHandler processor, {String? signature}) {
    return _addFastMethod(
      path,
      HttpMethod.head,
      processor,
      signature: signature,
    );
  }

  /// Adds a CONNECT request handler to the router.
  Router connect(String path, ProcessorHandler processor, {String? signature}) {
    return _addFastMethod(
      path,
      HttpMethod.connect,
      processor,
      signature: signature,
    );
  }

  /// Adds an OPTIONS request handler to the router.
  Router options(String path, ProcessorHandler processor, {String? signature}) {
    return _addFastMethod(
      path,
      HttpMethod.options,
      processor,
      signature: signature,
    );
  }

  /// Adds a TRACE request handler to the router.
  Router trace(String path, ProcessorHandler processor, {String? signature}) {
    return _addFastMethod(
      path,
      HttpMethod.trace,
      processor,
      signature: signature,
    );
  }

  /// Adds a PATCH request handler to the router.
  Router patch(String path, ProcessorHandler processor, {String? signature}) {
    return _addFastMethod(
      path,
      HttpMethod.patch,
      processor,
      signature: signature,
    );
  }
}
