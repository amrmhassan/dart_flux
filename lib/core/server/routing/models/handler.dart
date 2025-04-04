import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/utils/path_utils.dart';

//! the path can't be null, the processor must return a response
//! create 2 versions of a processor
class Handler extends RoutingEntity implements RequestProcessor {
  Handler(
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
    finalPath = null;
  }
  List<Middleware> _middlewares = [];
  List<Middleware> _lowerMiddleware = [];

  Handler middleware(Processor processor) {
    var middleware = Middleware(pathTemplate, method, processor);
    middleware.basePathTemplate = basePathTemplate;
    _middlewares.add(middleware);
    return this;
  }

  Handler lowerMiddleware(Middleware middleware) {
    middleware.basePathTemplate = basePathTemplate;
    _lowerMiddleware.add(middleware);
    return this;
  }

  String? get finalPath {
    return PathUtils.finalPath(basePathTemplate, pathTemplate);
  }

  @override
  List<RoutingEntity> processors(String path, HttpMethod method) {
    var middlewaresProcessors =
        _middlewares
            .where((middleware) => middleware.checkMine(path, method))
            .map((middleware) => middleware)
            .toList();

    var lowerMiddlewaresProcessors =
        _lowerMiddleware
            .where((middleware) => middleware.checkMine(path, method))
            .map((middleware) => middleware)
            .toList();

    bool mine = checkMine(path, method);
    if (mine) {
      return [...middlewaresProcessors, this, ...lowerMiddlewaresProcessors];
    }
    return [];
  }

  @override
  String? basePathTemplate;

  @override
  set finalPath(String? _finalPath) {
    super.finalPath = PathUtils.finalPath(basePathTemplate, pathTemplate);
  }
}
