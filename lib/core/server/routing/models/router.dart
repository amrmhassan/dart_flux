import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/models/handler.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';

class Router implements RequestProcessor {
  // only middlewares
  List<Middleware> _upperPipeline = [];
  // can be middlewares or handlers or routers
  List<RequestProcessor> _mainPipeLine = [];
  // only middlewares
  List<Middleware> _lowerPipeline = [];

  Router addRouter(Router handler) {
    _mainPipeLine.add(handler);
    return this;
  }

  Router addHandler(Handler handler) {
    _mainPipeLine.add(handler);
    return this;
  }

  Router addMiddleware(Middleware middleware) {
    _mainPipeLine.add(middleware);
    return this;
  }

  Router addUpperMiddleware(Middleware middleware) {
    _upperPipeline.add(middleware);
    return this;
  }

  Router addLowerMiddleware(Middleware middleware) {
    _lowerPipeline.add(middleware);
    return this;
  }

  @override
  List<Processor> processors(String path, HttpMethod method) {
    // main pipeline
    var main = _extractFromPipeline(_mainPipeLine, path, method);
    if (main.isEmpty) return [];

    // upper pipeline
    var upper = _extractFromPipeline(_upperPipeline, path, method);

    // lower pipeline
    var lower = _extractFromPipeline(_lowerPipeline, path, method);
    // then add them together then return
    return [...upper, ...main, ...lower];
  }

  List<Processor> _extractFromPipeline(
    List<RequestProcessor> pipeLine,
    String path,
    HttpMethod method,
  ) {
    List<Processor> mainProcessors = [];
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
