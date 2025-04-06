import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/models/handler.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/core/server/routing/models/router_base.dart';

class Router extends RouterBase {
  Router({
    List<Middleware>? upperPipeline,
    List<RequestProcessor>? mainPipeline,
    List<Middleware>? lowerPipeline,
  }) : super(
         upperPipeline: upperPipeline,
         mainPipeline: mainPipeline,
         lowerPipeline: lowerPipeline,
       );

  factory Router.path(String path) {
    return Router()..basePath = path;
  }

  //? adding request processors
  Router router(Router router) {
    router.basePath = basePath;
    mainPipeline.add(router);

    return this;
  }

  //raw
  Router handler(Handler handler) {
    handler.basePathTemplate = basePath;

    mainPipeline.add(handler);
    return this;
  }

  //raw
  Router rawMiddleware(Middleware middleware) {
    middleware.basePathTemplate = basePath;

    mainPipeline.add(middleware);
    return this;
  }

  Router middleware(Processor processor) {
    Middleware m = Middleware(null, null, processor);

    return rawMiddleware(m);
  }

  //raw

  /// upper middlewares will always be executed before any other middleware or handler on this router
  Router upperMiddleware(Middleware middleware) {
    middleware.basePathTemplate = basePath;
    upperPipeline.add(middleware);

    return this;
  }

  Router upper(Processor processor) {
    var m = Middleware(null, null, processor);

    return upperMiddleware(m);
  }

  //raw

  /// upper middlewares will always be executed after any other middleware or handler on this router
  Router lowerMiddleware(Middleware middleware) {
    middleware.basePathTemplate = basePath;

    lowerPipeline.add(middleware);
    return this;
  }

  Router lower(Processor processor) {
    return lowerMiddleware(Middleware(null, null, processor));
  }

  //? fast inserting handlers
  Router _addFastMethod(
    String path,
    HttpMethod method,
    ProcessorHandler processor,
  ) {
    Handler h = Handler(path, method, processor);
    h.basePathTemplate = basePath;
    return handler(h);
  }

  Router get(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.get, processor);
  }

  Router post(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.post, processor);
  }

  Router put(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.put, processor);
  }

  Router delete(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.delete, processor);
  }

  Router head(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.head, processor);
  }

  Router connect(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.connect, processor);
  }

  Router options(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.options, processor);
  }

  Router trace(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.trace, processor);
  }

  Router patch(String path, ProcessorHandler processor) {
    return _addFastMethod(path, HttpMethod.patch, processor);
  }
}
