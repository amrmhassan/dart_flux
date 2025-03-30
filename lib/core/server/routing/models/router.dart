// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/handler.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';

class Router implements RequestProcessor {
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

  Router router(Router handler) {
    _mainPipeline.add(handler);
    return this;
  }

  Router handler(Handler handler) {
    _mainPipeline.add(handler);
    return this;
  }

  Router middleware(Middleware middleware) {
    _mainPipeline.add(middleware);
    return this;
  }

  Router upperMiddleware(Middleware middleware) {
    _upperPipeline.add(middleware);
    return this;
  }

  Router lowerMiddleware(Middleware middleware) {
    _lowerPipeline.add(middleware);
    return this;
  }

  @override
  List<RoutingEntity> processors(String path, HttpMethod method) {
    // main pipeline
    var main = _extractFromPipeline(_mainPipeline, path, method);
    if (main.isEmpty) return [];

    // upper pipeline
    var upper = _extractFromPipeline(_upperPipeline, path, method);

    // lower pipeline
    var lower = _extractFromPipeline(_lowerPipeline, path, method);
    // then add them together then return
    return [...upper, ...main, ...lower];
  }

  List<RoutingEntity> _extractFromPipeline(
    List<RequestProcessor> pipeLine,
    String path,
    HttpMethod method,
  ) {
    List<RoutingEntity> mainProcessors = [];
    for (var requestProcessor in pipeLine) {
      // if handler then it should be the last of the pipeline
      var entityProcessors = requestProcessor.processors(path, method);
      if (entityProcessors.isEmpty) continue;
      mainProcessors.addAll(entityProcessors);
      if (requestProcessor is Handler || requestProcessor is Router) {
        return mainProcessors;
      }
    }
    return [];
  }
}
