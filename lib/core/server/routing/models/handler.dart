import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';

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
       ); // Ensure pathTemplate is never null
  List<Middleware> _middlewares = [];
  List<Middleware> _lowerMiddleware = [];

  Handler middleware(Processor processor) {
    _middlewares.add(Middleware(pathTemplate, method, processor));
    return this;
  }

  Handler lowerMiddleware(Middleware middleware) {
    _lowerMiddleware.add(middleware);
    return this;
  }

  @override
  List<RoutingEntity> processors(
    String path,
    HttpMethod method,
    String? basePathTemplate,
  ) {
    var middlewaresProcessors =
        _middlewares
            .where(
              (middleware) =>
                  middleware.checkMine(path, method, basePathTemplate),
            )
            .map((middleware) => middleware)
            .toList();

    var lowerMiddlewaresProcessors =
        _lowerMiddleware
            .where(
              (middleware) =>
                  middleware.checkMine(path, method, basePathTemplate),
            )
            .map((middleware) => middleware)
            .toList();

    bool mine = checkMine(path, method, basePathTemplate);
    if (mine) {
      return [...middlewaresProcessors, this, ...lowerMiddlewaresProcessors];
    }
    return [];
  }
}
