// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/handler.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/utils/path_utils.dart';

class Router implements RequestProcessor {
  /// this is a path template for the whole router and will apply for each sub request processor
  String? _basePathTemplate;
  // only middlewares
  List<Middleware> _upperPipeline = [];
  // can be middlewares or handlers or routers
  List<RequestProcessor> _mainPipeline = [];
  // only middlewares
  List<Middleware> _lowerPipeline = [];

  Router({
    List<Middleware>? upperPipeline,
    List<RequestProcessor>? mainPipeline,
    List<Middleware>? lowerPipeline,
  }) : _upperPipeline = upperPipeline ?? [],
       _mainPipeline = mainPipeline ?? [],
       _lowerPipeline = lowerPipeline ?? [];

  factory Router.path(String path) {
    return Router().._basePathTemplate = path;
  }

  @override
  List<RoutingEntity> processors(String path, HttpMethod method) {
    // basePathTemplate is the passed one from the request processor parent (mostly a router)
    // _basePathTemplate is the current router base path template and comes next after the basePathTemplate
    // so the passed down base path template should be the sum of the upper routers base path templates

    String? finalBasePathTemplate = PathUtils.finalPath(
      _basePathTemplate,
      basePathTemplate,
    );
    // main pipeline
    var main = _extractFromPipeline(
      _mainPipeline,
      path,
      method,
      finalBasePathTemplate,
      handlerIsAMust: true,
    );
    if (main.isEmpty) return [];

    // upper pipeline
    var upper = _extractFromPipeline(
      _upperPipeline,
      path,
      method,
      finalBasePathTemplate,
      handlerIsAMust: false,
    );

    // lower pipeline
    var lower = _extractFromPipeline(
      _lowerPipeline,
      path,
      method,
      finalBasePathTemplate,
      handlerIsAMust: false,
    );
    // then add them together then return
    return [...upper, ...main, ...lower];
  }

  List<RoutingEntity> _extractFromPipeline(
    List<RequestProcessor> pipeLine,
    String path,
    HttpMethod method,
    String? basePathTemplate, {

    /// this will ensure that the processors list must contain a handler at the end of the pipeline
    required bool handlerIsAMust,
  }) {
    bool foundHandler = false;
    List<RoutingEntity> mainProcessors = [];
    for (var requestProcessor in pipeLine) {
      // if handler then it should be the last of the pipeline
      var entityProcessors = requestProcessor.processors(path, method);
      if (entityProcessors.isEmpty) continue;
      if (requestProcessor is Handler || requestProcessor is Router) {
        foundHandler = true;
      }
      mainProcessors.addAll(entityProcessors);
    }

    if (handlerIsAMust && !foundHandler) return [];

    return mainProcessors;
  }

  //? adding request processors
  Router router(Router router) {
    router._basePathTemplate = _basePathTemplate;
    _mainPipeline.add(router);

    return this;
  }

  //raw
  Router handler(Handler handler) {
    handler.basePathTemplate = _basePathTemplate;

    _mainPipeline.add(handler);
    return this;
  }

  //raw
  Router rawMiddleware(Middleware middleware) {
    middleware.basePathTemplate = _basePathTemplate;

    _mainPipeline.add(middleware);
    return this;
  }

  Router middleware(Processor processor) {
    Middleware m = Middleware(null, null, processor);

    return rawMiddleware(m);
  }

  //raw

  /// upper middlewares will always be executed before any other middleware or handler on this router
  Router upperMiddleware(Middleware middleware) {
    middleware.basePathTemplate = _basePathTemplate;
    _upperPipeline.add(middleware);

    return this;
  }

  Router upper(Processor processor) {
    var m = Middleware(null, null, processor);

    return upperMiddleware(m);
  }

  //raw

  /// upper middlewares will always be executed after any other middleware or handler on this router
  Router lowerMiddleware(Middleware middleware) {
    middleware.basePathTemplate = _basePathTemplate;

    _lowerPipeline.add(middleware);
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
    h.basePathTemplate = _basePathTemplate;
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

  @override
  String? basePathTemplate;
}
