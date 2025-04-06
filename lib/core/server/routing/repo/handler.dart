import 'package:dart_flux/core/server/routing/models/handler_base.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';

/// A class that extends [HandlerBase] and provides methods to add middleware
/// to the upper and lower pipelines of a request handler.
class Handler extends HandlerBase {
  /// Constructor for initializing a handler with a path template, HTTP method, and processor.
  Handler(super.pathTemplate, super.method, super.processor);

  /// Adds middleware to the upper pipeline of the handler.
  ///
  /// This method creates a new [Middleware] object and attaches it to the
  /// upper pipeline (middlewares) of the handler. The middleware is associated
  /// with the handler's path template and method.
  Handler middleware(Processor processor) {
    var middleware = Middleware(pathTemplate, method, processor);
    middleware.basePathTemplate = basePathTemplate;
    middlewares.add(middleware);
    return this;
  }

  /// Adds middleware to the lower pipeline of the handler.
  ///
  /// This method adds a middleware to the lower pipeline (lowerMiddlewares)
  /// for the handler. It ensures that the middleware is associated with the
  /// correct base path template.
  Handler lower(Middleware middleware) {
    middleware.basePathTemplate = basePathTemplate;
    lowerMiddleware.add(middleware);
    return this;
  }
}
