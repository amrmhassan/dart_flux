import 'package:dart_flux/core/server/routing/models/handler_base.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';

class Handler extends HandlerBase {
  Handler(super.pathTemplate, super.method, super.processor);
  Handler middleware(Processor processor) {
    var middleware = Middleware(pathTemplate, method, processor);
    middleware.basePathTemplate = basePathTemplate;
    middlewares.add(middleware);
    return this;
  }

  Handler lower(Middleware middleware) {
    middleware.basePathTemplate = basePathTemplate;
    lowerMiddleware.add(middleware);
    return this;
  }
}
